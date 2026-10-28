#!/bin/bash
#SBATCH --job-name=copy_dti_data
#SBATCH --account=PAS2321
#SBATCH --nodes=1 --ntasks-per-node=4
#SBATCH --time=02:00:00
#SBATCH --output=copy_dti_%j.log
#SBATCH --mail-type=BEGIN,END,FAIL

# ── Paths ────────────────────────────────────────────────────────────────────
SUBLIST=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/sample.txt          # one subject ID per line
SRC_BASE=/fs/ess/PAS2321/Data/imaging                    # .../A0005/01/unprocessed/Diffusion/
DST_BASE=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/data

# ── File suffixes to copy ─────────────────────────────────────────────────────
# Covers dir98/99 × AP/PA × (main + SBRef) for both .nii.gz and .json
SUFFIXES=(
    "_dMRI_dir98_AP.nii.gz"
    "_dMRI_dir98_AP.json"
    "_dMRI_dir98_PA.nii.gz"
    "_dMRI_dir98_PA.json"
    "_dMRI_dir99_AP.nii.gz"
    "_dMRI_dir99_AP.json"
    "_dMRI_dir99_PA.nii.gz"
    "_dMRI_dir99_PA.json"
    "_dMRI_dir98_AP_SBRef.nii.gz"
    "_dMRI_dir98_AP_SBRef.json"
    "_dMRI_dir98_PA_SBRef.nii.gz"
    "_dMRI_dir98_PA_SBRef.json"
    "_dMRI_dir99_AP_SBRef.nii.gz"
    "_dMRI_dir99_AP_SBRef.json"
    "_dMRI_dir99_PA_SBRef.nii.gz"
    "_dMRI_dir99_PA_SBRef.json"
)

# ── Main loop ─────────────────────────────────────────────────────────────────
n_ok=0
n_skip=0
n_missing=0

while IFS= read -r iSub || [[ -n "$iSub" ]]; do

    [[ -z "$iSub" || "$iSub" == \#* ]] && continue   # skip blank lines / comments

    SRC_DIR="${SRC_BASE}/${iSub}/01/unprocessed/Diffusion"
    DST_DIR="${DST_BASE}/${iSub}/Diffusion"

    # Check source exists before doing anything
    if [[ ! -d "$SRC_DIR" ]]; then
        echo "WARNING: source directory not found for ${iSub}: ${SRC_DIR}"
        (( n_missing++ ))
        continue
    fi

    mkdir -p "$DST_DIR"

    for suffix in "${SUFFIXES[@]}"; do
        src_file="${SRC_DIR}/${iSub}${suffix}"
        dst_file="${DST_DIR}/${iSub}${suffix}"

        if [[ ! -f "$src_file" ]]; then
            echo "  MISSING: ${iSub}${suffix}"
            (( n_missing++ ))
            continue
        fi

        if [[ -f "$dst_file" ]]; then
            echo "  EXISTS (skip): ${iSub}${suffix}"
            (( n_skip++ ))
            continue
        fi

        cp "$src_file" "$dst_file"

        if [[ $? -eq 0 ]]; then
            echo "  OK: ${iSub}${suffix}"
            (( n_ok++ ))
        else
            echo "  ERROR copying: ${iSub}${suffix}"
            (( n_missing++ ))
        fi
    done

done < "$SUBLIST"

echo ""
echo "────────────────────────────────────────"
echo "Copy complete."
echo "  Copied:  ${n_ok}"
echo "  Skipped (already existed): ${n_skip}"
echo "  Missing/errors: ${n_missing}"
echo "────────────────────────────────────────"
