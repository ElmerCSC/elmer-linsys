#!/bin/bash
# Compares the linsys cpu time between Mahti and Roihu for the AMGX GPU-scaling runs
# (f1.dat = 1 GPU, f2.dat = 2 GPUs, f4.dat = 4 GPUs).

# DEFINE PATHS

ORG_DIR=$PWD

source $ORG_DIR/.venv/bin/activate

SCRIPT_PATH=python-scripts

MAHTI_PATH=$ORG_DIR/raw_results/mahti/results_amgx_compare
ROIHU_PATH=$ORG_DIR/raw_results/roihu/results_amgx_compare

# Number of GPUs to compare, each corresponding to a file f<n>.dat in the paths above
GPUS=(1 2 4)

FORMAT=png

# Define the name and location where the comparison plot should be saved
SAVE_NAME=roihu_mahti_comparison
SAVE_PATH=$ORG_DIR/results_2026/roihu_vs_mahti

# Define the used tolerance (no need to change)
TOL=0.000001

mkdir -p $SAVE_PATH

cd $SCRIPT_PATH

echo "Comparing Mahti vs Roihu linsys cpu time..."
echo

save_as=$SAVE_PATH/$SAVE_NAME.$FORMAT

python3 compare_roihu_mahti_times.py -mp $MAHTI_PATH -rp $ROIHU_PATH -g "${GPUS[@]}" -t $TOL -s $save_as

cd $ORG_DIR

echo "DONE"
