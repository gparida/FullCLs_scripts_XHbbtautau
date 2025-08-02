#!/bin/bash

CONFIG_FILE=$1
REMOTE_PATH=$2
UW_USERNAME=$3

# Parameters
SEED_START=0
SEED_END=50
BATCH_SIZE=25
#GRID_POINTS=800  # Number of grid points in r scan

if [ -z "$CONFIG_FILE" ] || [ -z "$REMOTE_PATH" ]; then
    echo "Usage: ./submit_condor_fullCLs.sh <config_file> <remote_workspace_path> <UW login user name>"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found!"
    exit 1
fi

echo ">>> Reading mass/grid config from: $CONFIG_FILE"
echo ">>> Copying workspaces from: $REMOTE_PATH"

# Download all required root files in one go
echo "---------------------------------------"
echo ">>> Copying all workspace.root files from remote to local. All files are copied but only the uncommented mass points in mass_config.txt will be run"
echo "---------------------------------------"
#scp parida@login.hep.wisc.edu:${REMOTE_PATH}/combined_run2_*.root ./ || { echo "SCP failed"; exit 2; }
scp ${UW_USERNAME}@login.hep.wisc.edu:${REMOTE_PATH}/combined_run2_*.root ./ || { echo "SCP failed"; exit 2; }

# Begin processing
while read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

    MASS=$(echo "$line" | awk '{print $1}')
    GRID_START=$(echo "$line" | awk '{print $2}')
    GRID_END=$(echo "$line" | awk '{print $3}')
    GRID_STEP=$(echo "$line" | awk '{print $4}')

    echo ">>> Preparing directory for mass ${MASS} and grid ${GRID_START}:${GRID_END}:${GRID_STEP}"

    WORKDIR="fullCLs_mass_${MASS}"
    mkdir -p ${WORKDIR}
    mv combined_run2_${MASS}.root ${WORKDIR}/
    cd ${WORKDIR}

    # Loop over batches of seeds
    for (( SEED_BATCH_START=${SEED_START}; SEED_BATCH_START<${SEED_END}; SEED_BATCH_START+=${BATCH_SIZE} )); do
        SEED_BATCH_END=$((SEED_BATCH_START + BATCH_SIZE - 1))
        BATCH_DIR="batch_${SEED_BATCH_START}_to_${SEED_BATCH_END}"
        mkdir -p ${BATCH_DIR}
        cd ${BATCH_DIR}

        for (( SEED=${SEED_BATCH_START}; SEED<=${SEED_BATCH_END} && SEED<${SEED_END}; SEED++ )); do
            echo ">>> Submitting seed ${SEED} for mass ${MASS}"

            combineTool.py -d ../combined_run2_${MASS}.root \
                -M HybridNew \
                --LHCmode LHC-limits \
                -n _obsAsimov_s${SEED} \
                --clsAcc 0 \
                -T 200 \
                -s ${SEED} \
                --singlePoint ${GRID_START}:${GRID_END}:${GRID_STEP} \
                --saveHybridResult \
                -m 125 \
                --job-mode condor \
                --task-name condor-m${MASS}_s${SEED} \
                --sub-opts=$'+JobFlavour = "tomorrow"\nlog = /dev/null\noutput = /dev/null\nerror = /dev/null' \ 
                --rMax=1000 \
                --rMin=-1000 \
                --fullBToys
        done

        cd ..
    done

    cd ..
done < "$CONFIG_FILE"
