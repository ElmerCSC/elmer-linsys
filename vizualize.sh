# DEFINE PATHS

RAW_RESULTS_PATH=results_2026/roihu/EndWindings-08-17/results_cpu_08_17
RESULTS_PATH=results_2026/roihu/EndWindings-08-17/results_cpu_08_17
# RAW_RESULTS_PATH=results_2026/roihu/EndWindings-CPU/results_cpu
# RESULTS_PATH=EndWindings-CPU



ORG_DIR=$PWD

source $ORG_DIR/.venv/bin/activate
# CASE_PATH=Navier/WinkelStructured
# CASE_PATH=Poisson/WinkelUnstructured
SCRIPT_PATH=python-scripts
# PROBLEM=Navier

#number of partitions used in the gpu run
PARTITIONS=4
RESULTS_PATH=results_2026/roihu/EndWindings-08-17/results_cpu_08_17/partitions-$PARTITIONS

FORMAT=png
MESH_LEVELS=(1)
# Define the name and location where the scalability plot should be saved
SCALE_NAME=scalability_test
# SCALE_PATH=$PWD/results/roihu/Navier-AMGX-WinkelStructured-partitions-$PARTITIONS-density-015
# SCALE_PATH=$ORG_DIR/results_2026/roihu/$RESULTS_PATH/Navier-WinkelStructured-partitions-$PARTITIONS
SCALE_PATH=$ORG_DIR/$RESULTS_PATH

# Define the name and location where the timing plots should be saved
# (these will be incremented with the mesh level)
TIME_NAME=timing_test
TIME_PATH=$SCALE_PATH

# USER CAN IF WANTED CHANGE FOLLOWING CONSTANTS:

# Define the path where resulting .dat files are stored (no need to change)
# RET_PATH=$PWD/$CASE_PATH/results_amgx_density_015
RET_PATH=$ORG_DIR/$RAW_RESULTS_PATH


# Define the resulting .dat file (no need to change)
RET_FILE=f$PARTITIONS.dat

# Define the used tolerance (no need to change)
TOL=0.000001

# Define if the total times should be plotted as well (no need to change)
VIZ_TOT_TIME=false

# Remove the result files if they already exist
# rm -f $CASE_PATH/results/f$PARTITIONS.*




# VISUALIZE THE RESULTS

mkdir -p $SCALE_PATH
mkdir -p $TIME_PATH

cd $SCRIPT_PATH

echo "Plotting scalability..."
echo

save_as=$SCALE_PATH/$SCALE_NAME.$FORMAT

# python3 plot_scalability_bar.py -p $RET_PATH -f $RET_FILE -s $save_as -t $TOL

cd $ORG_DIR

echo "Plotting timings..."
echo

cd $SCRIPT_PATH
# Copy the result files for easier access.
# cp $RET_PATH/$RET_FILE $SCALE_PATH/
# cp $RET_PATH/$RET_FILE.marker $SCALE_PATH/
# cp $RET_PATH/$RET_FILE.names $SCALE_PATH/

# # Copy the slurm log files (paths follow the --output/--error patterns above)
# cp $ORG_DIR/logs/${SLURM_JOB_NAME}_${SLURM_JOB_ID}.out $SCALE_PATH/
# cp $ORG_DIR/logs/${SLURM_JOB_NAME}_${SLURM_JOB_ID}.err $SCALE_PATH/

# Discover which OMP thread counts are actually present in RET_FILE's
# "expression 2" column (written by case_gpu.sif). Older result files
# without that column yield an empty list, and the loop below then just
# plots without filtering on thread count.
# THREADS_LIST=$(python3 - <<PYEOF
# import pandas as pd
# from tools.tools import read_names

# dat_file = "$RET_PATH/$RET_FILE"
# cols = read_names(dat_file)
# matches = [c for c in cols if "expression 2" in c]
# if matches:
#     idx = cols.index(matches[0])
#     data = pd.read_table(dat_file, sep=r"\s+", header=None)
#     print(" ".join(str(int(v)) for v in sorted(data[idx].unique())))
# PYEOF
# )

for partitions in "${PARTITIONS[@]}"; do
    for mesh_level in "${MESH_LEVELS[@]}"; do

        # for threads in ${THREADS_LIST:-_all_}; do

            echo "-----------------------------------"

            if [ "$threads" = "_all_" ]; then
                echo "Plotting timings with mesh level $mesh_level"
                th_arg=""
                save_as=$TIME_PATH/$TIME_NAME-$mesh_level.$FORMAT
            else
                echo "Plotting timings with mesh level $mesh_level, $threads threads"
                th_arg="-th $threads"
                save_as=$TIME_PATH/$TIME_NAME-$mesh_level-t$threads.$FORMAT
            fi
            echo

            if $VIZ_TOT_TIME; then
                python3 plot_times.py -p $RET_PATH -f $RET_FILE -s $save_as -t $TOL -m $mesh_level
            else
                python3 plot_times.py -p $RET_PATH -f $RET_FILE -s $save_as -t $TOL -m $mesh_level
            fi

            echo "------------------------------------"
            echo

        # done

    done
done

cd $ORG_DIR

echo "DONE"
