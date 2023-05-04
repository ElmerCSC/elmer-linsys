#!/bin/bash

# Remove the result files if they already exist
rm -f results/f.*

# Define the mesh level to be used
mesh_level=3

for s in linsys/*.sif; do

    echo ""
    echo ""
    echo '----------------------------------------------'
    echo 'starting: '$s  
    cp $s linsys.sif
    ElmerSolver case_all.sif -ipar 1 $mesh_level
    echo 'ending: '$s  
    echo '----------------------------------------------'
    echo ""
    echo ""
    
done

