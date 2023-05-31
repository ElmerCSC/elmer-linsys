#!/bin/bash
gmsh -1 -2 circular.geo
ElmerGrid 14 2 circular.msh -autoclean -scale 1000.0 1000.0 1.0 
gmsh -1 -2 circular_coarse.geo
ElmerGrid 14 2 circular_coarse.msh -autoclean -scale 1000.0 1000.0 1.0 
