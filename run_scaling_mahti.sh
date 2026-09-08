#!/bin/bash 
#SBATCH --time=01:00:00
#SBATCH --job-name=scaling_test
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=medium
#SBATCH --account=project_2001659
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128

export OMP_NUM_THREADS=1
module load elmer/latest
module load python-data



# THIS IS A FULLY AUTOMATED BASH SCRIPT FOR RUNNING
# A CASE WITH GIVEN SET OF SOLVERS AND MESH LEVELS
# AND VISUALIZING THE RESULTS.



# USER NEEDS TO FILL THE FOLLOWING CONSTANTS:


# Define the path to the case folder
CASE_PATH=Navier/WinkelStructured

# Define the path to the python scripts
SCRIPT_PATH=python-scripts

# Define the problem type
PROBLEM=Navier-short

# Define the mesh levels to loop over
MESH_LEVELS=(4)

# Define the format in which figures should be saved
FORMAT=png

# Define the number of partitions (no need to change)
PARTITIONS=$SLURM_NPROCS

# Define the name and location where the scalability plot should be saved
SCALE_NAME=scalability_test
SCALE_PATH=$PWD/results/mahti/Navier-WinkelStructured-$PARTITIONS

# Define the name and location where the timing plots should be saved
# (these will be incremented with the mesh level)
TIME_NAME=timing_test
TIME_PATH=$SCALE_PATH


# USER CAN IF WANTED CHANGE FOLLOWING CONSTANTS:

echo "Number of partitions: $PARTITIONS"
# Define the path where resulting .dat files are stored (no need to change)
# If changed, also change the path in plot_times.py and plot_scalability_bar.py and also the corresponding sif and scale path
RET_PATH=$PWD/$CASE_PATH/results_cpu

# Define the resulting .dat file (no need to change)
RET_FILE=f$PARTITIONS.dat

# Define the used tolerance (no need to change)
TOL=0.000001

# Define if the total times should be plotted as well (no need to change)
VIZ_TOT_TIME=false

# Remove the result files if they already exist
rm -f $CASE_PATH/results/f$PARTITIONS.*

# Copy the valid case file into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
# cp $CASE_PATH/case_all.sif $CASE_PATH/case.sif


ORG_DIR=$PWD


###################### RUN THE SCRIPTS #######################

# CHECK FOR PARTITIONINGS AND AS REQUIRED PARTITION THE MESH TO NEEDED AMOUNT

cd $CASE_PATH

# Find all folders with files of form mesh.*
MESH_DIRS=$(find . -type f -name "mesh.*" | sed -r 's|/[^/]+$||' |sort |uniq)

# for mesh_dir in "${MESH_DIRS[@]}"; do

    # Check if proper partitioning already exists
    # if [ -f "$mesh_dir/partitioning.$PARTITIONS" ]; then
	# continue
	
    # Otherwise call ElmerGrid
    # else
ElmerGrid 1 2 winkel.grd -partdual -metiskway $PARTITIONS
    # fi

# done

cd $ORG_DIR


# RUN THE ELMERSOLVER

echo "Running ElmerSolver..."

for mesh_level in "${MESH_LEVELS[@]}"; do

    for solver in linsys/*.sif; do

	if grep -Fxq "$solver" solver-lists/$PROBLEM-Solvers.txt
	then

	    cp $solver $CASE_PATH/linsys.sif
            cd $CASE_PATH

            echo 
            echo 
	    echo "-----------------------------------"
            echo "Starting $solver with mesh level $mesh_level"
            echo

            start=$(date +%s)
    
            srun ElmerSolver case_cpu.sif -ipar 2 $mesh_level $PARTITIONS

            end=$(date +%s)

   	    echo
            echo "Ending $solver with mesh level $mesh_level"
            echo "Elapsed time: $(($end-$start)) s"
            echo "-----------------------------------"
            echo

	    cd $ORG_DIR

	else
	    echo
	    echo "Solver $solver not recommended for given problem. Ignoring it"
	    echo
	fi

    done
    
done


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
# Do NOT copy if you set "Post File" in the sif (creates number of files equal to number of partitions)
cp -r $RET_PATH $SCALE_PATH/

for mesh_level in "${MESH_LEVELS[@]}"; do
    
    echo "-----------------------------------"
    echo "Plotting timings with mesh level $mesh_level"
    echo
    
    save_as=$TIME_PATH/$TIME_NAME-$mesh_level.$FORMAT

    if $VIZ_TOT_TIME; then
	python3 plot_times.py -p $RET_PATH -f $RET_FILE -s $save_as -t $TOL -m $mesh_level
    else
	python3 plot_times.py -p $RET_PATH -f $RET_FILE -s $save_as -t $TOL -m $mesh_level
    fi
    
    echo "-----------------------------------"
    echo

done

cd $ORG_DIR

echo "DONE"
