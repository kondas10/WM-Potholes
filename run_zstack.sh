#!/bin/bash
#SBATCH --job-name=run_zstack
#SBATCH --account=PAS2003
#SBATCH --nodes=1 --ntasks-per-node=8
#SBATCH --time=02:00:00
#SBATCH --mail-type=BEGIN,END,FAIL

# Set up environment
module load fsl/6.0.7.13
source $FSLDIR/etc/fslconf/fsl.sh

export BASE_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/data
export IN_DIR=${BASE_DIR}
export OUT_DIR=${BASE_DIR}

echo "Environment set up for $(hostname) at $(date)"

#------------- NOTHING BELOW HERE SHOULD BE MODIFIED--------------------
iSub=$1

if [[ -z "$iSub" ]]; then
    echo "ERROR: no subject ID provided. Usage: sbatch run_zstack.sh <SubjectID>"
    exit 1
fi

echo "Starting zstack merging for ${iSub}"

# Verify input files exist before doing any work
for scan in dir98_AP dir98_PA dir99_AP dir99_PA; do
    f="${IN_DIR}/${iSub}/Diffusion/${iSub}_dMRI_${scan}.nii.gz"
    if [[ ! -f "$f" ]]; then
        echo "ERROR: missing input file: $f"
        exit 1
    fi
done

# Make processed output directory for subject
PROC_DIR="${OUT_DIR}/${iSub}/processed"
mkdir -p "$PROC_DIR"

# ── Merge files for 98 AP ─────────────────────────────────────────────────────
fslmerge -z "${PROC_DIR}/${iSub}_dMRI_dir98_AP_zstack.nii.gz" \
    /fs/ess/PAS2003/Scripts/DTI/templates/98AP_emptyzstack.nii.gz \
    /fs/ess/PAS2003/Scripts/DTI/templates/98AP_emptyzstack.nii.gz \
    "${IN_DIR}/${iSub}/Diffusion/${iSub}_dMRI_dir98_AP.nii.gz" \
    /fs/ess/PAS2003/Scripts/DTI/templates/98AP_emptyzstack.nii.gz \
    /fs/ess/PAS2003/Scripts/DTI/templates/98AP_emptyzstack.nii.gz
echo "98 AP merged"

# ── Merge files for 99 AP ─────────────────────────────────────────────────────
fslmerge -z "${PROC_DIR}/${iSub}_dMRI_dir99_AP_zstack.nii.gz" \
    /fs/ess/PAS2003/Scripts/DTI/templates/99AP_emptyzstack.nii.gz \
    /fs/ess/PAS2003/Scripts/DTI/templates/99AP_emptyzstack.nii.gz \
    "${IN_DIR}/${iSub}/Diffusion/${iSub}_dMRI_dir99_AP.nii.gz" \
    /fs/ess/PAS2003/Scripts/DTI/templates/99AP_emptyzstack.nii.gz \
    /fs/ess/PAS2003/Scripts/DTI/templates/99AP_emptyzstack.nii.gz
echo "99 AP merged"

# ── Merge files for 98 PA ─────────────────────────────────────────────────────
fslmerge -z "${PROC_DIR}/${iSub}_dMRI_dir98_PA_zstack.nii.gz" \
    /fs/ess/PAS2003/Scripts/DTI/templates/98PA_emptyzstack.nii.gz \
    /fs/ess/PAS2003/Scripts/DTI/templates/98PA_emptyzstack.nii.gz \
    "${IN_DIR}/${iSub}/Diffusion/${iSub}_dMRI_dir98_PA.nii.gz" \
    /fs/ess/PAS2003/Scripts/DTI/templates/98PA_emptyzstack.nii.gz \
    /fs/ess/PAS2003/Scripts/DTI/templates/98PA_emptyzstack.nii.gz
echo "98 PA merged"

# ── Merge files for 99 PA ─────────────────────────────────────────────────────
fslmerge -z "${PROC_DIR}/${iSub}_dMRI_dir99_PA_zstack.nii.gz" \
    /fs/ess/PAS2003/Scripts/DTI/templates/99PA_emptyzstack.nii.gz \
    /fs/ess/PAS2003/Scripts/DTI/templates/99PA_emptyzstack.nii.gz \
    "${IN_DIR}/${iSub}/Diffusion/${iSub}_dMRI_dir99_PA.nii.gz" \
    /fs/ess/PAS2003/Scripts/DTI/templates/99PA_emptyzstack.nii.gz \
    /fs/ess/PAS2003/Scripts/DTI/templates/99PA_emptyzstack.nii.gz
echo "99 PA merged"

echo "zstack images created for ${iSub} — done at $(date)"
