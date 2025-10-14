#!/bin/bash

# Usage:
# ./collect_existing_fullCLs.sh <mass1> [mass2 mass3 ...]

QUANTILES=("0.025" "0.16" "0.5" "0.84" "0.975")

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <mass1> [mass2 mass3 ...]"
    exit 1
fi

SUMMARY_FILE="FullCLs_limits_summary.json"
echo "{" > "$SUMMARY_FILE"
MASS_COUNT=0

for MASS in "$@"; do
    WORKDIR="fullCLs_mass_${MASS}/BatchMerged_output/FinalMergedFull"
    OUTFILE="fullCLs_mass_${MASS}/limits_mass_${MASS}.json"

    if [ ! -d "$WORKDIR" ]; then
        echo "❌ ERROR: Directory not found for mass $MASS at $WORKDIR"
        continue
    fi

    echo ">>> Collecting limits for mass ${MASS} from existing logs"
    echo "{" > "$OUTFILE"

    for i in "${!QUANTILES[@]}"; do
        Q="${QUANTILES[$i]}"
        LOGFILE="${WORKDIR}/quantile_${Q}_m${MASS}.log"

        if [ ! -f "$LOGFILE" ]; then
            echo "⚠️ Missing log file: $LOGFILE"
            RVAL="null"
        else
            RVAL=$(grep "Limit: r <" "$LOGFILE" | awk '{print $4}')
        fi

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

    OBS_LOGFILE="${WORKDIR}/observed_m${MASS}.log"
    if [ ! -f "$OBS_LOGFILE" ]; then
        echo "⚠️ Missing observed log file: $OBS_LOGFILE"
        OBSVAL="null"
    else
        OBSVAL=$(grep "Limit: r <" "$OBS_LOGFILE" | awk '{print $4}')
    fi
    echo "  ,\"obs\": $OBSVAL" >> "$OUTFILE"

    echo "}" >> "$OUTFILE"
    echo "Saved limits to $OUTFILE"

    # Append to summary JSON
    if [ "$MASS_COUNT" -gt 0 ]; then
        echo "," >> "$SUMMARY_FILE"
    fi
    echo "  \"$MASS\": $(cat "$OUTFILE")" >> "$SUMMARY_FILE"
    MASS_COUNT=$((MASS_COUNT + 1))
done

echo "}" >> "$SUMMARY_FILE"
echo ">>> Combined summary written to $SUMMARY_FILE"
