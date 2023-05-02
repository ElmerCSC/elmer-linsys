#!/bin/bash
for s in linsys/*.sif; do
    echo '----------------------------------------------'
    echo 'starting: '$s  
    cp $s linsys.sif
    ElmerSolver
    echo 'ending: '$s  
    echo '----------------------------------------------'
done

