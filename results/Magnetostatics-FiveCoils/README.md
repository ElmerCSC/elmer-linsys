# Magnetostatics problem with five torus shaped closed coils

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Magnetostatics-FiveCoils/magnetostatics-fiveCoils.jpg?raw=true)

## Problem description

Compared to many of the problems discussed in this repository magnetostatics problems provide unique challenges. Most prevalent of these is the fact that the formed coefficient matrix is not invertible. This cuts out some solvers and a large set of preconditioners from the possible solver choices. Additionally, it means that there isn't an unambigous solution to the problem, which can make it challenging to verify the results. For those interested, an example of the sparsity structure for a characteristic matrix is visualized below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Magnetostatics-FiveCoils/sparsity_structure.png?raw=true)

## Results

The benchmarks with the five torus shaped closed coils were done with a differing numbers of degrees of freedom ranging from around 6 000 000 to around 400 000 000. Benchmarking was done on a single Mahti node (128 partitions) as well as 8 Mahti nodes (1024 partitions). The results from the single Mahti node are visualized below.

![Runtimes small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Magnetostatics-FiveCoils/runtimes_ML1.png?raw=true)
![Runtimes large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Magnetostatics-FiveCoils/runtimes_ML2.png?raw=true)

Clearly, the selection of converged solvers is not vast. Nonetheless, the ones that did converged seemed to perform more or less similarly, with the differences between slowest and fastest being only a few fold. However, due to the small number of datapoints it is hard to fit a valid curve to the datapoints to make some conclusions about the actual scalability that the solvers have. Thus, we don't have scaling coefficients for this case.

## Conclusions

Overall, the differences between the few converging solvers isn't that great. Thus, any choice of them would most likely lead to satisfactory results. However, it seems that Elmer's implementation of BiCGStab might scale the best and at least has the best runtime in the largest case. Generally, the BoomerAMG preconditioning, which is the only one that doesn't require the matrix to be invertible, doesn't seem to provide much additional benefit. This might be caused by the fact that AMG generally performs the best with syppetric and semidefinite matrices, which the one formed from magnetostatics problem might not be.