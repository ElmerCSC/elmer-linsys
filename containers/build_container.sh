#!/bin/bash
#SBATCH --job-name=elmer_container_build
#SBATCH --account=project_2001659
#SBATCH --partition=gpumedium
#SBATCH --time=00:40:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1 --cpus-per-task=72  # The product should be 72 if requesting 1 GPU per node
#SBATCH --gres=gpu:gh200:1  # Corresponds to 1 GPU per node

srun apptainer build --fakeroot container.sif Elmer_roihu_single_stage_v10_amgx_mmg_lib64.def