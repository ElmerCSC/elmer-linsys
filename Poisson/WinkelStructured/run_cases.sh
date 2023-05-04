#!/bin/bash/

# Define here the solver to be used
solver=linsys/direct_MUMPS.sif
linMarker=2

# Remove the result files if they already exist
rm -f results/f$linMarker.*

cp $solver linsys.sif

for i in 1 2 3 4; do
	
   start=$(date +%s%N)
   ElmerSolver case_single.sif -ipar 1 $i
   end=$(date +%s%N)

   echo ""
   echo ""
   echo "Ending: $solver with mesh level $i"
   echo "------------------------------------------"
   echo "Elapsed time: $(($end-$start)) ns"
   echo ""
   echo ""
   
done
