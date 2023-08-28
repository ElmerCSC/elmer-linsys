# Results for linear system benchmarks on multiphysics problems solved by Elmer

# Table of contents
1. [General](#general)
2. [Benchmarking](#benchmarking)
3. [Problems](#problems)
4. [Tables](#tables)
   1. [Solver properties](#solver_props)
   2. [Problem properties](#problem_props)
5. [Linear systems](#linsys)
6. [Linear solver families](#families)
   1. [Direct methods](#direct)
   2. [Krylov subspace methods](#krylov)
   3. [Multigrid methods](#multigrid)
   4. [Preconditioning](#preconditioning)
   5. [Other implementations](#others)

## General <a name="general"></a>

This markdown has quite a lot of information so depending on the readers goals some sections could be skipped. Ideally, everyone who is choosing a linear solver should read Sections [1](#general)-[4](#tables). Of these the most crucial is the Section [4](#tables) as that outlines both with which matrix types a given linear solver would work and what types of characteristic matrices each outlined problem forms. This at least should guide the reader in the choice of what _not_ to choose as the linear solver, but isn't enough to find the go to solver.

Sections [5](#linsys)-[6](#families) provide extra information on the solvers and their properties and can be skipped if that is not of interest. These sections are by no means mathematically rigorous, but require a running understanding of numerical linear algebra.

## Benchmarking <a name="benchmarking"></a>

The benchmarks in this directory mainly look into two factors: the total runtimes of the solvers and the algorithmic scaling of the solvers. The algorithmic scaling is generally formalized in the equation:
```math
t = \alpha n^{\beta}
```
where the $t$ is the runtime, $n$ the dimension of the system, $\alpha$ the constant coefficient and $\beta$ the scaling coefficient. By looking at the runtimes for different sized systems we can get an idea for $\alpha$. However, it is the $\beta$ that has the greater impact when the problem is scaled onto thousands of cores. Hence, it is separately computed by fitting a curve of the form associated with the algorithmic scaling to results on different sized systems.

Both the runtimes and $\beta$ are included as barplots in the problem specific directories. The total runtimes are plotted with the "plot_runtimes.py" script that can be found in "elmer-linsys/python-scripts" directory. Likewise, the scaling coefficients are can be plotted with the "plot_scalability_bar.py" script in the "elmer-linsys/python-scripts" directory. There are also some additional scripts for plotting different things. To learn about these please refer to the docstring found at the beginning of the script files.

Note that for each problem there exists benchmarks for Elmer's internal CPU based solvers as well as Hypre's CPU based solvers. Additionally, some more case specific benhmarks are available under some of the problem directories. These are listed below.

- [Poisson-WinkelUnstructured](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured): AmgX benchmarks
- [Poisson-WinkelUnstructured](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelUnstructured): BoomerAMG benchmarks
- [Navier-WinkelStructured](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Navier-WinkelStructured): AmgX benchmarks
- [VectorHelmholtz-BandpassFilterTets](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterTets): ILUT benchmarks

## Problems <a name="problems"></a>

In the benchmarks a variety of different problem types were covered. The links to the case specific directories are found below.

* Poisson
  - [WinkelStructured](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/Poisson-WinkelStructured)
  - [WinkelUnstructured](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/Poisson-WinkelUnstructured)
* Navier (Linear Elasticity)
  - [WinkelStructured](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/Navier-WinkelStructured)
* Stokes (Incompressible stokes)
  - [Circular](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/Stokes-Circular)
* Electrostatics
  - [CapacitanceOfTwoBalls (h-strategy)](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/Electrostatics-CapacitanceOfTwoBallsH)
  - [CapacitanceOfTwoBalls (p-strategy)](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/Electrostatics-CapacitanceOfTwoBallsP)
* Magnetostatics
  - [FiveCoils](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/Magnetostatics-FiveCoils)
* VectorHelmholtz
  - [Waveguide](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/VectorHelmholtz-Waveguide)
  - [BandpassFilter (Tetrahedral mesh)](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/VectorHelmholtz-BandpassFilterTets)
  - [BandpassFilter (Hexahedral mesh)](https://github.com/ElmerCSC/elmer-linsys/tree/main/results/VectorHelmholtz-BandpassFilterHexas)

## Tables <a name="tables"></a>

### Solver properties <a name="solver_props"></a>

Following table contains some requirements of the linear systems for an assortment of linear solvers and preconditioners. This list is not exhaustive, but outlines the most common choices. In the table "Pos. Sem-Def" is short for positive semi-definite and identically "Pos. Def." is short for positive definite. If the *-mark is in brackets the property is not strictly necessary, but highly recommended. Also note that as some of these properties are more restrictive than others (e.g. positive definite automatically means invertible) then also the superseded properties are marked.

| Solver | Square | Symmetric | Invertible | Pos. Sem-Def. | Pos. Def. |
| :----- | :----: | :-------: | :--------: | :-----------: | :-------: |
| CG     |    *   |     *     |     *      |      *        |     *     |
| LU     |    *   |           |     *      |               |           |
| Cholesky |  *   |     *     |     *      |      *        |     *     |
| BiCGStab(l) | * |           |            |               |           |
| Idrs(s) |  *    |           |            |               |           |
| QMR     |  *    |           |            |               |           |
| MINRES  |  *    |     *     |            |               |           |
| GMRES   |  *    |           |            |               |           |
| AMG     |  *    |   (*)     |            |     (*)       |           |
| ILU precond. |* |           |     *      |               |           |
| Vanka precond. | * |        |     *      |               |           |
| AMG precond. |* |   (*)     |            |     (*)       |           |

### Problem properies <a name="problem_props"></a>

Following table contains some properties of the linear systems associated with an assortment of problem types solvable with Elmer. This list is also not exhaustive, but outlines some commonly used ones. Same abbreviations etc. hold as in the case of table in Section [1](#solver_props) except for *-mark in brackets, which is used to indicate uncertainty in the property holding.

| Problem | Square | Symmetric | Invertible | Pos. Sem-Def. | Pos. Def. |
| :------ | :----: | :-------: | :--------: | :-----------: | :-------: |
| Poisson |   *    |     *     |     *      |      *        |     *     |
| Lin. Elasticity | * |  *     |     *      |      *        |     *     |
| Electrostatics | *  |  *     |     *      |      *        |     *     |
| Magnetostatics | *  |  *     |            |     (*)       |           |
| Incom. Stokes (block) | * | * |    *      |      *        |     *     |
| VectorHelmholtz | * |  *     |    *       |     (*)       |           |

Note that these are mainly based on the results of the benchmark tests. With a more complex meshes or boundary conditions the problem properties might change.

## Linear systems <a name="linsys"></a>

The linear systems of equations are commonly referred to as:
```math
Ax = b
```
where $A$ is the coefficient matrix, $b$ the right-hand side vector and $x$ the vector we are solving for. Naive approach for solving the system would be to invert the matrix $A$, but this is in practice never done. There are two reasons for it. Firstly, inverting a square matrix with e.g. Gaussian elimination is a $O(n^3)$ time operation, which for large $n$ is unfeasible. Secondly, number of non-zeros (and thus the memory requirements) of the inverse matrix is most likely much greater than the original one. Hence some more eloquent methods are required.

## Linear solver families <a name="families"></a>

Linear solvers can be grouped together based on some fundamental properties. However, which properties are chosen for said groupings are a bit arbitrary. Common groupings are e.g. _direct methods_, _Krylov subspace methods_ and _multigrid methods_. We will outline some basic properties for each.

### Direct methods <a name="direct"></a>

As their name suggests direct methods find a direct (rather than an approximative) solution to the linear system. However, this is done through decompositions instead of the matrix inverse. For general invertible matrices the most common decomposition is the LU-decomposition:
```math
A = LU
```
where $L$ is a lower triangular matrix and $U$ an upper triangular matrix. Once the decomposition is done solving the system $LUx = b$ is trivial. This is a result of the triangular nature of the matrices $L$ and $U$ as clearly if $L$ is lower triangular $Lx = b$ can be solved by first solving for $x_1$ from equation:
```math
l_{11}x_1 = b_1
```
then placing it to the second equation and solving for $x_2$ and continuing until $x$ is fully solved.

The LU decomposition is a $O(n^2)$ time operation and then solving for $x$ from the decomposed linear system is a $O(n)$ time operation. This greatly improves on naive matrix inversion with regards to the time complexity. However, the memory requirements can still become an issue as the sparse LU-decomposition suffers from "fill-in". That is $L$ and $U$ can be (most likely are) denser than $A$. "Fill-in" can be mitigated by methods like the _minimum degree algorithm_, but with large matrices even these might not be enough to keep the memory requirements from growing polynomially.

Direct methods can be very useful for small test cases run on a personal computer, but will end up being outperformed on larger simulations run on hundreds of cores by iterative methods. The benefit these methods have over others is their innate simplicity and thus using them with Elmer is as easy as it gets. To use a direct method it is enough to state:
```fortran
Linear System Solver = "Direct"
Linear System Direct Method = "MUMPS"  ! "umfpack", ...
```
in the problem case file.

Note that if $A$ is symmetric and positive definite, instead of LU-decomposition based direct methods, one should use Cholesky decomposition based methods. These find a decomposition $A = LL^T$. Fundamentally this is very similar, but generally Cholesky has better asymptotic complexity than LU.

### Krylov subspace methods <a name="krylov"></a>

Krylov subspace methods are some of the most well known and used iterative linear solvers. These include solvers such as conjugate gradient method, biconjugate gradient stabilized method and induced dimension reduction method.

The Krylov subspace in Krylov subspace methods refers to the $\text{order-}r$ Krylov subspace defined as:
```math
\mathcal{K}_r(A, b) = \text{span}\{b, Ab, A^2b, ..., A^{r-1}b\}
```
This is relevant as each iteration of a Krylov subspace method involves finding an iterate that is the $A$-orthogonal projection of the exact solution to a Krylov subspace. Consider for example the conjugate gradient method. In conjugate gradient method the $A$-orthogonal search directions $p_i$ are constructed from the residuals $r_i = b - Ax_i$ via a modified Gram-Schmidt process. Fundamentally, this requires the multiplication from left with $A$ with each iteration, which causes the iterate $x_i$ and search direction $p_{i-1}$ to exist in  $\mathcal{K}_i(A, b)$. As most Krylov subspace methods are heavily inspired by the conjugate gradient method similar reasonings could be found for them.

The reason why a large assortment of Krylov subspace methods exists is that the conjugate gradient method requires quite strict assumptions of $A$ to work. This is because conjugate gradient method doesn't solve $Ax = b$ itself, but finds the minimizer $x$ to an _energy function_:
```math
J(x) = \frac{1}{2}x^TAx - x^Tb
```
It can be shown that the solution $x$ to the linear system and the minimizer $x$ to the energy function are the same if $A$ is symmetric and positive definite (s.p.d.). Variants of the conjugate gradient method such as the biconjugate gradient stabilized method are designed to work with indefinite matrices as well.

Krylov subspace methods can be very useful in both small and large cases. Theoretically, e.g. the conjugate gradient method should reach an exact solution in $n$ iterations, which require matrix-vector products with time-complexity $O(n^2)$ (due to sparsity of the matrix this is really only the worst case scenario), leading to total worst case time-complexity of $O(n^3)$. However, in practise due to floating point errors an exact solution can never be found. Furthermore, an exact solution is rarely required as for example in the case of FEM the whole idea is to find an discrete approximation for a continuous phenomena. Thus, it should be enough if the error in the solution of the linear system is in the same order of magnitude as the discretization error. Hence, a tolerance for the solution is usually applied, which (assuming convergence) should decrease the required number of iterations. Additionally, to not waste time on non-converging solvers a maxmimum number of iterations is usually specified. Overall this means that Krylov subspace methods may reach a solution faster than direct methods even if their worst case time complexity is worse. Krylov subspace methods are also far more memory efficient as they don't require solving for a new matrix and thus generally have a constant memory requirement. An exception to this are methods like GMRES that require storing the found residuals to be used at later iterations.

Krylov subspace methods are a bit more complicated than direct methods and thus require more information from the user when called by Elmer. This information can be stated in form:
```fortran
Linear System Solver = "Iterative"
Linear System Direct Method = "CG"  ! "BiCGStabL", "Idrs", ...
Linear System Max Iterations = 10000  ! 1000, ...
Linear System Convergence Tolerance = 1.0e-8  ! 1.0e-7, ...
Linear System Abort Not Converged = True  ! False

Bicgstabl Polynomial Degree = 2  ! May be specified when using BiCGStabL
Idrs Parameter = 5  ! May be specified when using Idrs
...
```

### Multigrid methods <a name="multigrid"></a>

Multigrid methods are a newer class of solvers that are especially designed for solving discretized differential equations. They accomplish this by recursively doing coarse grid corrections on a set of coarser meshes of the problem. That is at the base case (with the coarsest mesh) the associated system is solved with a direct method. This solution of the base case is then used to find an approximation for the solution of the one finer mesh via coarse mesh correction. The finer approximations are then recursively used to find approximations on ever finer meshes until the original problem is reached. This is not an exhaustive explanation of the method. For more information see e.g. the ElmerSolver manual section 4.4 (the ElmerSolver is not fully up to date when it comes to multigrid methods available, but is a good starting point for learning more).

There are Elmer provides four different multigrid methods: the geometric multigrid (GMG), algebraic multigrid (AMG), cluster multigrid (CMG) and $p$-element multigrid (PMG), which differ in the way they find the coarse level equations. GMG uses a set of hierachical meshes to form the coarse level equations, while AMG can formulate them based on matrix $A$ alone via the classic Ruge-Stuben algorithm. CMG is an implementation of the agglomeration multigrid. PMG in turn is a novel approach for Elmer and finds the coarse level equations with regards to the $p$-elements rather than the standard mesh elements.

It is good to note that the Elmer implementations for AMG and CMG are not parallelized. In this regard Hypres BoomerAMG implementation supplements the selection.

The multigrid methods can theoretically be used with any (square) $A$, but it performs most reliably when $A$ is symmetric and semidefinite.

Multigrid methods can be used in Elmer by stating:
```fortran
Linear System Solver = "Multigrid"
MG Method = "Geometric"  ! "Algebraic", "Cluster", "p"
! The smoothing was not discussed, but is part of the iteration
MG Smoother = CG  ! Jacobi, BiCGStab, ...
MG Pre Smoothing iterations = 1  ! 2, 3, ...
MG Post Smoothing Iterations = 1  ! 2, 3, ...
MG Levels = 2  ! 3, 4, ...
! Define how the coarsest level equations are solved
mglowest: Linear System Solver = Iterative  ! Direct
mglowest: Linear System Iterative Method = BiCGStab  ! CG, ...
mglowest: Linear System Max Iterations = 100  ! 200, 500, ...
mglowest: Linear System Convergence Tolerance = 1.0e-5  ! 1.0e-3, 1.0e-7, ...
mglowest: Linear System Abort Not Converged = False
...
```

### Preconditioning <a name="preconditioning"></a>

For many iterative methods the rate of convergence is tied to the condition number $\kappa$ of the coefficient matrix $A$. Generally, for larger $\kappa(A)$ the convergence is slower. Thus, some methods attempt to find matrices $M$ such that $\kappa(MA) < \kappa(A)$. Here the matrix $M$ is known as the _preconditioner_ and is usually an approximation of the inverse of $A$.

There are many preconditioning methods available in Elmer including variants of the incomplete LU (ILU) decomposition, block jabobi based methods and multigrid based preconditioners. These can be accessed by stating:

```fortran
Linear System Preconditioning = ILU0  ! vanka, ...
```

### Other implementations <a name="others"></a>

Note that the above sections only really discuss Elmers internal implementations of linear solvers. However, Elmer also works with some external implementations including the Hypre library, Trilinos library and AmgX library. To utilize these some other keywords might be needed.

When comparing the same method across implementations there might be some differences in performance. This can be caused by differences in low-level optimizations or some more fundamental factors. For example there is a difference in how Elmers internal ILU factorization is computed to how the same is done in Hypres implementation, in that Elmer does the factorization partition-wise, while Hypre does it in a more "textbook" way for the full matrix $A$. Both have their advantages. Doing ILU factorization partition-wise allows for parallelization unlike the default way, but might lead to a worse approximation.