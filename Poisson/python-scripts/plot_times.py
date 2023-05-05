"""
Basic Python script that plots the execution times of all solvers with a given mesh level
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import sys


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


# Function for manually going through the dat_file.marker file containing the solver names as splitting
# it directly with ':' as separator might not work as the solvers name could also contain it
def read_markers(dat_file):
    filename = f"{dat_file}.marker"
    solvers = []
    with open(filename) as file:
        for line in file:
            solvers.append(line.strip().split(': ', 1)[1])

    return solvers


def main():
    if len(sys.argv) > 1:
        dat_file = sys.argv[1]
    else:
        # Predefined value. Will be overwritten by passed command line arg
        dat_file = "f.dat"
        
    data = pd.read_table(dat_file, delim_whitespace=True, header=None)

    solvers = read_markers(dat_file)

    data.columns = columns
    data['Solver'] = solvers

    # Drop the row if the solver failed
    data = data[data['norm'] != 0.0]

    data.sort_values(by=[use_time], ascending=True, inplace=True)

    times = data[use_time].values.tolist()
    solvers = data['Solver'].values.tolist()

    # Plot the times as a barplot
    fig, ax = plt.subplots()
    bars = ax.barh(solvers, times)
    ax.bar_label(bars)
    ax.set_ylabel("Solver")
    ax.set_xlabel(use_time)
    ax.set_title(f"Solver runtimes with Mesh Level: {int(data['MeshLevel'][0])}")

    plt.show()


main()
    
