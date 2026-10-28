#!/bin/bash
# submit_zstack.sh
# Usage: bash submit_zstack.sh
# Reads sublist.txt and submits one zstack job per subject.

# ── Paths ─────────────────────────────────────────────────────────────────────
SUBLIST=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/controls.txt
ZSTACK_SCRIPT=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/run_zstack.sh
LOG_DIR=/fs/ess/PAS2321/Projects/mindset_jmoody_dti-potholes-aging-tbi/logs/zstack

mkdir -p "$LOG_DIR"

n_submitted=0
n_skip=0

while IFS= read -r iSub || [[ -n "$iSub" ]]; do

    [[ -z "$iSub" || "$iSub" == \#* ]] && continue

    sbatch \
        --job-name="zstack_${iSub}" \
        --account=PAS2003 \
        --nodes=1 \
        --ntasks-per-node=8 \
        --time=01:00:00 \
        --output="${LOG_DIR}/${iSub}_%j.log" \
        --mail-type=FAIL \
        "$ZSTACK_SCRIPT" "$iSub"

    echo "Submitted zstack job for ${iSub}"
    (( n_submitted++ ))

done < "$SUBLIST"

echo ""
echo "────────────────────────────────────────"
echo "Submitted: ${n_submitted} jobs"
echo "────────────────────────────────────────"
