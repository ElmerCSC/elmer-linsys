Original repository: https://github.com/ElmerCSC/elmerfem-manuals/tree/main/tutorials-GUI-files/CapacitanceOfTwoBalls

NOTE! As increasing mesh level currently breaks with the P-strategy
one can create larger meshes with netgen using the mesh.geo file.

In netgen a larger mesh can be created by choosing _Refine Uniform_ under
_Refinement_. Mesh can be saved in Elmer compatible form by choosing
_Elmer_ as filetype under _Export Filetype_ in _File_.

When the meshes are generated they consist of linear tetrahedrons. Those can
be changed to quadratic tetrahedrons by calling:
```
ElmerGrid 2 2 < linear mesh folder > -increase -out < quadratic mesh folder >
```

For the meshes to work with included case file they should be named _meshquad_ref_*_ where * takes some integer value 1, 2, ...