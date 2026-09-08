#!/bin/bash
# Compares CPU (cg + ilu0) vs GPU (AMGX) linsys cpu time scaling on Roihu
# for the Navier-WinkelStructured mesh-3-density-015 case.

# DEFINE PATHS

ORG_DIR=$PWD

source $ORG_DIR/.venv/bin/activate

SCRIPT_PATH=python-scripts

CPU_PATH=$ORG_DIR/results_2026/roihu/Navier-CPU/mesh-3-density-015
GPU_PATH=$ORG_DIR/results_2026/roihu/Navier-AMGX/mesh-3-density-015

# Partition counts to compare, each corresponding to a Navier-WinkelStructured-partitions-<n> dir
CPU_PARTITIONS=(1536 2304 3072 6144)
GPU_PARTITIONS=(12 16 24 32)

# Number of GPU nodes each entry in GPU_PARTITIONS above corresponds to (used for the GPU x-axis/label)
GPU_NODES=(3 4 6 8)

# Which solver's rows to use from the CPU files (they may contain more than one solver)
CPU_SOLVER="cg + ilu0"

FORMAT=png

# Define the name and location where the comparison plot should be saved
SAVE_NAME=roihu_cpu_gpu_comparison
SAVE_PATH=$ORG_DIR/results_2026/roihu_cpu_vs_gpu

# Define the used tolerance (no need to change)
TOL=0.000001

mkdir -p $SAVE_PATH

cd $SCRIPT_PATH

echo "Comparing Roihu CPU vs GPU linsys cpu time..."
echo

save_as=$SAVE_PATH/$SAVE_NAME.$FORMAT

python3 compare_roihu_cpu_gpu_times.py -cp $CPU_PATH -gp $GPU_PATH \
    -cparts "${CPU_PARTITIONS[@]}" -gparts "${GPU_PARTITIONS[@]}" -gnodes "${GPU_NODES[@]}" \
    -cs "$CPU_SOLVER" -t $TOL -s $save_as

cd $ORG_DIR

echo "DONE"
