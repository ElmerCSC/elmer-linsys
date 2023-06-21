### test case for ChEESE on LUMI

##### To prepare the mesh:

This requites "gmsh" to be installed. 
Prepare the mesh with a script command.
If we want a bigger original mesh have a smaller value for clscale
```
gmsh winkel.geo -3 -clscale 0.2
```

! Transfer mesh into Elmer format
```
ElmerGrid 14 2 winkel.msh -autoclean -partdual -metiskway #np -nooverwrite
```