#!/bin/bash
#SBATCH --job-name=amgx_ew_mesh_3
#SBATCH --account=project_2001659
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=gpumedium
#SBATCH --nodes=1
#SBATCH --time=00:45:00
#SBATCH --ntasks-per-node=1 --cpus-per-task=1 # The product should be 72 if requesting 1 GPU per node
#SBATCH --gres=gpu:gh200:1
#SBATCH --mem=0


set -euo pipefail

#More threads don't really increase performance
export OMP_NUM_THREADS=1


# Define the path to the case folder
path=Magnetostatics/EndWindings

# Define the problem type
problem=EndWindings

# Define the number of partitions (should be nodes * ntasks-per-node)
partitions=$SLURM_NTASKS
threads=$SLURM_CPUS_PER_TASK

sif_basename=hierarc.sif
RESULTS_DIR=results_amgx_08_17


# container_path=/scratch/project_2001659/danieree/elmer-linsys/containers/container.sif
container_path=/scratch/project_2001659/danieree/elmer-linsys/containers/container_hypre_cuda.sif

# Job-specific filenames so a concurrently-running job that shares this same
# case directory (e.g. the CPU sweep) can't clobber this job's linsys.sif /
# config.json / case file while both are in flight.
ORG_DIR=$PWD
JOB_TAG=${SLURM_JOB_ID:-$$}
LINSYS_FILE=linsys_$JOB_TAG.sif
CONFIG_FILE=config_$JOB_TAG.json
CASE_FILE=case_gpu_$JOB_TAG.sif

# Anchored to $ORG_DIR (not a relative $path) since a mid-loop srun failure
# under `set -e` exits before the trailing `cd ../..` restores the cwd.

# Background host RAM + per-GPU memory poller, sampled every 2s for the
# whole job so usage around a crash can be checked after the fact.
# MEM_LOG="$ORG_DIR/logs/mem_poll_$JOB_TAG.csv"
# mkdir -p "$ORG_DIR/logs"
# {
#     echo "timestamp,host_used_MB,host_total_MB,gpu_index,gpu_used_MB,gpu_total_MB"
#     while true; do
#         ts=$(date +%s)
#         read -r used total < <(free -m | awk '/Mem:/{print $3, $2}')
#         nvidia-smi --query-gpu=index,memory.used,memory.total --format=csv,noheader,nounits \
#             | while IFS=', ' read -r idx gused gtotal; do
#                 echo "$ts,$used,$total,$idx,$gused,$gtotal"
#               done
#         sleep 2
#     done
# } > "$MEM_LOG" &
# MONITOR_PID=$!
# trap 'kill $MONITOR_PID 2>/dev/null; rm -f "$ORG_DIR/$path/$LINSYS_FILE" "$ORG_DIR/$path/$CONFIG_FILE" "$ORG_DIR/$path/$CASE_FILE"' EXIT

# Remove the result files if they already exist
# rm -f $path/results_amgx/f$result_file.*

# Copy the valid case file into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
# cp $path/case_amgx.sif $path/case.sif

cd $path
# Commands for Poisson/WinkelUnstructured mesh
# srun apptainer run --bind="$(csc-common-bind)" $container_path gmsh winkel.geo -3 -clscale 1.0 -v 5
# srun apptainer run --bind="$(csc-common-bind)" $container_path ElmerGrid 14 2 winkel.msh -autoclean -partdual -metiskway $partitions


# -n1: ElmerGrid itself isn't MPI-parallel, so without this srun launches one
# redundant copy per task (4-8x concurrent writers into the same
# winkel/partitioning.$partitions/ directory).
srun -n1 apptainer run --bind="$(csc-common-bind)" $container_path ElmerGrid 2 2 ./mesh -partdual -metiskway $partitions

cd ../..

for mesh_level in 2; do
    for solver in linsysAMGX/*.sif; do
	if grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
	then

        cp $solver $path/$LINSYS_FILE
	    # Assumes that the config file is named similarly to .sif file
	    filename=$(basename "$solver" ".sif")
	    cp linsysAMGX/$filename.json $path/$CONFIG_FILE
	    sed -i "s/config\.json/$CONFIG_FILE/" $path/$LINSYS_FILE
        sed "s/include linsys\.sif/include $LINSYS_FILE/" "$path/$sif_basename" > $path/$CASE_FILE
        sed -i "s/Results Directory \".*\"/Results Directory \"$RESULTS_DIR\"/" $path/$CASE_FILE

	    # AMGX's own configured iteration budget/tolerance for this solver, used below to
	    # detect a solve that silently hit max_iters without actually converging.
	    max_iters=$(grep -m1 -oP '"max_iters":\s*\K[0-9]+' linsysAMGX/$filename.json)
	    tolerance=$(grep -m1 -oP '"tolerance":\s*\K[0-9.eE+-]+' linsysAMGX/$filename.json)

            cd $path

            start=$(date +%s)

            echo
            echo
            echo "-----------------------------------"
            echo "Starting $solver with mesh level $mesh_level"
            echo

            # echo "Diagnostic: UCX_RNDV_THRESH as seen inside the container:"
            # srun apptainer exec --nv --bind="$(csc-common-bind)" $container_path env | grep UCX_RNDV_THRESH || echo "  (not set inside container)"

            # echo "Diagnostic: ulimits on the host (compute node, outside container):"
            # ulimit -a

            # echo "Diagnostic: ulimits as seen inside the container (per task):"
            # srun apptainer exec --nv --bind="$(csc-common-bind)" $container_path bash -c 'ulimit -a'

            srun --cpus-per-task=$threads apptainer run --nv --bind="$(csc-common-bind)" $container_path ElmerSolver $CASE_FILE -ipar 2 $mesh_level $partitions


            end=$(date +%s)

            # AMGX prints "Total Iterations: N" / "Total Reduction in Residual: R" per solve.
            # If it hit max_iters, the solve never actually converged even though ElmerSolver
            # itself exits normally -- flag it here (into stderr, i.e. the job's .err file) so
            # it's visible immediately instead of buried in thousands of lines of per-iteration
            # residual output. Reads from this job's own SLURM stdout log (already being written
            # by the --output=%x_%j.out redirection) rather than capturing a separate copy; `tac`
            # picks the most recent match since the file accumulates one block per solver/mesh
            # level looped over in this job.
            job_log=$ORG_DIR/${SLURM_JOB_NAME:-amgx_all}_${SLURM_JOB_ID}.out
            if [ -f "$job_log" ]; then
                iters=$(tac "$job_log" | grep -m1 -oP 'Total Iterations:\s*\K[0-9]+' || true)
                reduction=$(tac "$job_log" | grep -m1 -oP 'Total Reduction in Residual:\s*\K[0-9.eE+-]+' || true)
                if [ -n "$iters" ] && [ "$iters" -ge "$max_iters" ]; then
                    echo "CONVERGENCE FAILURE: $solver (mesh level $mesh_level, $partitions partitions) hit max_iters=$max_iters without converging -- residual only reduced to ${reduction:-unknown} (tolerance $tolerance)" >&2
                fi
            fi

            echo
            echo "Ending $solver with mesh level $mesh_level"
            echo "Elapsed time: $(($end-$start)) s"
            echo "-----------------------------------"
            echo

	    cd ../..

	else
	    echo
	    echo "Solver $solver not recommended for given problem. Ignoring it"
	    echo
	fi
    
   done

   echo "Finished all solvers for mesh level $mesh_level"

done


