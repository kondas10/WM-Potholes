#!/bin/bash
# submit_eddy.sh
# Usage: bash submit_eddy.sh
# Reads sublist.txt and submits one eddy job per subject.

# ── Paths ─────────────────────────────────────────────────────────────────────
SUBLIST=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/controls.txt
EDDY_SCRIPT=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/run_eddy.sh
LOG_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/logs/eddy

mkdir -p "$LOG_DIR"

n_submitted=0

while IFS= read -r iSub || [[ -n "$iSub" ]]; do

    [[ -z "$iSub" || "$iSub" == \#* ]] && continue

    sbatch \
        --job-name="eddy_${iSub}" \
        --account=PAS2003 \
        --nodes=4 \
        --ntasks-per-node=8 \
        --gpus-per-node=1 \
        --time=48:00:00 \
        --output="${LOG_DIR}/${iSub}_%j.log" \
        --mail-type=FAIL \
        "$EDDY_SCRIPT" "$iSub"

    echo "Submitted eddy job for ${iSub}"
    (( n_submitted++ ))

done < "$SUBLIST"

echo ""
echo "────────────────────────────────────────"
echo "Submitted: ${n_submitted} jobs"
echo "────────────────────────────────────────"
