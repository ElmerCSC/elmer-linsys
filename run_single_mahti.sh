#!/bin/bash 
#SBATCH --time=02:00:00
#SBATCH --job-name=run_scaling
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=medium
#SBATCH --account=project_2001628
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=32

export OMP_NUM_THREADS=1
module load elmer/latest

# Define the path to the case folder
path=Poisson/WinkelStructured

# Define the problem type
problem=Poisson

if ! grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
then   
    echo
    echo "Solver $solver not recommended for given problem. Exiting"
    echo
    return
fi

# Declare here which solver is to be used
solver=linsys/elmer_iter_BiCGStab2_BILU0.sif
# linMarker=??????

# Remove the result files if they already exist
# rm -f $path/results/f$linMarker.*

# Copy the valid case file into the case.sif file
cp $path/case_all.sif $path/case.sif
cp $solver $path/linsys.sif
cd $path

for i in 1 2 3 4 5 6 7; do

    echo
    echo
    echo "-----------------------------------"
    echo "Starting $solver with mesh level $i"
    echo

    start=$(date +%s)
    
    srun ElmerSolver case.sif -ipar 1 $i

    end=$(date +%s)

    echo
    echo "Ending $solver with mesh level $i"
    echo "Elapsed time: $(($end-$start)) s"
    echo "-----------------------------------"
    echo
   
done

cd ../.. 
