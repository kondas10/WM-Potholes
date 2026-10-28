#!/bin/bash
# submit_topup.sh
# Usage: bash submit_topup.sh
# Reads sublist.txt and submits one topup job per subject.

# ── Paths ─────────────────────────────────────────────────────────────────────
SUBLIST=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/controls.txt
TOPUP_SCRIPT=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/run_topup.sh
LOG_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/logs/topup

mkdir -p "$LOG_DIR"

n_submitted=0

while IFS= read -r iSub || [[ -n "$iSub" ]]; do

    [[ -z "$iSub" || "$iSub" == \#* ]] && continue

    sbatch \
        --job-name="topup_${iSub}" \
        --account=PAS2003 \
        --nodes=4 \
        --ntasks-per-node=8 \
        --time=02:00:00 \
        --output="${LOG_DIR}/${iSub}_%j.log" \
        --mail-type=FAIL \
        "$TOPUP_SCRIPT" "$iSub"

    echo "Submitted topup job for ${iSub}"
    (( n_submitted++ ))

done < "$SUBLIST"

echo ""
echo "────────────────────────────────────────"
echo "Submitted: ${n_submitted} jobs"
echo "────────────────────────────────────────"
