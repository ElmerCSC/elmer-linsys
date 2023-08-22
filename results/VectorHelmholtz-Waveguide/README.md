# Vectorial Helmholtz equation on a "shoebox" geometry

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-Waveguide/vectorHelmholtz_waveguide.png?raw=true)

## Problem description

Vectorial Helmholtz problem used used to solve time-harmonic Maxwell equations, which arise in many practical applications. A simple example that can be used for benchmarking purposes is having the waves, within a simple "shoebox". This is technically a trivial example case as it could be solved analytically. Nonetheless same basic properties associated with other VectorHelmholtz cases can be found in the formed characteristic matrix. Namely, the characteristic matrix is not positive definite (and most likely not positive semi-definite), which narrows down the set of usable solvers. For those interested, an example of the sparsity structure for a characteristic matrix is visualized below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-Waveguide/sparsity_structure.png?raw=true)

## Results

The benchmarks with the "shoebox" geometry were done with number of degrees of freedom ranging from around 40 000 to around 12 000 000. Both a single Mahti node (128 partitions) and 4 Mahti nodes (512 partitions) were used. The runtimes can be found from picture files "runtimes_ML*.png". Runtimes for the smallest and largest runs on a single Mahti node are visualized below.

![Runtimes small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-Waveguide/runtimes_ML1.png?raw=true)
![Runtimes large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-Waveguide/runtimes_ML3.png?raw=true)

The variability between the results is relatively small. Still, when looking at the scalability of the solvers we can see some quite major differences. The scaling coefficients for both the single node and 4 node runs are plotted below.

![Scalability single node](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-Waveguide/scalability_bar_ML1-3.png?raw=true)
![Scalability 4 nodes](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-Waveguide/scalability_bar_ML2-4_P512.png?raw=true)

## Conclusions

It appears that the coefficient matrix formed for the problem is not positive semi-definite as AMG preconditioned solvers don't appear in the results. This cuts out most of the Hypre library implemented solvers. Still even the ones using ILU preconditioner seem to not have converged, which is unusual. Unusual is also how the BiCGStab(l) solvers seem to have a better scalability than Ids(s) family of solvers. But as this doesn't translate into faster runtimes the "better" scalability is most likely a result of higher per iteration cost or perhaps the need to compute the transpose.

Overall, purely based on runtimes the best solver choice would appear to be Elmer's implementation of Idr(s) with ILU(n) preconditioning, but for very large runs the scalability might end up being an issue.