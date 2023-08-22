# Vectorial Helmholtz equation on an structured bandpass filter

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterHexas/vectorHelmholtz-bandpassFilterHexas.png?raw=true)

## Problem description

A bandpass filter is a natural application of Vectorial Helmholtz in solving time-harmonic Maxwell equations. Thus, a simple example of it also makes for a very enlightening example for benchmarking. A very coarse mesh of the problem is visualized above. This is technically the same problem as described in "VectorHelmholtz-BandpassFilterTets", but with a structured mesh. Usually a structured mesh leads to better results than their unstructured counterparts, but in this case the convergence was far worse for most methods. Thus, it is hard to say definitely what type of coefficient matrix was formed. By nature of the vectorial Helmholtz problem the matrix won't be positive definite (and most likely not positive semi-definite), but in this case it also seems to not be invertible. For those interested, an example of the sparsity structure for a characteristic matrix is visualized below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterHexas/sparsity_structure.png?raw=true)

## Results

The benchmarks were done on both a single Mahti node (128 partitions) and Mahti nodes (1024 partitions) with number of degrees of freedom ranging from around 500 000 to around 3 500 000. Unfortunately, this only constitutes two datapoints and thus isn't really enough for fitting a curve. When trying to create a finer mesh through mesh multiplication beyond the 3 500 000 degrees of freedom convergence suffered significantly.  The runtimes can be found from picture files "runtimes_ML*.png". Runtimes for the smallest and largest runs on a single Mahti node are visualized below.

![Runtimes small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterHexas/runtimes_ML1.png?raw=true)
![Runtimes large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterHexas/runtimes_ML2.png?raw=true)

## Conclusions

Overall, it seems that for some reason this benchmark didn't work as one would hope. Hence, drawing conclusions from it is somewhat moot, but if it had to be done one could conclude that the best choice for solver would be Elmer's implementation of Idr(s) without preconditioner. This solver performed the best in every run, but if the coefficient matrix were better behaved there might have been better options available.