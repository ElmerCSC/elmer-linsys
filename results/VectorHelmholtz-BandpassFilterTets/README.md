# Vectorial Helmholtz equation on an unstructured bandpass filter

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterTets/vectorHelmholtz-bandpassFilter_a08.png?raw=true)

## Problem description

A bandpass filter is a natural application of Vectorial Helmholtz in solving time-harmonic Maxwell equations. Thus, a simple example of it also makes for a very enlightening example for benchmarking. A very coarse mesh of the problem is visualized above. As a vectorial Helmholz the formed coefficient matrix is not positive definite (and most likely not positive semi-definite). Likewise, as a vectorial Helmholtz problem the same analysis also applies here as in the case "VectorHelmholtz-Waveguide". Thus, as the results are very similar, the reader is referred there or can make their own conclusions based on the included plots. For those interested, an example of the sparsity structure for a characteristic matrix is visualized below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterTets/sparsity_structure.png?raw=true)