"""
Basic Python script that plots the execution times for given linear solvers as a function of the number of elements and fits an exponential to it
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import os
import sys
import warnings
from scipy.optimize import curve_fit


# Change directory to WinkelStructured/results to access the .dat files
cwd_arr = os.getcwd().split('/')
cwd_arr[-1] = "WinkelStructured/results"
os.chdir('/'.join(cwd_arr))

columns = ["Line Marker", "dofs", "elements", "partitions", "norm", "total CPU time (s)",
           "simulation CPU time (s)", "simulation real time (s)", "linsys CPU time (s)",
           "linsys real time (s)", "solver CPU time (s)", "solver real time (s)",
           "MeshLevel"]

use_time = "linsys CPU time (s)"  # Must be listed in columns

colors = iter(mcolors.TABLEAU_COLORS.keys())

# Initialize the figure in global scope
plt.figure()


def read_and_plot(dat_file):
    data = pd.read_table(dat_file, delim_whitespace=True, header=None)
    markers = pd.read_table(f"{dat_file}.marker", sep=':', header=None)

    solver = markers[1].values.tolist()

    data.columns = columns
    data['Solver'] = solver

    # Drop the row if the solver failed
    data = data[data['norm'] != 0.0]

    times = data[use_time].values.tolist()
    elements = data['elements'].values.tolist()

    # Fit an exponential to the given datapoints
    curve_found = False
    try:
        popt, pcov = curve_fit(lambda n, a, b: a * n ** b, elements, times)
    except RuntimeError:
        warnings.warn("Could not fit a curve to the datapoints. Plotting just the points.", RuntimeWarning)
    else:
        x = np.linspace(np.min(elements), np.max(elements), 100)
        y = popt[0] * x ** popt[1]
        curve_found = True

    color = next(colors)

    plt.loglog(elements, times, color=color, marker='o', linestyle='None', mfc='none', alpha=0.7,
               label=f"Datapoints for solver: {data['Solver'][0]}")
    if curve_found:
        plt.loglog(x, y, color=color, alpha=0.5,
                   label=f"Found exponential: $({popt[0]:.2e}) \cdot n ^ {{{popt[1]:.2e}}}$")


def main():
    if len(sys.argv) > 1:
        dat_files = sys.argv[1:]
    else:
        # Predefined value. Will be overwritten by passed command line args
        dat_files = ["f2.dat"]

    for dat_file in dat_files:
        read_and_plot(dat_file)
        
    plt.ylabel(use_time)
    plt.xlabel("#Elements = $n$")
    plt.legend()
    plt.show()
    

main()

