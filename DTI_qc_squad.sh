#!/bin/bash
#SBATCH --job-name=run_squad
#SBATCH --account=PAS2321
#SBATCH --nodes=4 --ntasks-per-node=8
#SBATCH --time=02:00:00
#SBATCH --mail-type=BEGIN,END,FAIL

#before running this script you must generate list of quad output as txt file
    #txt file must specify full pathway for each qc folder, see code below:
    # find /fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/eddy_qc -mindepth 1 -maxdepth 1 -type d > quad_folders.txt

#run this script in the terminal with: sbatch DTI_qc_squad.sh

#Set up environment
module load fsl/6.0.4
source $FSLDIR/etc/fslconf/fsl.sh
export OUT_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/eddy_qc #change export directory for your analysis, where output should be stored

echo "environment has been set up"

cd "$OUT_DIR"

echo "start squad"
#run squad
eddy_squad "$OUT_DIR"/quad_folders.txt -u

echo "squad complete"