#!/bin/bash
#SBATCH --job-name=run_quad
#SBATCH --account=PAS2321
#SBATCH --nodes=4 --ntasks-per-node=8
#SBATCH --time=00:15:00
#SBATCH --mail-type=BEGIN,END,FAIL


#Set up environment
module load fsl/6.0.4
source $FSLDIR/etc/fslconf/fsl.sh
export OUT_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/eddy_qc #change export directory for your analysis, where output should be stored
export IN_DIR=/fs/ess/PAS2321/Helper/tbss #where processed data is stored

echo "environment has been set up"

iSub=$1

eddy_quad "$IN_DIR"/$iSub/eddy_unwarped_images_zstack_slspec_allruns \
-idx "$IN_DIR"/$iSub/index.txt \
-par "$IN_DIR"/$iSub/acqparams.txt \
-m "$IN_DIR"/$iSub/hifi_nodif_zstack_brain_mask \
-b "$IN_DIR"/$iSub/bvals \
-s /fs/ess/PAS2003/Scripts/DTI/templates/slicebuff_slspec_singlerun.txt \
-f "$IN_DIR"/$iSub/topup_AP_PA_b0_fout_zstack \
-o "$OUT_DIR"/quad_${iSub}

echo "QUAD run for $iSub, all done"