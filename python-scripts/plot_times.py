"""
Basic Python script that plots the execution times of all solvers with a given mesh level
If the file contains data for multiple mesh levels plots only the most common one

This script has four optional passable cmd args
   1. -f (--file) for using a different file than the one predefined
   2. -p (--path) for using a different path than the one predefined
   3. -t (--total_time) for plotting the total time as well (passed value should be "yes")
   4. -m (--mesh_level) for choosing the wanted mesh level if selected file contains multiple

Note it is not recommended to plot total times as well if file contains results for a large number of solvers
as the figure will get very crowded
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import warnings
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
cwd_arr[-1] = "Poisson/WinkelUnstructured/results"
os.chdir('/'.join(cwd_arr))

plot_total_time = False

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
    global plot_total_time
    mesh_level = None
    
    if len(sys.argv) > 1:
        parser = argparse.ArgumentParser()
        parser.add_argument('-p', '--path', type=str)
        parser.add_argument('-t', '--total_time', type=str)
        parser.add_argument('-f', '--file', type=str)
        parser.add_argument('-m', '--mesh_level', type=int)
        args = parser.parse_args()

        if args.path is not None:
            os.chdir(args.path)

        if args.total_time is not None:
            if args.total_time.lower() == 'yes':
                plot_total_time = True

        if args.file is not None:
            dat_filename = args.file

        mesh_level = args.mesh_level
        
    data = pd.read_table(dat_filename, delim_whitespace=True, header=None)
    solvers = read_markers(dat_filename)

    data.columns = columns
    data['Solver'] = solvers

    # Find the most common mesh level value and drop all rows with different mesh level
    # if no chosen mesh level was passed
    if mesh_level is None:
        mesh_level = data['MeshLevel'].mode()[0]

    data = data[data['MeshLevel'] == float(mesh_level)]

    solvers = data['Solver'].values.tolist()
    n_solvers = len(solvers)

    # Find the median of the norm values and remove the rows where the
    # norm varies significantly
    median = np.median(data['norm'].values)  # Might need to be changed to mode if floating point error can be handled
    data = data[np.isclose(data['norm'], median, atol=10 ** (-6))]

    if len(data) != n_solvers:
        print(f"WARNING: Solvers: {', '.join(list(set(solvers).difference(set(data['Solver'].values.tolist()))))} had incorrect solution")

    data.sort_values(by=[use_time], ascending=True, inplace=True)

    use_times = data[use_time].values
    total_times = data['total CPU time (s)'].values
    solvers = data['Solver'].values.tolist()

    y_axis = np.linspace(0, len(solvers), len(solvers))

    # Plot the times as a barplot
    fig, ax = plt.subplots()

    if plot_total_time:
        total_time_bars = ax.barh(y_axis + 0.2, total_times, 0.4, label='total CPU time (s)')
        use_time_bars = ax.barh(y_axis - 0.2, use_times, 0.4, label=use_time)
        ax.bar_label(use_time_bars)
        ax.bar_label(total_time_bars)

    else:
        use_time_bars = ax.barh(y_axis, use_times, label=use_time)
        ax.bar_label(use_time_bars)

    ax.set_yticks(y_axis, solvers)
    ax.set_ylabel("Solver")
    ax.set_xlabel("Time (s)")
    ax.set_title(f"Runtimes for {'-'.join(os.getcwd().split('/')[-3:-1])} with Mesh Level: {int(mesh_level)} ({data['partitions'].iloc[0]} partitions)")
    ax.legend(loc='lower right')
    
    plt.show()


main()
    
