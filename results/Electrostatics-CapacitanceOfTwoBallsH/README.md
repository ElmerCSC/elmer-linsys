# Electrostatics problem with two conducting balls


![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBalls/electrostatics-capacitanceOfTwoBalls.png?raw=true)


Spherical approximations are a classic in electromagnetics and thus a
a problem consisting of two balls provides a simple yet insightful
example of a electrostatics problem. As this example is very simple
it makes it possible for multitude of solvers to converge. Indeed,
the coefficient matrix is symmetric and positive definite since
conjugate gradient method without preconditioning converges. The
shape of the coefficient matrix can be found below.


![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBalls/sparsity_structure.png?raw=true)


Looking at the scalability bar plots we see that some solvers (generally from hypre)
have a scaling coefficient of less than 1. This shouldn't really be possible and is
most likely caused by a proportionally significant overhead from finding the
preconditioner in the smaller cases. The Hypre and Elmer implementations for ILU family
of preconditioners differs in that Elmer does the preconditioning partitionwise while
Hypre does it 'properly' with the downside that finding the preconditioner isn't fully
parallelizable. Similarly the AMG preconditioners most likely have quite a large overhead
due to the need for solving the coarse problem as an approximation for the fine grid solution.

Looking at the runtimes we see that a lot of solvers remain relatively competitive, but there seems to
be a few choices that are better than others at least in bigger cases. Hypres implementation of BiCGStab
with BoomerAMG preconditioning seems to win in runtime for larger cases as well as in scalability
and would be a good choice for larger cases. In smaller cases Elmers BiCGStab and IDRS solvers seem to be
the fastest. Interestingly, they perform best with ILU1 preconditioner. Out of these IDRS{5} with
ILU1 preconditioning has scales the best and would be good choice for smaller cases.