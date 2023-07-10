# Stokes problem with circular geometry


![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Stokes-Circular/stokes_circular.png?raw=true)


The Stokes problem with a circular ice sheet provides a simple and scalable example problem for glaciology.
Stokes problem in glaciology differs from other problems in that the linear system solves simultaneously
for velocity and pressure using block matrices. This also means that the solution to the problem isn't
necessarily a strict minimum, but a saddle point. For more information see e.g. https://elmerice.elmerfem.org/wiki/doku.php?id=start

Due to the problems block matrix nature the solvers are also chosen to work block-wise (denoted with "bpc"
in the solver name) and really the comparison then is between the block solvers. None the less the problems
are symmetric and positive definite since conjugate gradient without preconditioning converges. The shape of
the coefficient matrix can be seen below.


![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Stokes-Circular/sparsity_structure.png?raw=true)


In the tests we used a variety of solvers combined with different preconditioners. Out of the preconditioner
choices vanka had trouble with converging and ILU1 which probably would have converged took too long to be a
valid choice. This left ILU0, BoomerAMG and no preconditioner as possible choices.

Looking at the scalability bar plot it appears that Hypres BiCGStab with BoomerAMG preconditioning scales
best while Elmers implementation of IDRS{5} with ILU0 preconditioning is close behind. This is true, but
if we look at the runtimes we notice that Hypres solvers are still significantly slower than Elmers IDRS{5}
and CG with ILU0 preconditioning. So unless the problem is very large (requiring significantly more than
1000 cores) the best choice seems to be IDRS{5} with ILU0 preconditioning.

Also we notice that no preconditioner options were the slowest in this comparison and not really recommended.