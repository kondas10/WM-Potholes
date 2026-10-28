#!/bin/bash
#SBATCH --job-name=run_eddy
#SBATCH --account=PAS2003
#SBATCH --ntasks-per-node=8 --gpus-per-node=1
#SBATCH --time=48:00:00
#SBATCH --mail-type=BEGIN,END,FAIL

#Set up environment
module load fsl/6.0.7.13 #changed from 6.0.4 to 6.0.7.13
module load cuda/12.4.1 #changed from 9.1.85 after pitzer updated ##considered changing to 12.4.1 after pitzer update
source $FSLDIR/etc/fslconf/fsl.sh
export OUT_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/data #change export directory for your analysis, where output should be stored
export IN_DIR=/fs/ess/PAS2116/Data/0810DataPull/HCPA-AllImgData/imagingcollection01/ #input directory to where your raw data are stored

echo "environment has been set up"

#------------- NOTHING BELOW HERE SHOULD BE MODIFIED--------------------
iSub=$1

#Create average image of the corrected b0 volumes
fslmaths "$OUT_DIR"/$iSub/processed/topup_AP_PA_b0_iout_zstack -Tmean "$OUT_DIR"/$iSub/processed/hifi_nodif_zstack

echo "hifi_nodif created for $iSub"

#Use bet on averaged b0 (hifi_nodif created above). Creating a binary brain mask with fraction intensity threshold of 0.2
bet "$OUT_DIR"/$iSub/processed/hifi_nodif_zstack "$OUT_DIR"/$iSub/processed/hifi_nodif_zstack_brain -m -f .2

echo "BET run for $iSub"

#Concatenate bvecs and bvals files in order {98 AP 99 AP 98 PA 99 PA} to create 1 bval and 1 bvec file with all 4 scans
paste -d" " \
  "$IN_DIR"/$iSub/unprocessed/Diffusion/${iSub}_dMRI_dir98_AP.bval \
  "$IN_DIR"/$iSub/unprocessed/Diffusion/${iSub}_dMRI_dir99_AP.bval \
  "$IN_DIR"/$iSub/unprocessed/Diffusion/${iSub}_dMRI_dir98_PA.bval \
  "$IN_DIR"/$iSub/unprocessed/Diffusion/${iSub}_dMRI_dir99_PA.bval > "$OUT_DIR"/$iSub/processed/bvals

paste -d" " \
  "$IN_DIR"/$iSub/unprocessed/Diffusion/${iSub}_dMRI_dir98_AP.bvec \
  "$IN_DIR"/$iSub/unprocessed/Diffusion/${iSub}_dMRI_dir99_AP.bvec \
  "$IN_DIR"/$iSub/unprocessed/Diffusion/${iSub}_dMRI_dir98_PA.bvec \
  "$IN_DIR"/$iSub/unprocessed/Diffusion/${iSub}_dMRI_dir99_PA.bvec > "$OUT_DIR"/$iSub/processed/bvecs

echo "bvec and bval files concatenated for $iSub"

#Create index file
indx=""
for ((i=1; i<=99; i+=1)); do indx="$indx 1"; done
for ((i=1; i<=100; i+=1)); do indx="$indx 2"; done
for ((i=1; i<=99; i+=1)); do indx="$indx 3"; done
for ((i=1; i<=100; i+=1)); do indx="$indx 4"; done
echo $indx > "$OUT_DIR"/$iSub/processed/index.txt

echo "index file created"

#Create full diffusion data file for imain in eddy (in appropriate scan order)
fslmerge -t "$OUT_DIR"/$iSub/processed/AP_PA_scan_zstack \
"$OUT_DIR"/$iSub/processed/${iSub}_dMRI_dir98_AP_zstack.nii.gz \
"$OUT_DIR"/$iSub/processed/${iSub}_dMRI_dir99_AP_zstack.nii.gz \
"$OUT_DIR"/$iSub/processed/${iSub}_dMRI_dir98_PA_zstack.nii.gz \
"$OUT_DIR"/$iSub/processed/${iSub}_dMRI_dir99_PA_zstack.nii.gz

echo "full diffusion data file created for $iSub"

# changed from 9.1 to 10.2
echo "initiate eddy"
eddy_cuda10.2 --imain="$OUT_DIR"/$iSub/processed/AP_PA_scan_zstack --mask="$OUT_DIR"/$iSub/processed/hifi_nodif_zstack_brain_mask \
     --index="$OUT_DIR"/$iSub/processed/index.txt \
     --acqp="$OUT_DIR"/$iSub/processed/acqparams.txt \
     --bvecs="$OUT_DIR"/$iSub/processed/bvecs \
     --bvals="$OUT_DIR"/$iSub/processed/bvals \
     --fwhm=0 \
     --topup="$OUT_DIR"/$iSub/processed/topup_AP_PA_b0_zstack \
     --out="$OUT_DIR"/$iSub/processed/eddy_unwarped_images_zstack_slspec_allruns \
     --data_is_shelled \
     --repol \
     --ol_type=both \
     --mporder=10 \
     --slspec=/fs/ess/PAS2003/Scripts/DTI/templates/slicebuff_slspec_singlerun.txt
     
echo "eddy run for $iSub, all done"
