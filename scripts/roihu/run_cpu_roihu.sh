#!/bin/bash 
#SBATCH --time=00:30:00
#SBATCH --job-name=cpu_ew_mesh_2
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=medium
#SBATCH --account=project_2001659
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=1
#SBATCH --mem=0

set -euo pipefail

module load elmerfem

#More threads don't really increase performance
export OMP_NUM_THREADS=1


# Define the path to the case folder
path=Magnetostatics/EndWindings

# Define the problem type
problem=EndWindingsCPU

# Define the number of partitions (should be nodes * ntasks-per-node)
partitions=$SLURM_NTASKS
threads=$SLURM_CPUS_PER_TASK

sif_basename=hierarc.sif
RESULTS_DIR=results_cpu



# Job-specific filenames so a concurrently-running job that shares this same
# case directory (e.g. the CPU sweep) can't clobber this job's linsys.sif /
# config.json / case file while both are in flight.
ORG_DIR=$PWD
JOB_TAG=${SLURM_JOB_ID:-$$}
LINSYS_FILE=linsys_$JOB_TAG.sif
CONFIG_FILE=config_$JOB_TAG.json
CASE_FILE=case_cpu_$JOB_TAG.sif




cd $path

ElmerGrid 2 2 ./mesh -partdual -metiskway $partitions

cd ../..

for mesh_level in 2; do
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
        echo "Starting $solver with mesh level $mesh_level"

        srun --cpus-per-task=$threads ElmerSolver $CASE_FILE -ipar 2 $mesh_level $partitions

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
    rm -rf $path/$LINSYS_FILE $path/$CONFIG_FILE $path/$CASE_FILE
done
