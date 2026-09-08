#!/bin/bash 
#SBATCH --time=01:00:00
#SBATCH --job-name=run_complete
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=large
#SBATCH --account=project_2001659
#SBATCH --nodes=6
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
PROBLEM=Navier-roihu

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
# If changed, also change the path in plot_times.py and plot_scalability_bar.py and also the corresponding sif and scale path
RET_PATH=$PWD/$CASE_PATH/results_amgx_density_015

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

# Job-specific filenames so a concurrently-running job that shares this same
# case directory (e.g. the AMGX sweep) can't clobber this job's linsys.sif /
# case file while both are in flight.
JOB_TAG=${SLURM_JOB_ID:-$$}
LINSYS_FILE=linsys_$JOB_TAG.sif
CASE_FILE=case_cpu_$JOB_TAG.sif

trap 'rm -f "$CASE_PATH/$LINSYS_FILE" "$CASE_PATH/$CASE_FILE"' EXIT


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

	    cp $solver $CASE_PATH/$LINSYS_FILE
	    sed "s/include linsys\.sif/include $LINSYS_FILE/" $CASE_PATH/case_cpu.sif > $CASE_PATH/$CASE_FILE

	    # Hypre solves don't raise an ERROR on hitting the iteration cap (Elmer's own
	    # iterative solvers do, checked below) -- they just report how many iterations
	    # they took, so we need the configured cap to tell "converged" from "gave up".
	    max_iters=$(grep -m1 -oP 'Linear System Max Iterations\s*=\s*\K[0-9]+' "$solver" || true)

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

            # Check this solver's own slice of the job's SLURM stdout log (already being
            # written by the --output=logs/%x_%j.out redirection) for a convergence failure:
            # - Elmer's native iterative solvers print an explicit "Too many iterations were
            #   needed" ERROR (one line per rank) when they hit Linear System Max Iterations.
            # - Hypre doesn't raise an ERROR at all -- it just reports "Required iterations N"
            #   -- so N has to be compared against the configured max_iters by hand.
            # Scoped to the lines since this solver's own "Starting ..." marker so an earlier
            # solver's failure in the same job log isn't misattributed to this one.
            job_log=$ORG_DIR/logs/${SLURM_JOB_NAME:-run_complete}_${SLURM_JOB_ID}.out
            if [ -f "$job_log" ]; then
                start_line=$(grep -n -F "Starting $solver with mesh level $mesh_level" "$job_log" | tail -1 | cut -d: -f1)
                if [ -n "$start_line" ]; then
                    iter_errors=$(tail -n +"$start_line" "$job_log" | grep -c -F "ERROR:: IterSolve: Numerical Error: Too many iterations were needed." || true)
                    hypre_iters=$(tail -n +"$start_line" "$job_log" | grep -m1 -oP 'SolveHypre: Required iterations \K[0-9]+' || true)
                    if [ "${iter_errors:-0}" -gt 0 ]; then
                        echo "CONVERGENCE FAILURE: $solver (mesh level $mesh_level, $PARTITIONS partitions) -- Elmer's iterative solver reported 'Too many iterations were needed' on $iter_errors rank(s)" >&2
                    fi
                    if [ -n "$hypre_iters" ] && [ -n "$max_iters" ] && [ "$hypre_iters" -ge "$max_iters" ]; then
                        echo "CONVERGENCE FAILURE: $solver (mesh level $mesh_level, $PARTITIONS partitions) -- Hypre required $hypre_iters/$max_iters iterations without converging" >&2
                    fi
                fi
            fi

   	    echo
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
