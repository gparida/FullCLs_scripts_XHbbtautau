#!/bin/bash

# Usage:
# ./collect_results_fullCLs.sh <mass1> [mass2 mass3 ...]

QUANTILES=("0.025" "0.16" "0.5" "0.84" "0.975")

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <mass1> [mass2 mass3 ...]"
    exit 1
fi

echo ">>> Starting limit collection using HybridNew"

SUMMARY_FILE="FullCLs_limits_summary.json"
echo "{" > "$SUMMARY_FILE"
MASS_COUNT=0

for MASS in "$@"; do
    WORKDIR="fullCLs_mass_${MASS}"
    FINAL_MERGED_FILE="${WORKDIR}/BatchMerged_output/FinalMergedFull/final_merged_fullCLs_mass_${MASS}.root"
    COMBINE_INPUT="../../combined_run2_${MASS}.root"
    OUTFILE="limits_mass_${MASS}.json"

    if [ ! -f "$FINAL_MERGED_FILE" ]; then
        echo "❌ ERROR: Final merged file not found for mass $MASS at $FINAL_MERGED_FILE"
        continue
    fi

    echo ">>> Collecting limits for mass ${MASS}"
    echo "{" > "$OUTFILE"

    # Go into the directory of final merged file
    cd "$(dirname "$FINAL_MERGED_FILE")" || exit 1

    for i in "${!QUANTILES[@]}"; do
        Q="${QUANTILES[$i]}"
        LOGFILE="quantile_${Q}_m${MASS}.log"

        echo "  Running quantile $Q..."

        combine "$COMBINE_INPUT" \
            -M HybridNew \
            --LHCmode LHC-limits \
            --readHybridResults \
            --grid="$(basename "$FINAL_MERGED_FILE")" \
            --expectedFromGrid "$Q" \
            -m 125 | tee "$LOGFILE"

        RVAL=$(grep "Limit: r <" "$LOGFILE" | awk '{print $4}')

        # Rename quantile keys
        case "$Q" in
            "0.5")   QKEY="exp0" ;;
            "0.84")  QKEY="exp+1" ;;
            "0.975") QKEY="exp+2" ;;
            "0.16")  QKEY="exp-1" ;;
            "0.025") QKEY="exp-2" ;;
            *)       QKEY="q${Q}" ;;
        esac

        if [ "$i" -lt "$((${#QUANTILES[@]} - 1))" ]; then
            echo "  \"$QKEY\": $RVAL," >> "$OUTFILE"
        else
            echo "  \"$QKEY\": $RVAL" >> "$OUTFILE"
        fi
    done

    echo "  Running observed limit..."
    OBS_LOGFILE="observed_m${MASS}.log"

    combine "$COMBINE_INPUT" \
        -M HybridNew \
        --LHCmode LHC-limits \
        --readHybridResults \
        --grid="$(basename "$FINAL_MERGED_FILE")" \
        -m 125 | tee "$OBS_LOGFILE"

    OBSVAL=$(grep "Limit: r <" "$OBS_LOGFILE" | awk '{print $4}')
    echo "  ,\"obs\": $OBSVAL" >> "$OUTFILE"

    echo "}" >> "$OUTFILE"
    echo "Saved limits to $(pwd)/$OUTFILE"

    # Add to summary JSON
    cd - > /dev/null
    if [ "$MASS_COUNT" -gt 0 ]; then
        echo "," >> "$SUMMARY_FILE"
    fi
    echo "  \"$MASS\": $(cat "$OUTFILE")" >> "$SUMMARY_FILE"
    MASS_COUNT=$((MASS_COUNT + 1))
done

echo "}" >> "$SUMMARY_FILE"
echo ">>> Combined summary written to $SUMMARY_FILE"
