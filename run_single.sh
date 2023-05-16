#!/bin/bash/

# Define the path to the case folder
path=Poisson/WinkelStructured

# Define here the solver to be used
solver=linsys/elmer_iter_Gmres_ILU0.sif
# linMarker=??????

# Remove the result files if they already exist
# rm -f $path/results/f$linMarker.*

# Copy the valid case and solver file into the case folder
cp case_single.sif $path/case.sif
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
