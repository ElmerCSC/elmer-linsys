#!/bin/bash
#SBATCH --job-name=hypre_cuda_endwindings_gpu_4_ML3
#SBATCH --account=project_2001659
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=gpumedium
#SBATCH --nodes=1
#SBATCH --time=00:45:00
#SBATCH --ntasks-per-node=4 --cpus-per-task=72 # The product should be 72 if requesting 1 GPU per node
#SBATCH --gres=gpu:gh200:4
#SBATCH --mem=0

set -euo pipefail

export OMP_NUM_THREADS=72

# Define the path to the case folder
path=Magnetostatics/EndWindings

# Define the problem type
problem=EndWindingsHypre

# Define the number of partitions (should be nodes * ntasks-per-node)
partitions=$SLURM_NTASKS
threads=$SLURM_CPUS_PER_TASK

# in the sif, we change the results directory depending on if the run is gpu, cpu or amgx.
sif_basename=hierarc.sif
RESULTS_DIR=results_compare_hypre

container_path=/scratch/project_2001659/danieree/elmer-linsys/containers/container.sif


# Job-specific filenames so a concurrently-running job that shares this same
# case directory (e.g. the CPU sweep) can't clobber this job's linsys.sif /
# config.json / case file while both are in flight.
ORG_DIR=$PWD
JOB_TAG=${SLURM_JOB_ID:-$$}
LINSYS_FILE=linsys_$JOB_TAG.sif
CONFIG_FILE=config_$JOB_TAG.json
CASE_FILE=case_gpu_$JOB_TAG.sif


# Copy the valid case file into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
# cp $path/case_amgx.sif $path/case.sif


cd $path

srun -n1 apptainer run --bind="$(csc-common-bind)" $container_path ElmerGrid 2 2 ./mesh -partdual -metiskway $partitions

cd ../..

for mesh_level in 3; do
    for solver in linsys/*.sif; do
	if grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
	then
        # modify the linsysand case files to be job-specific
        cp $solver $path/$LINSYS_FILE
        sed "s/include linsys\.sif/include $LINSYS_FILE/" "$path/$sif_basename" > $path/$CASE_FILE
        # Change the results directory (no need to have seperate sifs for gpu and cpu runs)
        sed -i "s/Results Directory \".*\"/Results Directory \"$RESULTS_DIR\"/" $path/$CASE_FILE

        cd $path

        start=$(date +%s)

        echo "-----------------------------------"
        echo "Starting $solver with mesh level $mesh_level"

        srun --cpus-per-task=$threads apptainer run --nv --bind="$(csc-common-bind)" $container_path ElmerSolver $CASE_FILE -ipar 2 $mesh_level $partitions

        end=$(date +%s)

        echo "Ending $solver with mesh level $mesh_level"
        echo "Elapsed time: $(($end-$start)) s"
        echo "-----------------------------------"
	    cd ../..

	else
	    echo
	    echo "Solver $solver not recommended for given problem. Ignoring it"
	    echo
	fi
    
   done

   echo "Finished all solvers for mesh level $mesh_level"

done


