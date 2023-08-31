# Benchmarks for linear systems

## General

As with many computational methods FEM at it's core requires solving a large _sparse linear system_. This is the computationally expensive operation in FEM simulation and thus a good choice of _linear solver_ can have a significant impact on the total runtime. Hence, over the decades a multitude of different solvers have been developed to solve linear systems with different properties. But this large quantity of options can be a double-edged sword in that a good solver most likely exists for each problem type, but finding it can feel overwhelming.

This repository provides tools and test cases for comparing of different linear solver strategies. The idea is to provide more insight to how different strategies work for given problems and what kind of weak and strong scaling laws they follow. The resulting tools will hopefully help people to choose the most efficient linear solver strategy for their problem. 

We are open for ideas what problems should be studied. The test cases should be scalable and simple in the sense that only one equation is analyzed at a time.  Scalable test require that the mesh can be easily obtained in different densities. This may mean internal mesh multiplication by using "Mesh Levels" or easily refined meshes with some open source tools.

## License

The contents of this repository are licensed under the Creative Commons Attribution-NonCommercial 4.0 International License. To view a copy of this license, visit <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a> 

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a>

## Links

As mentioned this repository provides lots of tools for benchmarking and is structured to allow easy automation. To learn more about this reader is directed to the [HOW_TO_USE.md](https://github.com/ElmerCSC/elmer-linsys/blob/main/HOW_TO_USE.md) file.

Additionally, lots of varying test cases are included. For the results of the benchmarks and some analysis on these cases reader is referred to [README.md](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/README.md) file in the [results](https://github.com/ElmerCSC/elmer-linsys/tree/main/results) directory.

Finally, each case specific directory in the [results](https://github.com/ElmerCSC/elmer-linsys/tree/main/results) has it's own README with some conclusions. However, these conclusions are by no means absolute or generalizable. So in the [FAQ.md](https://github.com/ElmerCSC/elmer-linsys/blob/main/FAQ.md) file can be found some answers for frequently asked questions that may provide some guidance when choosing a linear solver.

## Decision flowchart

For those too impatient to do a more rigorous study to find the optimal linear solver below is attached a flowchart that could guide to a very good option. If the properties of the coefficient matrix formed for the problem are not known beforehand one can start testing from the most strict requirements (top right) and proceed towards the least strict requirements (bottom left) until convergence is achieved. Alternatively, the handy table at [README.md](https://github.com/ElmerCSC/elmer-linsys/blob/main/results/README.md) file in [results](https://github.com/ElmerCSC/elmer-linsys/tree/main/results) directory can be used to learn about the matrix properties associated with each problem type.

![Decision flowchart](https://github.com/ElmerCSC/elmer-linsys/blob/main/pics/decision_flowchart.png?raw=true)