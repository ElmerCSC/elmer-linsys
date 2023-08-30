# Stokes problem with circular geometry

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Stokes-Circular/stokes_circular.png?raw=true)

## Problem description

The Stokes problem with a circular ice sheet provides a simple and scalable example problem for glaciology. A very coarse mesh of the problem is visualized above. The incompressible Stokes problem in glaciology differs from other problems in that the linear system solves simultaneously for velocity and pressure using block matrices. This also means that the solution to the problem isn't necessarily a strict minimum, but a saddle point. For more information see e.g. https://elmerice.elmerfem.org/wiki/doku.php?id=start

Due to the problems block matrix nature the solvers are also chosen to work block-wise (denoted with "bpc" in the solver name) and really the comparison then is between the block solvers. Nonetheless the problems are symmetric and positive definite and thus a variety of block based solvers should converge. For those interested, an example of the sparsity structure for a characteristic matrix is visualized below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Stokes-Circular/sparsity_structure.png?raw=true)

## Results

The benchmarks with the circular geometry were done with the number of degrees of freedom ranging from around 3 800 000 to around 26 000 000. The benchmarks were performed on 4 Mahti nodes (512 partitions) as well as 8 Mahti nodes (1024 partitions). The runtimes can be found from picture files "runtimes_ML*.png". Runtimes for the smallest and largest runs on 8 Mahti nodes are visualized below.

![Runtimes small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Stokes-Circular/runtimes_ML1_P1024.png?raw=true)
![Runtimes large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Stokes-Circular/runtimes_ML4_P1024.png?raw=true)

Some variability seems to exist, but is not that major (around ten fold). Nonetheless, the differences in scalability between the solvers can vary significantly and are worth studying. The scaling coefficient from both the 4 node run and the 8 node run are plotted below.

![Scalability 4 nodes](https://github.com/ElmerCSC/elmer-linsys/blob/main/results//Stokes-Circular/scalability_bar_ML1-3.png?raw=true)
![Scalability 8 nodes](https://github.com/ElmerCSC/elmer-linsys/blob/main/results//Stokes-Circular/scalability_bar_ML1-4_P1024.png?raw=true)

## Conclusions

In this case the results are quite unanimous. Both concerning the runtime and the scalability the Elmer implementation of Idr(s) with ILU(n) preconditioning performs the best in both small and large cases as well as when increasing the number of nodes. Thus, it is the recommended solver.