#!/bin/bash

# Define the path to the case folder
path=Poisson/WinkelStructured

# Define the problem type
problem=Poisson

# Remove the result files if they already exist
rm -f $path/results/f.*

# Copy the valid case file into the case folder
cp case_all.sif $path/case.sif

for mesh_level in 2; do

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
    
            mpirun -np 4 ElmerSolver case.sif -ipar 1 $mesh_level

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
