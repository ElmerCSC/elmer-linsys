# Poisson problem with structured Winkel geometry


![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelStructured/poisson_winkelStructured.png?raw=true)

## Problem description

This is very similar problem to the one described in "Poisson-WinkelUnstructured" directory. Only difference is that the mesh in this case is structured. This makes the problem somewhat easier, but doesn't change the results in a meaningful way compared to the unstructured case. Only notable difference is that FETI (finite element tearing and interconnect) seem to work in this case, which is most likely caused by better behaved substructures.

However, for a more thorough analysis the reader is referred to "Poisson-WinkelUnstructured" directory. For those interested, an example of the sparsity structure for a characteristic matrix is visualized below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Poisson-WinkelStructured/sparsity_structure.png?raw=true)
