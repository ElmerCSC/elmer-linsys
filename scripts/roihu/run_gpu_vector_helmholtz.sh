#!/bin/bash
#SBATCH --job-name=gpu_helmholtz_direct
#SBATCH --account=project_2001659
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=gputest
#SBATCH --nodes=1
#SBATCH --time=00:15:00
#SBATCH --ntasks-per-node=1 --cpus-per-task=72 # The product should be 72 if requesting 1 GPU per node
#SBATCH --gres=gpu:gh200:1

set -euo pipefail


# More threads don't really increase performance
export OMP_NUM_THREADS=72

# Define the path to the case folder
path=VectorHelmholtz/BandpassFilterTets-gpu

# Define the problem type
problem=DirectGPU

# Define the number of partitions (should be nodes * ntasks-per-node)
partitions=$SLURM_NTASKS
threads=$SLURM_CPUS_PER_TASK

RESULTS_DIR=results



# Job-specific filenames so a concurrently-running job that shares this same
# case directory (e.g. the CPU sweep) can't clobber this job's linsys.sif /
# config.json / case file while both are in flight.
sif_basename=Filter_Zhai.sif

container_path=/scratch/project_2001659/danieree/Elmer-gpu-containers/container_cudss_mumps_test.sif



# Remove the result files if they already exist
# rm -f $path/results_amgx/f$result_file.*

# Copy the valid case file into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
# cp $path/case_amgx.sif $path/case.sif

# Job-specific filenames so a concurrently-running job that shares this same
# case directory (e.g. the CPU sweep) can't clobber this job's linsys.sif /
# config.json / case file while both are in flight.
ORG_DIR=$PWD
JOB_TAG=${SLURM_JOB_ID:-$$}
LINSYS_FILE=linsys_$JOB_TAG.sif
CONFIG_FILE=config_$JOB_TAG.json
CASE_FILE=case_$JOB_TAG.sif


cd $path

apptainer run --bind="$(csc-common-bind)" "$container_path" elmerf90 -o EMParam_WR28.so EMParam_WR28.F90

# -n1: ElmerGrid itself isn't MPI-parallel
# ElmerGrid 1 2 winkel.grd -partdual -metiskway $partitions
apptainer run --bind="$(csc-common-bind)" "$container_path" ElmerGrid 2 2 Hl_Filter_Zhai_a08 -partdual -metiskway $partitions

cd ../..


    for solver in linsys/*.sif; do
	if grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
	then
        # modify the linsysand case files to be job-specific
	    cp $solver $path/$LINSYS_FILE
        sed "s/include linsys\.sif/include $LINSYS_FILE/" "$path/$sif_basename" > $path/$CASE_FILE
        sed -i "s/Results Directory \".*\"/Results Directory \"$RESULTS_DIR\"/" $path/$CASE_FILE

        cd $path

        start=$(date +%s)

        echo "-----------------------------------"
        echo "Starting $solver with mesh level"
        echo

        srun --cpus-per-task=$threads apptainer run --nv --bind="$(csc-common-bind)" $container_path ElmerSolver $CASE_FILE

        end=$(date +%s)

        echo "Elapsed time: $(($end-$start)) s"
        echo "-----------------------------------"

        cd ../..
	else
	    echo
	    echo "Solver $solver not recommended for given problem. Ignoring it"
	    echo
	fi
    
    done
    

   echo "Finished all solvers"



