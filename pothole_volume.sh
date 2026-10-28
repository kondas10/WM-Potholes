#before running this script, rename potholes directories to potholes_fa or potholes_md

#set up environment
export OUT_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/AK #output directory where analyses will be stored
export FA_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final/potholes_fa/sample/thresholded/clusters
export MD_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/final/potholes_md/sample/thresholded/clusters
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

echo "now exporting volume" 

#export total volume of FA clusters in each subject to a text file
for sub in `cat $sample_list`; do \
sub=$(echo $sub | tr -d '\r')
total=$(awk '$1 !~ /^#/ {sum+=$3} END {print sum}' "$FA_DIR"/${sub}_cluster_n5.txt)
echo $total >> "$OUT_DIR"/potholes_output_txt/cluster_total_volume_fa.txt; done
#merge sublist and number of clusters into single text file
paste "$OUT_DIR"/potholes_output_txt/potholes_output_temp2.txt "$OUT_DIR"/potholes_output_txt/cluster_total_volume_fa.txt | column -s $'\t' -t >> "$OUT_DIR"/potholes_output_txt/potholes_output.txt




