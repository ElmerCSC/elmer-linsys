#!/bin/bash 
#SBATCH --time=01:00:00
#SBATCH --job-name=run_complete
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=small
#SBATCH --account=project_2001659
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=384

export OMP_NUM_THREADS=1


module load elmerfem
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
PROBLEM=Navier

# Define the mesh levels to loop over
MESH_LEVELS=(3)

# Define the format in which figures should be saved
FORMAT=png

# Define the number of partitions (no need to change)
PARTITIONS=$SLURM_NPROCS

# Define the name and location where the scalability plot should be saved
SCALE_NAME=scalability_test
SCALE_PATH=$PWD/results/roihu/Navier-WinkelStructured-$PARTITIONS

# Define the name and location where the timing plots should be saved
# (these will be incremented with the mesh level)
TIME_NAME=timing_test
TIME_PATH=$SCALE_PATH


# USER CAN IF WANTED CHANGE FOLLOWING CONSTANTS:

echo "Number of partitions: $PARTITIONS"
# Define the path where resulting .dat files are stored (no need to change)
RET_PATH=$PWD/$CASE_PATH/results

# Define the resulting .dat file (no need to change)
RET_FILE=f$PARTITIONS.dat

# Define the used tolerance (no need to change)
TOL=0.000001

# Define if the total times should be plotted as well (no need to change)
VIZ_TOT_TIME=false

# Remove the result files if they already exist
# rm -f $CASE_PATH/results/f$PARTITIONS.*

# Copy the valid case file into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
# cp $CASE_PATH/case_all.sif $CASE_PATH/case.sif


ORG_DIR=$PWD

# Job-specific filenames so a concurrently-running jobs that share this same
# case directory (e.g. running a CPU and AMGX test case) don't cause a race condition
# in linsys.sif / case.sif / config.json
JOB_TAG=${SLURM_JOB_ID:-$$}
LINSYS_FILE=linsys_$JOB_TAG.sif
CASE_FILE=case_cpu_$JOB_TAG.sif

trap 'rm -f "$CASE_PATH/$LINSYS_FILE" "$CASE_PATH/$CASE_FILE"' EXIT


###################### RUN THE SCRIPTS #######################

# CHECK FOR PARTITIONINGS AND AS REQUIRED PARTITION THE MESH TO NEEDED AMOUNT

cd $CASE_PATH


ElmerGrid 1 2 winkel.grd -partdual -metiskway $PARTITIONS


cd $ORG_DIR


# RUN THE ELMERSOLVER

echo "Running ElmerSolver..."

for mesh_level in "${MESH_LEVELS[@]}"; do

    for solver in linsys/*.sif; do

	if grep -Fxq "$solver" solver-lists/$PROBLEM-Solvers.txt
	then

	    cp $solver $CASE_PATH/$LINSYS_FILE
	    sed "s/include linsys\.sif/include $LINSYS_FILE/" $CASE_PATH/case_cpu.sif > $CASE_PATH/$CASE_FILE


        cd $CASE_PATH

        echo
        echo
	    echo "-----------------------------------"
        echo "Starting $solver with mesh level $mesh_level"
        echo

        start=$(date +%s)

        srun ElmerSolver $CASE_FILE -ipar 2 $mesh_level $PARTITIONS
        status=$?

        end=$(date +%s)

	    if [ $status -ne 0 ]; then
		echo "FAILED $solver with mesh level $mesh_level (srun exit code $status)"
	    else
		echo "Ending $solver with mesh level $mesh_level"
	    fi
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
cp $RET_PATH/$RET_FILE $SCALE_PATH/
cp $RET_PATH/$RET_FILE.marker $SCALE_PATH/
cp $RET_PATH/$RET_FILE.names $SCALE_PATH/

# Copy the slurm log files (paths follow the --output/--error patterns above)
cp $ORG_DIR/logs/${SLURM_JOB_NAME}_${SLURM_JOB_ID}.out $SCALE_PATH/
cp $ORG_DIR/logs/${SLURM_JOB_NAME}_${SLURM_JOB_ID}.err $SCALE_PATH/

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
