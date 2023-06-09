#!/bin/bash
#SBATCH --time=00:20:00
#SBATCH --job-name=amgx_single
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=gpumedium
#SBATCH --gres=gpu:a100:4,nvme:950
#SBATCH --account=project_2001628
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4

export OMP_NUM_THREADS=32
module load elmer/amgx

# Define the path to the case folder
path=Poisson/WinkelUnstructured

# Define the problem type
problem=PoissonAMGX

# Define the number of partitions (should be nodes * ntasks-per-node)
partitions=4

# Declare here which solver is to be used
solver=linsysAMGX/elmer_amgx_fgrmes.sif
config=linsysAMGX/elmer_amgx_fgrmes.json
# linMarker=??????

if ! grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
then   
    echo
    echo "Solver $solver not recommended for given problem. Exiting"
    echo
    exit
fi

# Remove the result files if they already exist
# rm -f $path/results/f$linMarker.*

# Copy the valid case file into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
cp $path/case_amgx.sif $path/case.sif

cp $solver $path/linsys_amgx.sif
cp $config $path/config.json

cd $path

for mesh_level in 1 2 3 4; do

    echo
    echo
    echo "-----------------------------------"
    echo "Starting $solver with mesh level $mesh_level"
    echo

    start=$(date +%s)
    
    srun ElmerSolver case.sif -ipar 2 $mesh_level $partitions

    end=$(date +%s)

    echo
    echo "Ending $solver with mesh level $mesh_level"
    echo "Elapsed time: $(($end-$start)) s"
    echo "-----------------------------------"
    echo
   
done

cd ../.. 
