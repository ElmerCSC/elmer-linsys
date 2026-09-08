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
RESULTS_DIR=results_cpu_08_17


# Tracks whether any solver in the sweep crashed or failed to converge/match
# the reference solution, so the job's own exit code (checked below) reflects
# that instead of always reporting COMPLETED just because the script itself
# ran to the end.
overall_status=0


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

	    cp $solver $path/$LINSYS_FILE
        sed "s/include linsys\.sif/include $LINSYS_FILE/" "$path/$sif_basename" > $path/$CASE_FILE
        sed -i "s/Results Directory \".*\"/Results Directory \"$RESULTS_DIR\"/" $path/$CASE_FILE

	    # Hypre solves don't raise an ERROR on hitting the iteration cap (Elmer's own
	    # iterative solvers do, checked below) -- they just report how many iterations
	    # they took, so we need the configured cap to tell "converged" from "gave up".
	    max_iters=$(grep -m1 -oP 'Linear System Max Iterations\s*=\s*\K[0-9]+' "$solver" || true)

            cd $path

            start=$(date +%s)

            echo
            echo
            echo "-----------------------------------"
            echo "Starting $solver with mesh level $mesh_level"
            echo


            # `set -e` would otherwise kill the whole sweep (and every solver
            # still queued after this one) the moment ElmerSolver aborts on a
            # non-converged solve -- wrapping the call in `if ! ...` lets that
            # single failure be logged and the loop move on to the next solver.
            if ! srun --cpus-per-task=$threads ElmerSolver $CASE_FILE -ipar 2 $mesh_level $partitions
            then
                echo "SOLVER CRASHED: $solver (mesh level $mesh_level, $partitions partitions) -- ElmerSolver exited non-zero, moving on to next solver" >&2
                overall_status=1
            fi


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
                        echo "CONVERGENCE FAILURE: $solver (mesh level $mesh_level, $partitions partitions) -- Elmer's iterative solver reported 'Too many iterations were needed' on $iter_errors rank(s)" >&2
                        overall_status=1
                    fi
                    if [ -n "$hypre_iters" ] && [ -n "$max_iters" ] && [ "$hypre_iters" -ge "$max_iters" ]; then
                        echo "CONVERGENCE FAILURE: $solver (mesh level $mesh_level, $partitions partitions) -- Hypre required $hypre_iters/$max_iters iterations without converging" >&2
                        overall_status=1
                    fi

                    # With `Skip Compute Steady State Change` set on Solver 2, the reference-norm
                    # check ElmerSolver runs at the end of each solve is now comparing the actual
                    # magnetic norm, not the raw (gauge-noisy) AV-vector norm -- so its own FAILED
                    # verdict is trustworthy and worth failing the job on.
                    ref_failures=$(tail -n +"$start_line" "$job_log" | grep -c -F "WARNING:: CompareToReferenceSolution: Solver 2 FAILED" || true)
                    if [ "${ref_failures:-0}" -gt 0 ]; then
                        echo "REFERENCE NORM FAILURE: $solver (mesh level $mesh_level, $partitions partitions) -- Solver 2 did not match its magnetic-norm reference" >&2
                        overall_status=1
                    fi
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
    rm -rf $path/$LINSYS_FILE $path/$CONFIG_FILE $path/$CASE_FILE
done

if [ "$overall_status" -ne 0 ]; then
    echo "One or more solvers crashed or failed to converge/match the reference solution -- see CRASHED/FAILURE lines above" >&2
fi
exit $overall_status


