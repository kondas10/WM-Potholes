#!/bin/bash
#SBATCH --job-name=run_tbss
#SBATCH --account=PAS2321
#SBATCH --nodes=1 --ntasks-per-node=8
#SBATCH --time=24:00:00
#SBATCH --mail-type=BEGIN,END,FAIL

#Set up environment
module load fsl/6.0.4
source $FSLDIR/etc/fslconf/fsl.sh
export OUT_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final #change export directory for your analysis, where output should be stored
sublist=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final/sample.txt #read in sample for your analysis
reflist=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final/controls.txt #read in controls for your analysis
#COMMENTS
    #be sure to change the time you submit the job for based on number of subjects, if needed.
    #tbss_1 is generally quick, tbss_2 takes ~10 min per subject
    
echo "environment has been set up"

#Put all FA maps into single directory called tbss
mkdir "$OUT_DIR"/tbss
for iSub in `cat $sublist`; do cp /fs/ess/PAS2321/Data/imaging/$iSub/processed/diffusion_dtifit/${iSub}_diffusion.dc.eddy.dtifit.fa.nii.gz "$OUT_DIR"/tbss/${iSub}.nii.gz; done
for iSub in `cat $reflist`; do cp /fs/ess/PAS2116/JM_potholes_ref/dti_processing/$iSub/dtifit_out_FA.nii.gz "$OUT_DIR"/tbss/${iSub}.nii.gz; done

echo "all FA maps have been put into single directory"

#run TBBS step 1 -- 
    #erodes FA images slightly to remove brain-edge artifacts and zero the end slices (removes likely outliers)
    #This should be run from the TBSS directory
cd "$OUT_DIR"/tbss
tbss_1_preproc *nii.gz

echo "TBSS step 1 has been run"

#run TBSS step 2 --
    #nonlinear registration and aligning all the FA data across all subjects to the FMRIB58_FA template
    #This should be run from TBSS directory (or one directory before the FA directory)
cd "$OUT_DIR"/tbss
tbss_2_reg -T

echo "TBSS step 2 has been run"

#Run TBSS step 3 — 
    #apply registration from step 2 to bring FA data to standard space. This does the warping
    #This should be run from the tbss directory (or one directory before the FA directory)
cd "$OUT_DIR"/tbss
tbss_3_postreg -S

echo "TBSS step 3 has been run"

# Run TBSS step 4 — 
    #threshold the mean FA skeleton at .2 threshold & project FA data onto mean FA skeleton
    #This should be run from the tbss directory (or one directory before the stats directory)
cd "$OUT_DIR"/tbss
tbss_4_prestats 0.2

echo "TBSS step 4 has been run, all done"