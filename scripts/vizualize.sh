# SCRIPT FOR VISUALIZING RESULTS
# USED WHEN RUNNING LOCALLY
# THE USER SHOULD DEFINE THE PATHS FOR RESULTS AND VENV,
# NUMBER OF PARTITIONS, MESH LEVELS. OTHER PARAMS ARE OPTIONAL.

# DEFINE PATHS

# Results from roihu (.dat files)
RAW_RESULTS_PATH=results_2026/roihu/EndWindings-08-17/results_cpu_08_17

ORG_DIR=$PWD

source $ORG_DIR/.venv/bin/activate
SCRIPT_PATH=python-scripts

#number of partitions used in the run
PARTITIONS=4
# where to save the plots
RESULTS_PATH=results_2026/roihu/EndWindings-08-17/results_cpu_08_17/partitions-$PARTITIONS

FORMAT=png
MESH_LEVELS=(1)
# Define the name and location where the scalability plot should be saved
SCALE_NAME=scalability_test
SCALE_PATH=$ORG_DIR/$RESULTS_PATH

# Define the name and location where the timing plots should be saved
# (these will be incremented with the mesh level)
TIME_NAME=timing_test
TIME_PATH=$SCALE_PATH

# USER CAN IF WANTED CHANGE FOLLOWING CONSTANTS:
# Define the path where resulting .dat files are stored (no need to change)
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


for partitions in "${PARTITIONS[@]}"; do
    for mesh_level in "${MESH_LEVELS[@]}"; do

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

    done
done

cd $ORG_DIR

echo "DONE"
