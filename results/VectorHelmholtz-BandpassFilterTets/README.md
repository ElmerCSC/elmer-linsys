# Vectorial Helmholtz equation on an unstructured bandpass filter

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterTets/vectorHelmholtz-bandpassFilterTets_a08.png?raw=true)

## Problem description

A bandpass filter is a natural application of Vectorial Helmholtz in solving time-harmonic Maxwell equations. Thus, a simple example of it also makes for a very enlightening example for benchmarking. A very coarse mesh of the problem is visualized above. As a vectorial Helmholz the formed coefficient matrix is not positive definite (and most likely not positive semi-definite). Likewise, as a vectorial Helmholtz problem the same analysis also applies here as in the case "VectorHelmholtz-Waveguide". Thus, as the results are very similar, the reader is referred there or can make their own conclusions based on the included plots. For those interested, an example of the sparsity structure for a characteristic matrix is visualized below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterTets/sparsity_structure.png?raw=true)

## Other benchmarks

With wave equations the tolerance based incomplete LU factorization (ILUT) can provide slightly more intuitive results than standard ILU(n) and might even improve convergence. Additonally, there hasn't been any ILUT preconditioned solvers in the other benchmarks so it is good to get some data with them as well. The benchmarks were done on 2 Mahti nodes (256 partitions) with degrees of freedom ranging from around 40 000 to around 1 150 000. The plots can be found below.

![Runtimes ML1](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterTets/runtimes_ILUT_ML1.png?raw=true)
![Runtimes ML2](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterTets/runtimes_ILUT_ML2.png?raw=true)
![Runtimes ML3](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/VectorHelmholtz-BandpassFilterTets/runtimes_ILUT_ML3.png?raw=true)

From the results we see that the differences in runtimes that the changes in tolerances cause are quite small. Interestingly, across multiple solvers the different tolerances can have quite a different effect even though the underlying coefficient matrix is the same. With BiCGStab(l) it seems that performance is consistently improved by having a very big tolerance (1e-1 or 1e-2), while similar effect is not visible with Idr(s). This means that the increase (or decrease) in tolerance doens't really have a systematic impact on the runtimes as one might assume.

It is also good to note that the ILUT preconditioner doens't seem to make the solvers any more stable as with the finest mesh all Idr(s) and some BiCGStab(l) solvers fail to converge. This is an effect that was seen in the main benchmarks as well (see runtimes_ML3.png for example).

Overall, it is hard to draw any real conclusions from the available data, but fundamentally it appears that there is no good way to choose a optimal tolerance for ILUT preconditioner as it is very much mesh and solver dependent.