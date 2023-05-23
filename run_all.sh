#!/bin/bash

# Define the path to the case folder
path=Poisson/WinkelStructured

# Define the problem type
problem=Poisson

# Define the number of partitions (should be np)
partitions=4

# Remove the result files if they already exist
# rm -f $path/results/f.*

# Copy the valid case file into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
cp $path/case_all.sif $path/case.sif

for mesh_level in 1; do

    for solver in linsys/*.sif; do

	if grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
	then

	    cp $solver $path/linsys.sif
            cd $path

            echo 
            echo 
	    echo "-----------------------------------"
            echo "Starting $solver with mesh level $mesh_level"
            echo

            start=$(date +%s)
    
            mpirun -np 4 ElmerSolver case.sif -ipar 2 $mesh_level $partitions

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
