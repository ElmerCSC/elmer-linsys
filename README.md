# Benchmarks for linear systems

This repository provides tools and test cases for comparing of different linear solver strategies. The idea is to provide more insight to how different strategies work for given problems and what kind of weak and strong scaling laws they follow. The resulting tools will hopefully help people to choose the most efficient linear solver strategy for their problem. 

We are open for ideas what problems should be studied. The test cases should be scalable and simple in the sense that only one equation is analyzed at a time.  Scalable test require that the mesh can be easily obtained in different densities. This may mean internal mesh multiplication by using "Mesh Levels" or easily refined meshes with some open source tools. 

