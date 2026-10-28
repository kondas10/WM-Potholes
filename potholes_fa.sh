#!/bin/bash
#SBATCH --job-name=run_potholes_fa
#SBATCH --account=PAS2321
#SBATCH --nodes=1 --ntasks-per-node=8
#SBATCH --time=1:00:00
#SBATCH --mail-type=BEGIN,END,FAIL


#BEFORE RUNNING THIS SCRIPT--
    #define your MAIN_DIR
    #within your MAIN_DIR, you must have 4 txt files: sublist.txt (everyone), sample.txt (sample only), 
        #controls.txt (reference group only), and controls_images_list.txt (reference group images names)
    #within your MAIN_DIR, you must have tbss output (stored in original directory structure)
    #make sure your volume list has appropriate number of subjects (see line 60)

echo "BEGIN POTHOLES_FA.SH"

#set up environment
module load fsl/6.0.4
module load freesurfer/7.2.0
source $FREESURFER_HOME/SetUpFreeSurfer.sh
source $FSLDIR/etc/fslconf/fsl.sh

#define main directory
export MAIN_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final

echo "environment has been set up"

#-----------------PART ONE, SET UP DIRECTORIES FOR POTHOLES--------------------------------------------------------

echo "***** BEGIN PART ONE - SET UP DIRECTORIES FOR POTHOLES *****"

#create analysis directories
mkdir "$MAIN_DIR"/potholes
mkdir "$MAIN_DIR"/potholes/splits
mkdir "$MAIN_DIR"/potholes/sublists
mkdir "$MAIN_DIR"/potholes/controls_all
mkdir "$MAIN_DIR"/potholes/controls_ind
mkdir "$MAIN_DIR"/potholes/sample
mkdir "$MAIN_DIR"/potholes/sample/thresholded

echo "analysis directories have been created"

#copy relevant files to analysis directory
cp "$MAIN_DIR"/tbss/stats/all_FA_skeletonised.nii.gz "$MAIN_DIR"/potholes/splits/all_FA_skeletonised.nii.gz
cp "$MAIN_DIR"/sublist.txt "$MAIN_DIR"/potholes/sublists/sublist.txt
cp "$MAIN_DIR"/sample.txt "$MAIN_DIR"/potholes/sublists/sample.txt
cp "$MAIN_DIR"/controls.txt "$MAIN_DIR"/potholes/sublists/controls.txt
cp "$MAIN_DIR"/controls_images_list.txt "$MAIN_DIR"/potholes/sublists/controls_images_list.txt

echo "all_FA_skeletonized and sublists have been copied to appropriate analysis directory"

#split 4D all_FA_skeletonised into individual files for each subject
cd "$MAIN_DIR"/potholes/splits
fslsplit all_FA_skeletonised.nii.gz
mkdir "$MAIN_DIR"/potholes/tbss_output
mv "$MAIN_DIR"/potholes/splits/all_FA_skeletonised.nii.gz "$MAIN_DIR"/potholes/tbss_output/all_FA_skeletonised.nii.gz

echo "all_FA_skeletonized has been split into individual 3D files for each subject"

#create volume list -- specific to number of people in sample
cat << VOLS >"$MAIN_DIR"/potholes/sublists/vollist.txt
0000
0001
0002
0003
0004
0005
0006
0007
0008
0009
0010
0011
0012
0013
0014
0015
0016
0017
0018
0019
0020
0021
0022
0023
0024
0025
0026
0027
0028
0029
0030
0031
0032
0033
0034
0035
0036
0037
0038
0039
0040
0041
0042
0043
0044
0045
0046
0047
0048
0049
0050
0051
0052
0053
0054
0055
0056
0057
0058
0059
0060
0061
0062
0063
0064
0065
0066
0067
0068
0069
0070
0071
0072
0073
0074
0075
0076
0077
0078
0079
0080
0081
0082
0083
0084
0085
0086
0087
0088
0089
0090
0091
0092
0093
0094
0095
0096
0097
0098
0099
0100
0101
0102
0103
0104
0105
0106
0107
0108
0109
0110
0111
0112
0113
0114
0115
0116
0117
0118
0119
0120
0121
0122
0123
0124
0125
0126
0127
0128
0129
0130
0131
0132
0133
0134
0135
0136
0137
0138
0139
0140
0141
0142
0143
0144
0145
0146
0147
0148
0149
0150
0151
0152
0153
VOLS

