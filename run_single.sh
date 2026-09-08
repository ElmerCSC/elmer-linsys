#!/bin/bash

path=Magnetostatics/EndWindings


cd $path

ElmerGrid 2 2 ./mesh -partdual -metiskway 2
cd ../..


# Define the path to the case folder
# path=Navier/WinkelStructured

# Define the problem type
problem=Magnetostatics
# problem=Navier

# Define the number of partitions (should be np)
partitions=2

# Define here the solver to be used
# solver=linsys/direct_MUMPS.sif
# solver=linsys/elmer_iter_CG_none.sif
solver=linsys/elmer_iter_BiCGStab4_none.sif
# linMarker=??????

if ! grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
then   
    echo
    echo "Solver $solver not recommended for given problem. Exiting"
    echo
    exit 1
fi


# Remove the result files if they already exist
# rm -f $path/results/f$linMarker.*

# Copy the valid case into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
# cp $path/case_single.sif $path/case.sif

cp $solver $path/linsys.sif
cd $path


for mesh_level in 1; do
	
   echo 
   echo 
   echo "-----------------------------------"
   echo "Starting $solver with mesh level $mesh_level"
   echo
	
   start=$(date +%s)
   # mpirun -np 2 ElmerSolver hierarc.sif -ipar 2 $mesh_level $partitions
   mpirun -np 2 ElmerSolver case.sif -ipar 2 $mesh_level $partitions


   end=$(date +%s)

   echo
   echo "Ending $solver with mesh level $mesh_level"
   echo "Elapsed time: $(($end-$start)) s"
   echo "-----------------------------------"
   echo
   
done

cd ../..
