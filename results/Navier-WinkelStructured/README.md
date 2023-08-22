# Navier problem on structured Winkel geometry

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured/navier_winkelStructured.png?raw=true)

## Problem description

The structured Winkel geometry provides a simple (but not trivial) case study for linear elasticity problem. Thus, it is a good choice for benhmarking a variety of solvers. A very coarse mesh of the problem is visualized above. The linear elasticity problems form a symmetric and positive definite coefficient matrix meaning that (theoretically) any choice of solver should converge. But as the linear elasticity has three degrees of freedom per node, even relatively coarse meshes can form a large problem, which can lead to large differences between performances of the solvers. For those interested, an example of the sparsity structure for a characteristic matrix is visualized below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured/sparsity_structure.png?raw=true)

## Results

The benchmarks with the unstructured Winkel geometry were done with number of degrees of freedom ranging from around 160 000 to around 7 000 000 on both a single Mahti node (128 partitions) and 4 Mahti nodes (512 partitions). The runtimes can be found from picture files "runtimes_ML*.png". Runtimes for the smallest and largest runs on a single Mahti node are visualized below.

![Runtimes small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured/runtimes_ML1.png?raw=true)
![Runtimes large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured/runtimes_ML3.png?raw=true)

Indeed, as predicted the variability in both the small and the large cases are quite large (around 100 fold). To study the cause of this the scalability coefficients for both the single node and the 4 node runs are plotted below.

![Scalability single node](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured/scalability_bar_ML1-3.png?raw=true)
![Scalability 4 nodes](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured/scalability_bar_ML1-3_P512.png?raw=true)

## Conclusions

Generally, it would seem that in smaller cases the hypre implementations are significantly slower and not recommended. Indeed, a somewhat suprising set of solvers, in FETI (finite element tearing and interconnect) and GCR (Generalized Conjugate Residual) based methods, perform the best in the smaller cases. Both FETI and the block preconditioned GCR can most likely utilize the structured nature of the geometry well. However, these methods did not converge in the larger runs would indicate some underlying stability issues. Additionally, the difference is in the runtimes was quite minor when compared to e.g. the Elmer implementations of ILU(n) preconditioned Idr(s) or CG methods. Thus, overall these could be a safer yet highly perfomant choice for solvers.

Another interesting note is that, most Hypre's solvers seem to have a very high overhead when solving the problems. This evident in them generally having a comaprably poor runtimes, but decent scalability. This scalability is not accurate, but in very large runs it might make some Hypre solvers like the BiCGStab with ILU preconditioning a considerable choice. Based on available data, that is still not recommendable.

## Other benchmarks

The support for Nvidia's AmgX library was recently added to Elmer and allows parallelizing the computations onto Nvidia GPUs. As the GPUs are by design different from CPUs the results with GPU accelerated solvers are not directly comparable to purely CPU based implementations. They can still be compared to one another and as the linear elasticity problem is relatively simple it provides a good framework for such benchmarks.

Some runtimes acquired from running the case on a single Mahti GPU node with four partitions can be seen below.

![Runtimes AmgX small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured/runtimes_amgx_ML1.png?raw=true)
![Runtimes AmgX large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-Structured/runtimes_amgx_ML3.png?raw=true)

Based on this (very small) sample it seems that conjugate gradient with DILU (diagonally-based incomplete LU factorization) performs best. However, looking at the scalability plot below it doesn't scale best.

![Scalability AmgX](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured/scalability_bar_amgx_ML2-4.png?raw=true)

Interestingly, all of the solvers seem to have a scaling coefficient of less than one. This shouldn't be possible as the ideal case scenario would be linear scaling. The reason for this odd result is most likely a very large overhead from transfering the matrices to the GPUs, which hides the comparably small solving times. This is likely most prevalent in the DILU preconditioned FGMRES method as it has by far the smallest scaling coefficient. It also had the longest runtimes, which is probably the explaining factor.
