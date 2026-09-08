#!/bin/bash
# Compares the linear solver's energy consumption (CPU cg+ilu0 vs GPU AMGX) on Roihu
# for the Navier-WinkelStructured mesh-3-density-015 case, assuming each node runs
# at its rated max power for the duration of the linsys real time.

# DEFINE PATHS

ORG_DIR=$PWD

source $ORG_DIR/.venv/bin/activate

SCRIPT_PATH=python-scripts

CPU_PATH=$ORG_DIR/results_2026/roihu/Navier-CPU/mesh-3-density-015
GPU_PATH=$ORG_DIR/results_2026/roihu/Navier-AMGX/mesh-3-density-015

# Partition counts to compare, each corresponding to a Navier-WinkelStructured-partitions-<n> dir
CPU_PARTITIONS=(1536 2304 3072 6144)
GPU_PARTITIONS=(12 16 24 32)

# Number of GPU nodes each entry in GPU_PARTITIONS above corresponds to
GPU_NODES=(3 4 6 8)

# CPU cores per node, used to convert CPU_PARTITIONS into node counts
CPU_CORES_PER_NODE=384

# Assumed max power draw per node, in watts (2x AMD EPYC 9965 @ 500W, 4x NVIDIA GH200 @ ~1000W)
CPU_NODE_POWER=1000
GPU_NODE_POWER=4000

# Which solver's rows to use from the CPU files (they may contain more than one solver)
CPU_SOLVER="cg + ilu0"

FORMAT=png

# Define the name and location where the energy plot should be saved
SAVE_NAME=roihu_cpu_gpu_energy
SAVE_PATH=$ORG_DIR/results_2026/roihu_cpu_vs_gpu

# Define the used tolerance (no need to change)
TOL=0.000001

mkdir -p $SAVE_PATH

cd $SCRIPT_PATH

echo "Comparing Roihu CPU vs GPU linear solver energy..."
echo

save_as=$SAVE_PATH/$SAVE_NAME.$FORMAT

python3 compare_roihu_cpu_gpu_energy.py -cp $CPU_PATH -gp $GPU_PATH \
    -cparts "${CPU_PARTITIONS[@]}" -gparts "${GPU_PARTITIONS[@]}" -gnodes "${GPU_NODES[@]}" \
    -cnpn $CPU_CORES_PER_NODE -cpw $CPU_NODE_POWER -gpw $GPU_NODE_POWER \
    -cs "$CPU_SOLVER" -t $TOL -s $save_as

cd $ORG_DIR

echo "DONE"
