#before running this script, rename potholes directories to potholes_fa

#set up environment
export OUT_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final #output directory where analyses will be stored
export FA_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final/potholes_fa/sample/thresholded/clusters
sample_list="$OUT_DIR"/sample.txt #individuals who are part of study sample
mkdir "$OUT_DIR"/potholes_output_txt

echo "environment has been set up"

#EXPORT FA POTHOLES
echo "now exporting FA potholes data, starting with number of clusters then number of voxels in largest cluster"

#export number of FA clusters for each subject to a text file
for sub in `cat $sample_list`; do \
awk '/NClusters/ {print $3}' "$FA_DIR"/${sub}_cluster_n5.txt >> "$OUT_DIR"/potholes_output_txt/num_clusters_fa.txt; done
#merge sublist and number of clusters into single text file
paste "$OUT_DIR"/sample.txt "$OUT_DIR"/potholes_output_txt/num_clusters_fa.txt | column -s $'\t' -t >> "$OUT_DIR"/potholes_output_txt/potholes_output_temp1.txt

#export number of voxels in largest FA cluster for each subject to a text file
for sub in `cat $sample_list`; do \
awk 'NR==28 {print $2}' "$FA_DIR"/${sub}_cluster_n5.txt >> "$OUT_DIR"/potholes_output_txt/largest_cluster_fa.txt; done
#merge largest FA cluster into temp1 text file
paste "$OUT_DIR"/potholes_output_txt/potholes_output_temp1.txt "$OUT_DIR"/potholes_output_txt/largest_cluster_fa.txt | column -s $'\t' -t > "$OUT_DIR"/potholes_output_txt/potholes_output_temp2.txt


#CREATE FINAL FILE AND CLEAN UP DIRECTORY
echo "now adding column names and generating final output file"
#add column names 
echo "anon_subid num_potholes_fa largest_pothole_fa num_potholes_md largest_pothole_md" > "$OUT_DIR"/potholes_output_txt/potholes_output_final.txt
cat "$OUT_DIR"/potholes_output_txt/potholes_output_temp1.txt >> "$OUT_DIR"/potholes_output_txt/potholes_output_final.txt

echo "now deleting temp files to clean up output_txt directory"
#delete temp files
rm "$OUT_DIR"/potholes_output_txt/potholes_output_temp*.txt

echo "ALL DONE :) POTHOLES_OUTPUT_FINAL.TXT IS READY TO USE FOR ANALYSES"
