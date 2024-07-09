# Poisson problem with unstructured Winkel geometry

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/poisson_winkelUnstructured.png?raw=true)

## Problem description

The heat equation on simple 3D geometry (like the unstructured Winkel) provides a very 'easy' problem and is thus a good choice for benchmarking a variaty of solvers. A very coarse mesh of the problem is visualized above. As the problem is fundamentally a Poisson problem the formed coefficient matrix is symmetric and positive definite. This means that (theoretically) any choice of a solver should converge. Additionally, as there is only a single degree of freedom per node, the size of the coefficient matrix remains reasonable even for quite fine meshes. For those interested, an example of the sparsity structure for a characteristic matrix is visualized below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/sparsity_structure.png?raw=true)

## Results

The benchmarks with the unstructured Winkel geometry were done with number of degrees of freedom ranging from around 13 000 to around 24 000 000 on both a single Mahti node (128 partitions) and 4 Mahti nodes (512 partitions). The runtimes can be found from picture files "runtimes_ML*.png". Runtimes for the smallest and largest runs on a single Mahti node are visualized below.

![Runtimes small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/runtimes_ML1.png?raw=true)
![Runtimes large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/runtimes_ML5.png?raw=true)

From these we can see a great variability (up to a hundred fold) in the runtimes between the fastest and slowest solvers. This variablity can in part be constituted to the differences in scalability. The scalability coefficents for both the single node and 4 node run are visualized below.

![Scalability single node](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/scalability_bar_ML1-5.png?raw=true)
![Scalability 4 nodes](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/scalability_bar_ML1-5_P512.png?raw=true)

## Conclusions

Generally, it seems that in the smaller cases any solver could be valid as, while the difference between runtimes can be around ten fold, all ran in a sub-second time. It is really in the larger cases where differences increase significantly. In the largest case the fastest solvers were Hypre library implementations of the BiCGStab(l) method with slightly varying BoomerAMG preconditioners. From the scalability plots these were also the best scaling solver choices. In smaller cases Elmer's implementations of BiCGStab(l) and Idr(s) with differing ILU(n) preconditioners can be very competitive, but don't scale nearly as well.

Thus, for smaller problems a good choice of solver could be e.g. Elmer's Idr(s) method with ILU(n) preconditioner while for larger cases the undeniably best option is Hypre's implementation of BiCGStab(l) with BoomerAMG preconditioner.

## Other benchmarks

Due to the simplicity of this benchmark it has also been used in some more case specific benchmarks. These are the benchmarks on some solvers provided by AmgX library as well as comparisons on greater range of BoomerAMG preconditioned methods as those seemed to perform exceptionally in the main benchmark.

### AmgX benchmarks

The support for Nvidia's AmgX library was recently added to Elmer and allows parallelizing the computations onto Nvidia GPUs. As the GPUs are by design different from CPUs the results with GPU accelerated solvers are not directly comparable to purely CPU based implementations. As the number of cores in a single GPU node (128 cores) is different to the number of GPUs (four Nvidia A100 GPUs) it isn't readily clear as to how many partitions should be used. Thus, some comparisons between number of partitions with a single solver are visualized below.

![Partition number comparison](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/scalability_amgx_1_node.png?raw=true)

From the graph it would seem that the best choice is four partitions (the green line) as this shares the same decent scalability as 8, 16 and 32 partitions, but has consistently a better runtime. In turn 1 and 2 partitions performs better on small cases, but scale worse. This is most likely the result from having less overhead at small cases from transferring the matrices to GPUs, but comes with the drawback that resources are inefficiently utilized.

Some runtimes acquired from running the case on a single Mahti GPU node with four partitions can be seen below.

![Runtimes AmgX small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/runtimes_amgx_ML2.png?raw=true)
![Runtimes AmgX large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/runtimes_amgx_ML4.png?raw=true)

Based on this (very small) sample it seems that conjugate gradient with DILU (diagonally-based incomplete LU factorization) performs best. Indeed, looking at the scalability plot below it also scales the best in this case.

![Scalability AmgX](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/scalability_bar_amgx_ML2-4.png?raw=true)

Interestingly, all of the solvers seem to have a scaling coefficient of less than one. This shouldn't be possible as the ideal case scenario would be linear scaling. The reason for this odd result is most likely a very large overhead from transfering the matrices to the GPUs, which hides the comparably small solving times.

### BoomerAMG benchmarks

As the Hypre's implementation of BiCGStab(l) method with BoomerAMG preconditioner performed so well it is only natural to wonder could the performance be further improved by finetuning the BoomerAMG parameters. Thus, benchmarks with an assortment of BoomerAMG settings were completed. The runtimes from these bechmarks on 2 Mahti nodes (256 partitions) are included below.

![Runtimes BoomerAMG small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/runtimes_boomeramg_ML2.png?raw=true)
![Runtimes BoomerAMG large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/runtimes_boomeramg_ML5.png?raw=true)

Clearly, the results vary significantly. However, the differences in runtimes remain somewhat constant across mesh sizes and this is further confirmed with (relatively) small differences in scaling coefficients as plotted below.

![Scalability BoomerAMG](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/scalability_bar_boomeramg.png?raw=true)

It seems that generally not scaling the linear system inmproves performance. Additionally, one would like to have "relax" parameter set to 3, "coarsen" to 0 and "smoother" to either 3 or 6. Example of how to set these is given below.
```fortran
Linear System Preconditioning = "boomeramg"

BoomerAMG Relax Type = Integer 3
BoomerAMG Coarsen Type = Integer 0
BoomerAMG Num Sweeps = Integer 1
Boomeramg Max Levels = Integer 25
BoomerAMG Interpolation Type = Integer 0
BoomerAMG Smooth Type = Integer 3  ! 6
BoomerAMG Cycle Type = Integer 1
BoomerAMG Num Functions = Integer 1  ! DOFs
BoomerAMG Strong Threshold = Real 0.5

Linear System Scaling = False
```