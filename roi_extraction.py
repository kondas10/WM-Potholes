#!/usr/bin/env python3

import nibabel as nib
import numpy as np
import pandas as pd
from pathlib import Path
import sys


# ============================================================
# STEP 1: MAIN EXTRACTION
# ============================================================

def calculate_cluster_volumes_by_masks(subject_list_file, cluster_dir, mask_dir, output_csv):

    mask_dir_path = Path(mask_dir)
    mask_files = sorted(mask_dir_path.glob("*.nii.gz"))

    if not mask_files:
        print(f"ERROR: No mask files found in {mask_dir}")
        return None, None, None

    print(f"Found {len(mask_files)} mask files")

    # -------------------------
    # Load masks
    # -------------------------
    masks = {}
    for mask_file in mask_files:

        region_name = mask_file.stem.replace('.nii', '').replace('bin_', '')
        mask_img = nib.load(mask_file)

        masks[region_name] = {
            "data": mask_img.get_fdata().astype(bool),
            "img": mask_img
        }

    # voxel volume
    voxel_dims = list(masks.values())[0]["img"].header.get_zooms()[:3]
    voxel_volume = np.prod(voxel_dims)

    print(f"Voxel volume: {voxel_volume:.3f} mm³")

    # -------------------------
    # Subjects
    # -------------------------
    with open(subject_list_file, "r") as f:
        subjects = [x.strip() for x in f if x.strip()]

    print(f"Found {len(subjects)} subjects")

    all_results = []
    subject_totals = []

    # ========================================================
    # MAIN LOOP
    # ========================================================
    for idx, subject in enumerate(subjects, 1):

        print(f"\nProcessing {subject} ({idx}/{len(subjects)})")

        cluster_file = Path(cluster_dir) / f"{subject}_cluster_n5.nii.gz"

        if not cluster_file.exists():
            print(f"  WARNING missing file")
            continue

        cluster_img = nib.load(cluster_file)
        cluster_data = cluster_img.get_fdata().astype(int)

        cluster_vals = np.unique(cluster_data)
        cluster_vals = cluster_vals[cluster_vals > 0]

        total_vox = 0

        print(f"  clusters: {len(cluster_vals)}")

        # -------------------------
        # clusters
        # -------------------------
        for c in cluster_vals:

            c_mask = (cluster_data == c)
            c_vox = np.sum(c_mask)
            c_vol = c_vox * voxel_volume

            total_vox += c_vox

            # region overlap
            for region_name, mask in masks.items():

                overlap = c_mask & mask["data"]
                vox = np.sum(overlap)

                if vox > 0:
                    all_results.append({
                        "Subject": subject,
                        "ClusterIndex": int(c),
                        "RegionName": region_name,
                        "VoxelsInRegion": int(vox),
                        "VolumeInRegion_mm3": vox * voxel_volume,
                        "TotalClusterVoxels": int(c_vox),
                        "TotalClusterVolume_mm3": c_vol,
                        "PercentInRegion": vox / c_vox * 100
                    })

        subject_totals.append({
            "Subject": subject,
            "TotalNumClusters": len(cluster_vals),
            "TotalVoxels": int(total_vox),
            "TotalVolume_mm3": total_vox * voxel_volume
        })

    # -------------------------
    # DATAFRAMES
    # -------------------------
    df = pd.DataFrame(all_results)
    df_totals = pd.DataFrame(subject_totals)

    # ALWAYS KEEP SUBJECTS EVEN IF NO OVERLAP
    df_totals.to_csv(output_csv.replace(".csv", "_subject_totals.csv"), index=False)

    if len(df) == 0:
        print("No overlaps found at all.")
        return None, None, df_totals

    df.to_csv(output_csv, index=False)

    # summary (safe even if partial overlap)
    df_summary = (
        df.groupby(["Subject", "RegionName"])
        .agg({
            "VolumeInRegion_mm3": "sum",
            "VoxelsInRegion": "sum",
            "ClusterIndex": "count"
        })
        .rename(columns={"ClusterIndex": "NumClusters"})
        .reset_index()
    )

    df_summary.to_csv(output_csv.replace(".csv", "_summary_roi.csv"), index=False)

    return df, df_summary, df_totals


# ============================================================
# STEP 2: WIDE FORMAT (FIXED)
# ============================================================

def pivot_to_wide_format(summary_file, totals_file, output_file):

    df = pd.read_csv(summary_file)
    df_totals = pd.read_csv(totals_file)

    # -------------------------
    # MASTER TABLE = ALL SUBJECTS
    # -------------------------
    result = df_totals.copy()
    result = result.rename(columns={
        "TotalNumClusters": "Total_NumClusters",
        "TotalVoxels": "Total_Voxels",
        "TotalVolume_mm3": "Total_Volume_mm3"
    })

    result = result.set_index("Subject")

    # region list (safe)
    regions = sorted(df["RegionName"].unique()) if len(df) > 0 else []

    # -------------------------
    # add region columns
    # -------------------------
    for r in regions:

        region_df = (
            df[df["RegionName"] == r]
            .groupby("Subject")[["VolumeInRegion_mm3", "NumClusters", "VoxelsInRegion"]]
            .sum()
            .rename(columns={
                "VolumeInRegion_mm3": f"{r}_Volume_mm3",
                "NumClusters": f"{r}_NumClusters",
                "VoxelsInRegion": f"{r}_Voxels"
            })
        )

        result = result.join(region_df, how="left")

    # -------------------------
    # cleanup
    # -------------------------
    result = result.fillna(0)

    int_cols = [c for c in result.columns if "NumClusters" in c or "Voxels" in c]
    result[int_cols] = result[int_cols].astype(int)

    vol_cols = [c for c in result.columns if "Volume_mm3" in c]
    result[vol_cols] = result[vol_cols].astype(float)

    result = result.reset_index()
    result.to_csv(output_file, index=False)

    print(f"✓ Wide format saved: {output_file}")
    print(f"  shape: {result.shape}")

    return result


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":

    print("=" * 70)
    print("CLUSTER VOLUME ANALYSIS (FIXED VERSION)")
    print("=" * 70)

    subject_list = "/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final/sample.txt"
    cluster_directory = "/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final/potholes_fa/sample/thresholded/clusters"
    mask_directory = "/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/AK/masks/final_masks"

    detailed_output = "cluster_volumes_masks_detailed.csv"
    summary_output = "cluster_volumes_masks_detailed_summary_roi.csv"
    totals_output = "cluster_volumes_masks_detailed_subject_totals.csv"
    wide_output = "cluster_volumes_masks_wide.csv"

    # -------------------------
    # run
    # -------------------------
    df, df_summary, df_totals = calculate_cluster_volumes_by_masks(
        subject_list,
        cluster_directory,
        mask_directory,
        detailed_output
    )

    print("\nCreating wide format...")

    df_wide = pivot_to_wide_format(
        summary_output,
        totals_output,
        wide_output
    )

    print("\nDONE")

