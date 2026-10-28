#!/bin/bash
#SBATCH --job-name=run_topup
#SBATCH --account=PAS2003
#SBATCH --nodes=4 --ntasks-per-node=8
#SBATCH --time=02:00:00
#SBATCH --mail-type=BEGIN,END,FAIL

# Set up environment
module load fsl/6.0.7.13
source $FSLDIR/etc/fslconf/fsl.sh

export BASE_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/data

echo "Environment set up for $(hostname) at $(date)"

#------------- NOTHING BELOW HERE SHOULD BE MODIFIED--------------------
iSub=$1

if [[ -z "$iSub" ]]; then
    echo "ERROR: no subject ID provided. Usage: sbatch run_topup.sh <SubjectID>"
    exit 1
fi

PROC_DIR="${BASE_DIR}/${iSub}/processed"
RAW_DIR="${BASE_DIR}/${iSub}/Diffusion"

# Verify zstack inputs exist before doing any work
for scan in dir98_AP dir99_AP dir98_PA dir99_PA; do
    f="${PROC_DIR}/${iSub}_dMRI_${scan}_zstack.nii.gz"
    if [[ ! -f "$f" ]]; then
        echo "ERROR: missing zstack file: $f"
        exit 1
    fi
done

# Verify SBRef JSON exists for readout time
Ref_json="${RAW_DIR}/${iSub}_dMRI_dir98_AP_SBRef.json"
if [[ ! -f "$Ref_json" ]]; then
    echo "ERROR: missing SBRef JSON: $Ref_json"
    exit 1
fi

echo "Starting topup for ${iSub}"

# Extract first volume (b0) for all 4 scans
fslroi "${PROC_DIR}/${iSub}_dMRI_dir98_AP_zstack.nii.gz" "${PROC_DIR}/nodif_98_AP_zstack" 0 1
fslroi "${PROC_DIR}/${iSub}_dMRI_dir99_AP_zstack.nii.gz" "${PROC_DIR}/nodif_99_AP_zstack" 0 1
fslroi "${PROC_DIR}/${iSub}_dMRI_dir98_PA_zstack.nii.gz" "${PROC_DIR}/nodif_98_PA_zstack" 0 1
fslroi "${PROC_DIR}/${iSub}_dMRI_dir99_PA_zstack.nii.gz" "${PROC_DIR}/nodif_99_PA_zstack" 0 1
echo "First volumes extracted for ${iSub}"

# Combine b0 volumes across all 4 scans
fslmerge -t "${PROC_DIR}/AP_PA_b0_zstack" \
    "${PROC_DIR}/nodif_98_AP_zstack" \
    "${PROC_DIR}/nodif_99_AP_zstack" \
    "${PROC_DIR}/nodif_98_PA_zstack" \
    "${PROC_DIR}/nodif_99_PA_zstack"
echo "Volumes combined for ${iSub}"

# Get readout time and create acqparams file
readout_time=$(cat "${Ref_json}" | grep "TotalReadoutTime" | awk -F[:,] '{print $2}')

if [[ -z "$readout_time" ]]; then
    echo "ERROR: could not extract TotalReadoutTime from ${Ref_json}"
    exit 1
fi

cat << ACQPARAM > "${PROC_DIR}/acqparams.txt"
0 -1 0 $readout_time
0 -1 0 $readout_time
0 1 0 $readout_time
0 1 0 $readout_time
ACQPARAM
echo "acqparams file created (TotalReadoutTime=${readout_time})"

# Run topup
echo "Initiating topup for ${iSub}"
topup --imain="${PROC_DIR}/AP_PA_b0_zstack.nii.gz" \
      --datain="${PROC_DIR}/acqparams.txt" \
      --config=b02b0.cnf \
      --out="${PROC_DIR}/topup_AP_PA_b0_zstack" \
      --iout="${PROC_DIR}/topup_AP_PA_b0_iout_zstack" \
      --fout="${PROC_DIR}/topup_AP_PA_b0_fout_zstack"

echo "topup complete for ${iSub} at $(date)"
