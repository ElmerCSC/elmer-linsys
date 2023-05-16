#!/bin/bash/

# Define the path to the case folder
path=Poisson/WinkelStructured

# Define the problem type
problem=Poisson

# Define here the solver to be used
solver=linsys/trilinos_ml_sgs.sif
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

# Copy the valid case and solver file into the case.sif file
cp $path/case_single.sif $path/case.sif
cp $solver $path/linsys.sif
cd $path

for mesh_level in 2 3 4; do
	
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
   
done

cd ../..
