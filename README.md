# Benchmarks for linear systems

## General

This repository provides tools and test cases for comparing of different linear solver strategies. The idea is to provide more insight to how different strategies work for given problems and what kind of weak and strong scaling laws they follow. The resulting tools will hopefully help people to choose the most efficient linear solver strategy for their problem. 

We are open for ideas what problems should be studied. The test cases should be scalable and simple in the sense that only one equation is analyzed at a time.  Scalable test require that the mesh can be easily obtained in different densities. This may mean internal mesh multiplication by using "Mesh Levels" or easily refined meshes with some open source tools.

## Structure

This repository is structured to allow easy automation. Depending on the problem one wants to benchmark it will be found in directory "[problem type]/[geometry]". As an example there exists two separate benchmark cases for the Poisson problem (heat equation). These can be found in the "Poisson" directory. The individual geometries themselves are in directories "WinkelStructured" and "WinkelUnstructured" respectively.

The test cases themselves are not enough for proper benchmarking, and as the main target for the benchmarks are the different linear solvers these should be readily available. And indeed a large assortment of linear solvers can be found in the "linsys" and "linsysAMGX" directories.

However, as depending on the problem at hand one might not want to do the benchmarks with every available solver, there should be some way to "mask out" unwanted solvers. And for this purpose there is the "solver-lists" directory. Every file in this directory should be named in format "[problem type]-Solvers.txt" and in each file should be the paths to the files which describes the _wanted_ solvers for the problem.

Finally, once the data is available, there should be a way to easily analyze it. For this purpose there is a selection of python scripts available in the "python-scripts" directory.

Some results and analysis for the cases available in this repository can be found from the "results" directory.

## How to use

To automate the benchmarking as thoroughly as possible there are available some bash scripts. Of these the "run_complete.sh" and "run_complete_mahti.sh" are most mature and easiest to use. These function fundamentally the same way, with the only difference being that "run_complete.sh" is meant to be used on a personal computer, while "run_complete_mahti.sh" is primarily designed to be used on Mahti, but should be very easy to modify for any slurm based computer cluster.

These bash scripts will do everything from partitioning the mesh to needed amount (this is currently not super robust) and running ElmerSolver on specified case with specified solver to plotting the results. For the automated script to be able to control the mesh size and the wanted solver, the case file for the problem will have to be designed with that in mind. ElmerSolver implements two ways to help with this.

Firstly, one can include contents of another file into the case file with the "include" keyword. This is currently used to add the information of the wanted solver to the case file. That is the case file should contain the line
```fortran
include "linsys.sif"
```
at the valid Solver section, which is to be benchmarked. The bash script will copy the contents of a specified solver file from e.g. the "linsys" directory into the "linsys.sif" file in the case directory so that the correct solver is readily available for ElmerSolver.

Secondly, ElmerSolver allows passing "command line arguments" into the case file. To pass integer values into the case file one can use the -ipar flag. An example of how to use this is given below.
```bash
ElmerSolver case.sif -ipar 2 $n $m
```
Notice that to pass 2 wanted integer values (stored in variables n and m in the above example) one needs to specify to the -ipar flag as to how many values to expect. Thus, the first argument is the number of values to be passed. This value could be anything, but the automated bash script passes two values. The first of these values is the mesh level that is wanted and second is the number of partitions used. These can then be accessed in the case file with $ipar(0) and $ipar(1) respectively. It is up to the user to specify how the mesh level value is utilized. Natural choice would be to change the Mesh Levels value in the Simulation section with
```fortran
Mesh Levels = $ipar(0)
```
This causes ElmerSolver to do simple mesh multiplication for generating a finer mesh. However, if this causes stability issues one could generate multiple different sized meshes using a third party software beforehand and store these e.g. as "mesh_1", "mesh_2" etc. Then in the Header section one could specify
```fortran
Mesh DB "." "mesh_"$ipar(0)$
```
To choose the one with wanted size.
The number of partitions is not strictly necessary as it is only really used for naming the file into which the results are saved. This could be replaced with the line
```fortran
Partition Numbering = Logical True
```
in the valid solver.

The above mentioned valid solver is also required from the user. This is generally of form
```fortran
Solver <add solver number here>
  Equation = SaveTimings
  Procedure = "SaveData" "SaveScalars"

  Filename = f$ipar(1)$.dat
  Variable 1 = <add the variable of interest here>
  Operator 1 = dofs
  Operator 2 = elements
  Operator 3 = partitions
  Operator 4 = norm
  Operator 5 = cpu time

  Expression 1 = Real $ipar(0)

! Give a unique tag to each line/method
  Line Marker = Integer $LinMethod$

! We write a separate file showing how marker is mapped to string of the method
  Comment = String $LinStr$

  File Append = True
  Parallel Reduce = True
End
```
For the "SaveTimings" equation to be able to save the valid timings the lines
```fortran
Linear System Timing = True
Solver Timing = True
```
Should be added to the Solver section of interest. The variables $LinStr$ and $LinMethod$ should be specified in the solver file and are used to identify solvers in analysis phase.

To plot the found benchmarking results one can use the python scripts available in the "python-scripts" directory. To learn more about how these work reader is referred to the docstrings at the beginning of each script file. However, the scipts use some common third party libraries. These are "numpy", "matplotlib", "pandas" and "scipy". These can be installed with e.g. the pip package manager by stating
```bash
pip install <add the name of the package here>
```
on the command line.