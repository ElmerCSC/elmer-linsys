# Poisson problem with structured Winkel geometry


![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelStructured/poisson_winkelStructured.png?raw=true)


The heat equation on simple 3D geometry provides a very 'easy' problem and is
thus a good choice for benchmarking a variaty of solvers. This is evident in the fact
that the coefficient matrix for the problem is symmetric and positive definite as
CG without any preconditioning converges. Sparsity structure for the problem can be
seen below.


![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelStructured/sparsity_structure.png?raw=true)


Looking at the scalability bar plots we see that some solvers (generally from hypre)
have a scaling coefficient of less than 1. This shouldn't really be possible and is
most likely caused by a proportionally significant overhead from finding the
preconditioner in the smaller cases. The Hypre and Elmer implementations for ILU family
of preconditioners differs in that Elmer does the preconditioning partitionwise while
Hypre does it 'properly' with the downside that finding the preconditioner isn't fully
parallelizable. Similarly the AMG preconditioners most likely have quite a large overhead
due to the need for solving the coarse problem as an approximation for the fine grid solution.

Looking at the runtimes for the larger problems it appears that a multitude of solvers are
still very competitive. These solvers generally fall into either the BiCGStab, CG or IDRS
families of solvers, while GMRES and direct alternatives fall behind. Also depending on the
number of partitions FETI might be a valid choice. This is in contrast with smaller cases
where all Hypre solvers take significantly longer, most likely due to the overhead from finding
the preconditioners.

For most cases Elmers implementation of IDRS with ILU0 preconditioning seems to be a good choice.
If the problem is very large then Hypres BiCGStab implementation with BoomerAMG preconditioners
become the best option.