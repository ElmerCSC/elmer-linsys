#!/bin/bash 
#SBATCH --time=02:00:00
#SBATCH --job-name=run_all
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=medium
#SBATCH --account=project_2001628
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=64

export OMP_NUM_THREADS=1
module load elmer/latest

# Define the path to the case folder
path=Poisson/WinkelStructured

# Define the problem type
problem=Poisson

# Define the number of partitions (should be nodes * ntasks-per-node)
partitions=128

# Uncomment this if you don't want to append to existing results
# rm -f $path/results/f.*

# Copy the valid case file into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
cp $path/case_all.sif $path/case.sif

for mesh_level in 3 4 5; do

    for solver in linsys/*.sif; do

	if grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
	then

            cp $solver $path/linsys.sif
            cd $path

            start=$(date +%s)

            echo
            echo
            echo "-----------------------------------"
            echo "Starting $solver with mesh level $mesh_level"
            echo
    
            srun ElmerSolver case.sif -ipar 2 $mesh_level $partitions

            end=$(date +%s)

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

done
