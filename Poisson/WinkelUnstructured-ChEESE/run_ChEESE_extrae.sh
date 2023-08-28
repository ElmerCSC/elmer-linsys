#!/bin/bash
################################
## SLURM batchjob script for
## Elmer on LUMI
##
## copyleft 2023-06-21
##    CSC-IT Center for Sciencce
##
################################
 
#SBATCH --time=00:10:00
#SBATCH --job-name=ChEESE_extrae
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=standard

####### change to your project #######
#SBATCH --account=project_462000233

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
ml use /appl/local/csc/modulefiles
# this loads the spack-PrgEnv-gnu cray-libsci (BLAS, LAPACK) version
###### best to use this for audits! #########
ml use /appl/lumi/spack/23.03/0.19.2/share/spack/modules/linux-sles15-zen2
ml use /appl/local/csc/soft/eng/elmer/spack/23.03/0.19.2/modules/tcl/linux-sles15-zen2/
ml load elmer/gcc-spack
###### this loads the container version of Elmer
# module load elmer/latest
###### this loads the PregEnv/gnu version ###
###### (using cray-libsci (BLAS, LAPACK)

###### load tools   #########
export SPACK_USER_PREFIX=/project/$SLURM_JOB_ACCOUNT/spack   # change this if necessary
module load spack/23.03-2
# module load papi
module load extrae
# export EXTRAE_CONFIG_FILE=extrae_detail.xml
export EXTRAE_CONFIG_FILE=extrae_detail_circular.xml
TRACE="env LD_PRELOAD=libmpitracecf.so"

###### make it so! ######### 
srun $TRACE ElmerSolver case.sif
