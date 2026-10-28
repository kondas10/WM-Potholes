# White Matter Potholes
Code used in the manuscript "White Matter Potholes: A Step Towards Individualized Markers of Microstructural Abnormality in Aging and Traumatic Brain Injury"

## Pipeline:
### Move DWI to correct location with move.sh
### Process DWI data with run_zstack.sh, run_topup.sh, and run_eddy.sh and submit counterparts
### Quality assurance with run_quad.sh, DTI_qc_quad.sh, and DTI_qc_squad.sh
### Run TBSS with tbss.sh
### Create potholes with potholes_fa.sh
### Extract potholes in whole brain with pothole_export.sh
### Extract potholes in ROIs with roi_extraction.py
### Run analyses in R with WM_Potholes_Analysis.qmd
