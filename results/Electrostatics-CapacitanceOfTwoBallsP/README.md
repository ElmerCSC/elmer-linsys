# Electrostatics problem with two conducting balls

![Problem Visualization](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBallsP/electrostatics-capacitanceOfTwoBallsP.png?raw=true)

## Problem description

Spherical approximations are a classic in electromagnetism and thus a problem consisting of two balls provides a simple yet insightful example of a electrostatics problem. An example of the problem is visualized above. This is a slightly modified case from the one analyzed in "Electrostatics-CapacitanceOfTwoBallsH" and utilizes higher-order $p$-elements. Unfortunately, currently the P-MultiGrid preconditioner is not overly stable with the change in mesh size so the results are somewhat incomplete. The shape of the coefficient matrix can be found below.

![Sparsity Structure](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBallsP/sparsity_structure.png?raw=true)

## Results

The benchmarks on this problem were only done on 2 Mahti nodes with number of degrees of freedom varying from around 530 000 to around 3 700 000. The runtimes can be found from picture files "runtimes_ML*.png". Runtimes for the smallest and largest runs are visualized below.

![Runtimes small](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBallsP/runtimes_ML3.png?raw=true)
![Runtimes large](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/Electrostatics-CapacitanceOfTwoBallsP/runtimes_ML4.png?raw=true)

The change in the degree of $p$-elements seems to have a intuitive effect on the runtime. Unfortunately, due to the instability in the method only two different mesh sizes were functioning and looking into the scalabilities is thus limited by the amount of usable data.

## Conclusions

Generally, it seems that Idr(s) outperforms the BiCGStab(l) in both when the mesh size and the order of the $p$-elements is increased. However, until the instability issues are resolved, there is no way to make proper conclusions.