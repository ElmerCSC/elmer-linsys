# Magnetostatics problem with five torus shaped closed coils


![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Magnetostatics-FiveCoils/magnetostatics-fiveCoils.jpg?raw=true)


Magnetostatics problems, even in simple cases, provide their own challenges,
namely that there isn't an unambigous solution to the problem. This means
that preconditioners that work by approximating the inverse (e.g. ILU)
of the coefficient matrix will fail. Additionally, the coefficient matrix
while symmetric is not positive definite and thus requires solvers that can
handle more general matrices. The shape of the coefficient matrix can be
seen below.


![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Magnetostatics-FiveCoils/sparsity_structure.png?raw=true)


Due to the nature of the problem we are limited to a very few solvers. Looking
at the scalability bar plot we see that IDRS{5} solver seems to scale the best.
However, it didn't converge in the larger cases and thus generally a good choice
could be Elmers implementation of BiCGStab{4}, which both scaled well and
converged with larger problems.