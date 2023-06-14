# Navier problem on structured Winkel geometry


![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured/navier_winkelStructured.png?raw=true)


Linear elasticity on a simple 3D geometry provides a simple problem, but unlike the heat equation
contains 3 degrees of freedom for each node. Thus as the mesh grows the coefficient matrix grows
at a significantly faster rate than in the Poisson problems. This puts significant strain on the
linear solvers and their scalability. In spite of this the coefficient matrix is symmetric and
positive definite as CG without preconditioning converges. Sparsity structure for the problem
can be found below.


![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured/sparsity_structure.png?raw=true)


Looking at the scalability bar plots we see that some solvers (generally from hypre)
have a scaling coefficient of less than 1. This shouldn't really be possible and is
most likely caused by a proportionally significant overhead from finding the
preconditioner in the smaller cases. The Hypre and Elmer implementations for ILU family
of preconditioners differs in that Elmer does the preconditioning partitionwise while
Hypre does it 'properly' with the downside that finding the preconditioner isn't fully
parallelizable. Similarly the AMG preconditioners most likely have quite a large overhead
due to the need for solving the coarse problem as an approximation for the fine grid solution.
Note that as the Navier problems are by default bigger than Poisson ones (due to having 3 dofs
per node rather than one) the scaling coefficients are generally all better behaved, apart from
a few that are overly high.

Looking at the runtimes for smaller cases it appears that FETI solvers and GCR perform very well.
These are block based methods, which clearly can utilize the structure of the coefficient matrix
efficiently. However, with standard mesh multiplication the convergence of these methods is poor,
which is why they don't show in the barplots for larger problem sizes. It could be that if the
increase in mesh size was done in some other way the convergence can be retained. Other well
performing solvers are the IDRS family of solvers as well as standard CG. As the problem size
increases Hypres solvers become comparatively better, but in the scales studied aren't contenders
against IDRS or CG implementations.

Thus generally a good choice seems to be IDRS5 with ILU0 or CG with ILU0 preconditioning independent
of the problem size, but further research is required.



