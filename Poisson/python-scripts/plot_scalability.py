"""
Basic Python script that plots the execution times of a given linear solver as a function of the number of elements and fits an exponential to it
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
from scipy.optimize import curve_fit


# Change directory to WinkelStructured/results to access the .dat files
print(os.getcwd())
cwd_arr = os.getcwd().split('/')
cwd_arr[-1] = "WinkelStructured/results"
os.chdir('/'.join(cwd_arr))

columns = ["Line Marker", "dofs", "elements", "partitions", "norm", "total CPU time (s)",
           "simulation CPU time (s)", "simulation real time (s)", "linsys CPU time (s)",
           "linsys real time (s)", "solver CPU time (s)", "solver real time (s)",
           "MeshLevel"]

lin_method_id = 2
use_time = "linsys CPU time (s)"  # Must be listed in columns


def main():
    data = pd.read_table(f"f{lin_method_id}.dat", delim_whitespace=True, header=None)
    markers = pd.read_table(f"f{lin_method_id}.dat.marker", sep=':', header=None)

    solver = markers[1].values.tolist()

    data.columns = columns
    data['Solver'] = solver

    # Drop the row if the solver failed
    data = data[data['norm'] != 0.0]

    times = data[use_time].values.tolist()
    elements = data['elements'].values.tolist()

    # Fit an exponential to the given datapoints
    popt, pcov = curve_fit(lambda n, a, b: a * n ** b, elements, times)
    x = np.linspace(np.min(elements), np.max(elements), 100)
    y = popt[0] * x ** popt[1]

    # Plot the datapoints and fitted exponential
    plt.figure()
    plt.loglog(x, y, 'k', label=f"Found exponential: $({popt[0]:.2e}) \cdot n ^ {{{popt[1]:.2e}}}$")
    plt.loglog(elements, times, 'r.', label="Datapoints")
    plt.ylabel(use_time)
    plt.xlabel("#Elements = $n$")
    plt.title(f"Solver: {data['Solver'][0]}")  # Assumes that the file contains results for only one solver
    plt.legend()
    plt.show()
    

main()

