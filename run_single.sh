#!/bin/bash/

# Define the path to the case folder
path=Poisson/WinkelStructured

# Define the problem type
problem=Poisson

# Define the number of partitions (should be np)
partitions=4

# Define here the solver to be used
solver=linsys/direct_MUMPS.sif
# linMarker=??????

if ! grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
then   
    echo
    echo "Solver $solver not recommended for given problem. Exiting"
    echo
    return
fi


# Remove the result files if they already exist
# rm -f $path/results/f$linMarker.*

# Copy the valid case into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
cp $path/case_single.sif $path/case.sif

cp $solver $path/linsys.sif
cd $path

for mesh_level in 2; do
	
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
   
done

cd ../..
