# Frequently asked questions

### When should I use direct methods?

Direct methods are rarely the fastest solvers available, but due to their simplicity might at times be an attractive option. For example, when doing small tests on a personal computer a direct method could be a valid option as any solver should be very fast. However, when working on larger cases direct methods will end up getting outperformed both time-wise (direct methods generally scale very poorly) and memory-wise (direct methods are susceptible to "fill-in") by other methods.

Also do note that as direct methods are usually based around LU-decomposition they require that the coefficient matrix is invertible to be usable.

### Which multigrid implementation should I use?

Generally, when it comes to multigrid methods Elmers implementations are not the most robust and have some limitation. For example, Elmers implementations for algebraic multigrid and cluster multigrid are only available in serial. However, Hypres BoomerAMG implementation is available and supplements the selection where Elmers implementations are lacking. As BoomerAMG is overall more robust and works in parallel it should be the go to unless there is very specific reason for using Elmers implementations.

### What should be my go to Krylov subspace method?

There is a multitude of Krylov subspace mehtods available in Elmer and these vary highly with regards to their scalability and robustness. If the coefficient matrix is symmetric and positive definite the optimal choice should be CG. However, as it can be hard to verify positive definiteness of a matrix without trial and error a better option might be Idr(s). Idr(s) usually converges in very similar time as CG, but works also on indefinite matrices. Still in some (rare) cases Idr(s) might prove too unstable. In these cases it is worth trying BiCGStab(l) as it can at times converge with cases that Idr(s) did not.

To sum up, a good default is Idr(s). If matrix is known to be symmetric and positive definite CG is also a very good choice. If Idr(s) fails to converge one could try BiCGStab(l).

