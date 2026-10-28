#!/bin/bash

#SCRIPT INSTRUCTIONS
#Before running script, sublist must be generated
#Step 1 - set OUT_DIR as the pathway to the directory where you want run logs to be exported
    #and sublist as correct file name
#Step 2 - check pathways for script to be run and change if your script is stored elsewhere 
#Step 3 - run this script in the terminal (with command ./run_quad.sh)

#Define OUT_DIR, sublist, & stage of pipeline to run
export OUT_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/eddy_qc_run_logs #directory where RUN LOGS should be stored
sublist=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/sublist_qc.txt #define sublist

cd "$OUT_DIR"

for iSub in `cat $sublist`; do sbatch /fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/scripts/eddy_qc/DTI_qc_quad.sh $iSub; done
echo "running DTI_qc_quad"
