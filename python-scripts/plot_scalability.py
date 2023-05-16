"""
Basic Python script that plots the execution times for given linear solvers as a function of the number of elements and fits an exponential to them

Usage is: 
    python3 plot_scalability.py   // When using predefined values
    python3 plot_scalability.py -f "file1" "file2" ...  // When using predefined path, but given files
    python3 plot_scalability.py -f "file1" "file2" ... -p "path"  // When using given path and files
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import os
import sys
import warnings
import argparse
from scipy.optimize import curve_fit


columns = ["Line Marker", "dofs", "elements", "partitions", "norm", "total CPU time (s)",
           "simulation CPU time (s)", "simulation real time (s)", "linsys CPU time (s)",
           "linsys real time (s)", "solver CPU time (s)", "solver real time (s)",
           "MeshLevel"]

use_time = "linsys CPU time (s)"  # Must be listed in columns

colors = iter(mcolors.TABLEAU_COLORS.keys())

# Initialize the figure in global scope
plt.figure()


################# PREDEFINED ####################

# Predefined .dat files that the code will look for if nothing is passed as argument
dat_files = ["f2.dat"]

# Change directory to predefined location from where the results can be read
# (in this case WinkelStructed/results)
cwd_arr = os.getcwd().split('/')
cwd_arr[-1] = "Poisson/WinkelStructured/results"
os.chdir('/'.join(cwd_arr))

#################################################


# Function for manually going through the dat_file.marker file containing the solver names as splitting
# it directly with ':' as separator might not work as the solvers name also contains it
def read_markers(dat_file):
    filename = f"{dat_file}.marker"
    solvers = []
    with open(filename) as file:
        for line in file:
            solvers.append(line.strip().split(': ', 1)[1])

    return solvers


def read_and_plot(dat_file):
    data = pd.read_table(dat_file, delim_whitespace=True, header=None)

    solvers = read_markers(dat_file)

    data.columns = columns
    data['Solver'] = solvers

    # Drop the solver if it failed with any mesh level
    # This is relatively poor way of evaluating the correctness
    # of the solution and should be rewritten
    median = np.median(data['norm'].values)
    data = data[np.isclose(data['norm'], median, atol=0.1)]

    if len(data) != len(solvers):
        print(f"WARNING: Solver {solvers[0]} had incorrect solution")
        return

    times = data[use_time].values.tolist()
    dofs = data['dofs'].values / 1_000_000  # Unit should be 1M dofs

    # Fit an exponential to the given datapoints
    curve_found = False
    try:
        popt, pcov = curve_fit(lambda n, a, b: a * n ** b, dofs, times)
    except RuntimeError:
       print(f"WARNING: Could not fit a curve to the datapoints of solver {solvers[0]}. Plotting just the points.")
    else:
        x = np.linspace(np.min(dofs), np.max(dofs), 100)
        y = popt[0] * x ** popt[1]
        curve_found = True

    color = next(colors)

    plt.loglog(dofs, times, color=color, marker='o', linestyle='None', mfc='none', alpha=0.7,
               label=f"Datapoints for solver: {data['Solver'][0]}")
    
    if curve_found:
        plt.loglog(x, y, color=color, alpha=0.5,
                   label=f"Found exponential: $({popt[0]:.2e}) \cdot n ^ {{{popt[1]:.2e}}}$")


def main():
    # Python generally understands the global scope here without special declaration, but it is added just to be sure
    global dat_files  
    
    if len(sys.argv) > 1:
        parser = argparse.ArgumentParser()
        parser.add_argument('-p', '--path', type=str)
        parser.add_argument('-f', '--files', nargs='*', type=str)
        args = parser.parse_args()

        if args.path is not None:
            os.chdir(args.path)

        if args.files is not None:
            dat_files = args.files      

    for dat_file in dat_files:
        read_and_plot(dat_file)
        
    plt.ylabel(use_time)
    plt.xlabel("#dofs (in millions) = $n$")
    plt.legend()
    plt.show()
    

main()

