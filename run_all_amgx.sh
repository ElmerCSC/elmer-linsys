#!/bin/bash
#SBATCH --time=00:20:00
#SBATCH --job-name=amgx_all
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

# Remove the result files if they already exist
# rm -f $path/results/f$linMarker.*

# Copy the valid case file into the case.sif file
# This can be commented out if there is only a single
# default case file in the folder
cp $path/case_amgx.sif $path/case.sif

for mesh_level in 3 4 5; do

    for solver in linsysAMGX/*.sif; do

	if grep -Fxq "$solver" solver-lists/$problem-Solvers.txt
	then

            cp $solver $path/linsys_amgx.sif
	    # Assumes that the config file is named similarly to .sif file
	    filename=$(basename "$solver" ".sif")
	    cp linsysAMGX/$filename.json $path/config.json
	    
            cd $path

            start=$(date +%s)

            echo
            echo
            echo "-----------------------------------"
            echo "Starting $solver with mesh level $mesh_level"
            echo
    
            srun ElmerSolver case.sif -ipar 2 $mesh_level $partitions

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
