"""
Basic Python script that plots the execution times of all solvers with a given mesh level
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os


# Change directory to WinkelStructured/results to access the .dat files
print(os.getcwd())
cwd_arr = os.getcwd().split('/')
cwd_arr[-1] = "WinkelStructured/results"
os.chdir('/'.join(cwd_arr))

columns = ["Line Marker", "dofs", "elements", "partitions", "norm", "total CPU time (s)",
           "simulation CPU time (s)", "simulation real time (s)", "linsys CPU time (s)",
           "linsys real time (s)", "solver CPU time (s)", "solver real time (s)",
           "MeshLevel"]

use_time = "linsys CPU time (s)"  # Must be listed in columns


def main():
    data = pd.read_table(f"f.dat", delim_whitespace=True, header=None)
    markers = pd.read_table(f"f.dat.marker", sep=':', header=None)

    solver = markers[1].values.tolist()

    data.columns = columns
    data['Solver'] = solver

    # Drop the row if the solver failed
    data = data[data['norm'] != 0.0]

    times = data[use_time].values.tolist()
    solvers = data['Solver'].values.tolist()

    # Plot the times as a barplot
    fig, ax = plt.subplots()
    ax.bar(solvers, times)
    ax.set_xlabel("Solver")
    ax.set_ylabel(use_time)
    ax.set_title(f"Solver runtimes with Mesh Level: {int(data['MeshLevel'][0])}")
    plt.xticks(rotation=30, ha='right')

    plt.show()


main()
    
