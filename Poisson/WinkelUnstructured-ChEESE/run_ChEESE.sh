################################
## SLURM batchjob script for
## Elmer on LUMI
##
## copyleft 2023-06-21
##    CSC-IT Center for Sciencce
##
################################

#!/bin/bash 
#SBATCH --time=00:30:00
#SBATCH --job-name=ChEESE_test
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=standard

####### change to your project #######
#SBATCH --account=project_200XXXXX

####### change to numbers of nodes and MPI tasks ###
####### NB: we provide meshes for 128,256,512 and 1024 partitions #####
#######     do the math by matching the product of next entries   #####
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128

################## OpenMP Stuff ##########
## use only if you undersubscribe
## the MPI tasks
##########################################
#SBATCH --cpus-per-task=1
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
echo "running OpenMP on $SLURM_CPUS_PER_TASK"
#export KMP_AFFINITY=compact
#export KMP_DETERMINISTIC_REDUCTION=yes

###### enable CSC provided modules #########
module use /appl/local/csc/modulefiles
###### this loads the container version of Elmer
# module load elmer/latest
###### this loads the PregEnv/gnu version ###
###### (using cray-libsci (BLAS, LAPACK)
###### best to use this for audits! #########
module load elmer/gcc-cray
###### make it so! ######### 
srun ElmerSolver case.sif
