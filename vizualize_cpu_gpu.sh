# DEFINE PATHS

RESULTS_ROOT=results_2026/roihu/EndWindings-08-19

# Directory holding the CPU f<n>.dat/.marker/.names files (one file per partition count).
# Add more f<n>.dat files here and the plot picks them up automatically -- no script changes needed.
CPU_DIR=$RESULTS_ROOT/results_cpu_08_17

# Directories/files holding the single-GPU reference runs
GPU_AMGX_DIR=$RESULTS_ROOT/results_amgx_08_17
GPU_AMGX_FILE=f1.dat

GPU_HYPRE_CUDA_DIR=$RESULTS_ROOT/results_hypre_cuda_08_17
GPU_HYPRE_CUDA_FILE=f1.dat

ORG_DIR=$PWD

source $ORG_DIR/.venv/bin/activate

SCRIPT_PATH=python-scripts

# Mesh level to plot (only this level is used from all input files)
MESH_LEVEL=2

FORMAT=png

# Define the name and location where the figure should be saved
PLOT_NAME=cpu_gpu_partitions
PLOT_PATH=$ORG_DIR/$RESULTS_ROOT

TEST_CASE=EndWindings

# USER CAN IF WANTED CHANGE FOLLOWING CONSTANTS:

# Define the used tolerance (no need to change)
TOL=0.000001

# Substrings identifying which solver rows to use (no need to change unless marker names change)
CPU_SOLVER_PCG="pcg + ams + smoother 0"
CPU_SOLVER_CG="cg + none"
GPU_AMGX_SOLVER="cg_none"
GPU_HYPRE_SOLVER="boomeramg + smoother 3"


# VISUALIZE THE RESULTS

mkdir -p $PLOT_PATH

cd $SCRIPT_PATH

echo "Plotting CPU vs GPU linsys cpu time (mesh level $MESH_LEVEL)..."
echo

save_as=$PLOT_PATH/$PLOT_NAME-$MESH_LEVEL.$FORMAT

python3 plot_cpu_gpu.py \
    -cp $ORG_DIR/$CPU_DIR \
    -gap $ORG_DIR/$GPU_AMGX_DIR -gaf $GPU_AMGX_FILE -gas "$GPU_AMGX_SOLVER" \
    -ghp $ORG_DIR/$GPU_HYPRE_CUDA_DIR -ghf $GPU_HYPRE_CUDA_FILE -ghs "$GPU_HYPRE_SOLVER" \
    -cs1 "$CPU_SOLVER_PCG" -cs2 "$CPU_SOLVER_CG" \
    -m $MESH_LEVEL -t $TOL -c "$TEST_CASE" \
    -s $save_as

cd $ORG_DIR

echo "DONE"
