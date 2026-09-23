#!/bin/bash 
#SBATCH --time=01:00:00
#SBATCH --job-name=run_P-multigrid
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=medium
#SBATCH --account=project_2001628
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128

export OMP_NUM_THREADS=1
module load elmer/latest


# THIS IS A FULLY AUTOMATED BASH SCRIPT FOR RUNNING
# A CASE WITH GIVEN SET OF SOLVERS, MESH LEVELS
# AND P VALUES



# USER NEEDS TO FILL THE FOLLOWING CONSTANTS:


# Define the path to the case folder
CASE_PATH=Electrostatics/CapacitanceOfTwoBallsP

# Define the problem type
PROBLEM=P-MutliGrid

# Define the mesh levels to loop over
MESH_LEVELS=(1 2 3)

# Define the P values to loop over
P_VALUES=(2 3 4 5 6 7)


# USER CAN IF WANTED CHANGE FOLLOWING CONSTANTS:


# Define the number of partitions (no need to change)
PARTITIONS=$SLURM_NPROCS

# Define the path where resulting .dat files are stored (no need to change)
RET_PATH=$PWD/$CASE_PATH/results

# Define the resulting .dat file (no need to change)
RET_FILE=f$PARTITIONS.dat


ORG_DIR=$PWD


###################### RUN THE SCRIPTS #######################

# CHECK FOR PARTITIONINGS AND AS REQUIRED PARTITION THE MESH TO NEEDED AMOUNT

cd $CASE_PATH

# Find all folders with files of form mesh.*
MESH_DIRS=$(find . -type f -name "mesh.*" | sed -r 's|/[^/]+$||' |sort |uniq)

for mesh_dir in "${MESH_DIRS[@]}"; do

    # Check if proper partitioning already exists
    if [ -f "$mesh_dir/partitioning.$PARTITIONS" ]; then
	continue
	
    # Otherwise call ElmerGrid
    else
	ElmerGrid 2 2 $mesh_dir -partdual -metiskway $PARTITIONS
    fi

done

cd $ORG_DIR


# RUN THE ELMERSOLVER

echo "Running ElmerSolver..."

for mesh_level in "${MESH_LEVELS[@]}"; do

    for p_value in "${P_VALUES[@]}"; do

	for solver in linsys/*.sif; do

	    if grep -Fxq "$solver" solver-lists/$PROBLEM-Solvers.txt
	    then

		cp $solver $CASE_PATH/linsys.sif
		cd $CASE_PATH

		echo 
		echo 
		echo "-----------------------------------"
		echo "Starting $solver with mesh level $mesh_level and p-value $p_value"
		echo

		start=$(date +%s)
		
		srun ElmerSolver case.sif -ipar 3 $mesh_level $PARTITIONS $p_value

		end=$(date +%s)

   		echo
		echo "Ending $solver with mesh level $mesh_level and p-value $p_value"
		echo "Elapsed time: $(($end-$start)) s"
		echo "-----------------------------------"
		echo

		cd $ORG_DIR

	    else
		echo
		echo "Solver $solver not recommended for given problem. Ignoring it"
		echo
	    fi

	done

    done
    
done


cd $ORG_DIR

echo "DONE"
