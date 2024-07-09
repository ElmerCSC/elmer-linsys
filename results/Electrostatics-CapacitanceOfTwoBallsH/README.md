# Electrostatics problem with two conducting balls

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBallsH/electrostatics-capacitanceOfTwoBalls.png?raw=true)

## Problem description

Spherical approximations are a classic in electromagnetism and thus a problem consisting of two balls provides a simple yet insightful example of a electrostatics problem. A very coarse mesh of the problem is visualized above. As this example is very simple it makes it possible for multitude of solvers to converge. Indeed, the coefficient matrix is symmetric and positive definite meaning (theoretically) any choice of solver should work. The shape of the coefficient matrix can be found below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBallsH/sparsity_structure.png?raw=true)

## Results

The benchmarks on this problem were only done on a single Mahti node with number of degrees of freedom varying from around 450 000 to around 24 000 000. The runtimes can be found from picture files "runtimes_ML*.png". Runtimes for the smallest and largest runs are visualized below.

![Runtimes small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBallsH/runtimes_ML2.png?raw=true)
![Runtimes large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBallsH/runtimes_ML4.png?raw=true)

The variability seems quite drastic between the fastest and the slowest methods (around 100 fold) in the smallest case, but somewhat evens out when going to the larger runs. This would be indicative of differing scalabilities between the solvers. The scaling coefficients computed for the solvers are found below:

![Scalability single node](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBallsH/scalability_bar_ML2-4.png?raw=true)

## Conclusions

Generally, in the small cases it seems that Elmer's implementations of ILU(n) preconditioned BiCGStab(l) and Idr(s) methods perform best, with almost non-existant differences in the runtimes. When the problem size is increased Hypre's BoomerAMG preconditioned BiCGStab becomes quite significantly faster than the rest. But still e.g. Elmer's Idr(s) method with ILU(1) preconditioning wouldn't be an overly poor choice. An unusual observation is that the ILU(1) preconditioner is competitive if not superior to ILU(0) preconditioner.

Overall, with larger problems it seems that Hypre's BiCGStab with BoomerAMG preconditioning is the obvious choice. It scales way better than Elmer's comparable implementations and has the smallest runtimes when increasing the problem size to that around 24 000 000 degrees of freedom. For smaller cases e.g. Elmer's Idr(s) method with ILU(n) preconditioning could be a good choice, although differences between all of Elmer's ILU(n) preconditioned Krylov subspace methods are quite minor. These methods also remain competitive in single node runs, but if the number of nodes were to be increased they would most likely end up lagging behind.