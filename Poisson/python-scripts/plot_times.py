"""
Basic Python script that plots the execution times of all solvers with a given mesh level
If the file contains data for multiple mesh levels plots only the most common one

Usage is: 
    python3 plot_times.py   // When using predefined values
    python3 plot_times.py "file"  // When using predefined path, but given file
    python3 plot_times.py "file" -p "path"  // When using given path and file
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import sys
import argparse


columns = ["Line Marker", "dofs", "elements", "partitions", "norm", "total CPU time (s)",
           "simulation CPU time (s)", "simulation real time (s)", "linsys CPU time (s)",
           "linsys real time (s)", "solver CPU time (s)", "solver real time (s)",
           "MeshLevel"]

use_time = "linsys CPU time (s)"  # Must be listed in columns


################# PREDEFINED ####################

# Predefined .dat files that the code will look for if nothing is passed as argument
dat_filename = "f.dat"

# Change directory to predefined location from where the results can be read
# (in this case WinkelStructed/results)
cwd_arr = os.getcwd().split('/')
cwd_arr[-1] = "WinkelStructured/results"
os.chdir('/'.join(cwd_arr))

#################################################


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
    global dat_filename  # Python isn't smart enough so this needs to be declared
    
    if len(sys.argv) > 1:
        parser = argparse.ArgumentParser()
        parser.add_argument('-p', '--path', type=str)
        parser.add_argument('dat_file', type=str)
        args = parser.parse_args()

        if args.path is not None:
            os.chdir(args.path)

        if args.dat_file is not None:
            dat_filename = args.dat_file
        
    data = pd.read_table(dat_filename, delim_whitespace=True, header=None)
    solvers = read_markers(dat_filename)

    data.columns = columns
    data['Solver'] = solvers

    # Drop the row if the solver failed
    data = data[data['norm'] != 0.0]

    # Find the most common mesh level value and drop all rows with different mesh level
    mesh_level = data['MeshLevel'].mode()[0]
    data = data[data['MeshLevel'] == mesh_level]

    data.sort_values(by=[use_time], ascending=True, inplace=True)

    times = data[use_time].values.tolist()
    solvers = data['Solver'].values.tolist()

    # Plot the times as a barplot
    fig, ax = plt.subplots()
    bars = ax.barh(solvers, times)
    ax.bar_label(bars)
    ax.set_ylabel("Solver")
    ax.set_xlabel(use_time)
    ax.set_title(f"Solver runtimes with Mesh Level: {int(mesh_level)} ({data['partitions'][0]} partitions)")

    plt.show()


main()
    