echo "volume list txt file has been created"

#merge sublist and vol_list
cd "$MAIN_DIR"/potholes/sublists
paste sublist.txt vollist.txt | column -s $'\t' -t >> sub_vol_link.txt

echo "subject list and volume list have been merged"

#rename individual 3D nii.gz files from volnum to subject ID
cat sub_vol_link.txt | while read -r iSub volnum; \
do mv "$MAIN_DIR"/potholes/splits/vol${volnum}.nii.gz "$MAIN_DIR"/potholes/splits/${iSub}_posttbss.nii.gz; done

echo "individual 3D nii.gz files have been renamed from volume number to subject ID"

echo "***** PART ONE COMPLETE - SET UP DIRECTORIES FOR POTHOLES *****"

#-----------------PART TWO, CALCULATE Z-SCORES--------------------------------------------------------

echo "***** BEGIN PART TWO - CALCULATE Z-SCORES *****"

#define lists
sample_list="$MAIN_DIR"/potholes/sublists/sample.txt
control_list="$MAIN_DIR"/potholes/sublists/controls.txt
control_images_list="$MAIN_DIR"/potholes/sublists/controls_images_list.txt

#CREATE AVERAGE IMAGE
echo "begin process for calculating average image"
cd "$MAIN_DIR"/potholes/splits
mri_concat --f "$MAIN_DIR"/potholes/sublists/controls_images_list.txt \
--o "$MAIN_DIR"/potholes/controls_all/avg.nii.gz \
--mean
echo "process for calculating average image is complete"

#CREATE STANDARD DEVIATION IMAGE
echo "begin process for calculating SD image"
cd "$MAIN_DIR"/potholes/splits
mri_concat --f "$MAIN_DIR"/potholes/sublists/controls_images_list.txt \
--o "$MAIN_DIR"/potholes/controls_all/sd.nii.gz \
--std
echo "process for calculating SD image is complete"

#CREATE Z-SCORES
echo "begin process for calculating z-scores"
#perform subtraction -- subtract average of controls from each sample subject
for sub in `cat $sample_list`; do fslmaths "$MAIN_DIR"/potholes/splits/${sub}_posttbss.nii.gz -sub "$MAIN_DIR"/potholes/controls_all/avg.nii.gz "$MAIN_DIR"/potholes/sample/${sub}_subtraction.nii.gz; done
#divide subtracted value by control SD
for sub in `cat $sample_list`; do fslmaths "$MAIN_DIR"/potholes/sample/${sub}_subtraction.nii.gz -div "$MAIN_DIR"/potholes/controls_all/sd.nii.gz "$MAIN_DIR"/potholes/sample/${sub}_z.nii.gz; done
#threshold images at -3
for sub in `cat $sample_list`; do fslmaths "$MAIN_DIR"/potholes/sample/${sub}_z.nii.gz -uthr -3 "$MAIN_DIR"/potholes/sample/thresholded/${sub}_z_thresh.nii.gz; done
echo "process for calculating z-scores is complete"

echo "***** PART TWO COMPLETE - CALCULATE Z-SCORES *****"

#-----------------PART THREE, GENERATE CLUSTERS--------------------------------------------------------

echo "***** BEGIN PART THREE - GENERATE CLUSTERS *****"

#create directory for clusters
mkdir "$MAIN_DIR"/potholes/sample/thresholded/clusters

#generate clusters using mri_volcluster for each subject in sample
for sub in `cat $sample_list`; do \
mri_volcluster --in "$MAIN_DIR"/potholes/sample/thresholded/${sub}_z_thresh.nii.gz \
--minsizevox 5 \
--thmin 3 \
--sign neg \
--no-adjust \
--mni152reg \
--sum "$MAIN_DIR"/potholes/sample/thresholded/clusters/${sub}_cluster_n5.txt \
--ocn "$MAIN_DIR"/potholes/sample/thresholded/clusters/${sub}_cluster_n5.nii.gz; done

echo "***** PART THREE COMPLETE - GENERATE CLUSTERS *****"
echo "POTHOLES_FA.SH COMPLETE"
