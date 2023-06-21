# Generate the mesh (only test case currently)
echo "Generating the mesh ..."
echo "------------------------------------------------"

python3 gen_mesh.py

echo "------------------------------------------------"
echo

echo "Running ElmerGrid on the mesh ..."
echo "------------------------------------------------"

ElmerGrid 14 2 figure_8.msh -autoclean -metisbc -halo

# Partition the mesh
# ElmerGrid 2 2 figure_8 -partdual -metiskway 4

echo "------------------------------------------------"
echo

# Run the solver

echo "Solving the problem ..."
echo "------------------------------------------------"
ElmerSolver case.sif
echo "------------------------------------------------"
echo

echo "FINISHED"
