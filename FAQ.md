# Frequently asked questions

### When should I use direct methods?

Direct methods are often attractive for rather small cases but eventually loose their competitivenesss for larger cases due to poor scaling.
If the problem is 3D and vector valued the "fill-in" tends to kill the performance or exhaust the memory earlier.  

Also do note that as direct methods are usually based around LU-decomposition they require that the coefficient matrix is invertible to be usable.

Sometimes direct methods provide the only working solution. 


### Which multigrid implementation should I use?

Generally, when it comes to multigrid methods Elmers implementations are not the most robust and have some limitation. For example, Elmers implementations for algebraic multigrid and cluster multigrid are only available in serial. However, Hypres BoomerAMG implementation is available and supplements the selection where Elmers implementations are lacking. As BoomerAMG is overall more robust and works in parallel it should be the go to unless there is very specific reason for using Elmers implementations.

### What should be my go to Krylov subspace method?

There is a multitude of Krylov subspace mehtods available in Elmer and these vary highly with regards to their scalability and robustness. If the coefficient matrix is symmetric and positive definite the optimal choice should be CG. However, as it can be hard to verify positive definiteness of a matrix without trial and error a better option might be Idr(s). Idr(s) usually converges in very similar time as CG, but works also on indefinite matrices. Still in some (rare) cases Idr(s) might prove too unstable. In these cases it is worth trying BiCGStab(l) as it can at times converge with cases that Idr(s) did not.

To sum up, a good default is Idr(s). If matrix is known to be symmetric and positive definite CG is also a very good choice. If Idr(s) fails to converge one could try BiCGStab(l).

### How should I choose the convergence tolerance?

The desired convergence tolerance depends on how easy it to reach it and how it affects your results. As generic rule the tolerance should be
2-3 orders of magnitude smaller than desired nonlinear system tolerance. Elmer by default normalizes the equations so the choice of unit system
should not affect the tolerance chosen. A typical value could be 1.0e-8 but you can choose smaller value, e.g. 1.0e-10 if it easy to reach,
or larger values, e.g. 1e-7, if I have serious issues with convergence of the iteration.

### Sometimes my iterative solution seems to converge but then diverges. What should I do?

Nothing guarantees that Krylov methods would converge, most may even diverge. There is a flag "Linear System Robust = True" that can
bu used for Idr(s) and BiCGStab(l) that monitor the convergence and save the best intermediate result even in case of divergence.

### Why is "none" used as preconditioner?

By default Elmer scales the linear system such that the diagonal entries of the matrix become one. That has the same affect as
diagonal preconditioning. Hence the preconditioner "none" can often be used and with good convergence.

### What is the difference between ILUn and BILUn?

ILUn provides preconditioner that creates an incomplete LU-decomposition with sparsity structured of A^(n+1). BILUn is simular
except the entries are only created on the block-diagonal. Hence, BILUn is only applicable for vector valued problems. 





