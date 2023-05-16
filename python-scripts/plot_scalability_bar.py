"""
Basic Python script that finds and plots the "scaling coefficients" for all solvers in a given file 
The file should contain data for multiple mesh levels

Usage is: 
    python3 plot_scalability_bar.py   // When using predefined values
    python3 plot_scalability_bar.py -f "file"  // When using predefined path, but given file
    python3 plot_scalability_bar.py -f "file" -p "path"  // When using given path and file
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import sys
import argparse
from scipy.optimize import curve_fit


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
cwd_arr[-1] = "Poisson/WinkelStructured/results"
os.chdir('/'.join(cwd_arr))

#################################################


# Function for computing the scaling coefficient b from equation t = a * n ^ b for a given solver
def comp_coef(times, n_dofs):
    try:
        popt, pcov = curve_fit(lambda n, a, b: a * n ** b, n_dofs, times)
    except RuntimeError:
        return None
    else:
        return popt[1]
    

# Function for manually going through the dat_file.marker file containing the solver names as splitting
# it directly with ':' as separator might not work as the solvers name could also contain it
def read_markers(dat_file):
    filename = f"{dat_file}.marker"
    solvers = []
    with open(filename) as file:
        for line in file:
            solvers.append(line.strip().split(': ', 1)[1])

    return solvers


def failed_solvers(data):
    ret = []
    for mesh_level in data['MeshLevel'].unique():
        temp = data[data['MeshLevel'] == mesh_level]
        # Find the median of the norm values and remove the rows where the
        # norm varies significantly
        median = np.median(temp['norm'].values)  # Might need to be changed to mode if floating point error can be handled
        temp = temp[~np.isclose(temp['norm'], median, atol=10 ** (-6))]
        ret += temp['Solver'].values.tolist()

    return ret


def main():
    global dat_filename  # Python isn't smart enough so this needs to be declared
    
    if len(sys.argv) > 1:
        parser = argparse.ArgumentParser()
        parser.add_argument('-p', '--path', type=str)
        parser.add_argument('-f', '--file', type=str)
        args = parser.parse_args()

        if args.path is not None:
            os.chdir(args.path)

        if args.file is not None:
            dat_filename = args.file
        
    data = pd.read_table(dat_filename, delim_whitespace=True, header=None)
    solvers = read_markers(dat_filename)

    data.columns = columns
    data['Solver'] = solvers

    # Drop the row if the solver failed
    remove_solvers = list(set(failed_solvers(data)))

    if len(remove_solvers) != 0:
        data = data[~data['Solver'].isin(remove_solvers)]
        print(f"WARNING: Solvers: {', '.join(remove_solvers)} had incorrect solution")

    grouped = data.groupby('Solver', group_keys=True).apply(lambda x: x)

    successful_solvers = []
    coefs = []

    for solver in data['Solver'].values:
        times = grouped[grouped['Solver'] == solver][use_time].values.tolist()
        dofs = grouped[grouped['Solver'] == solver]['dofs'].values / 1_000_000  # Unit should be 1M dofs

        ret = comp_coef(times, dofs)

        if ret is not None:
            successful_solvers.append(solver)
            coefs.append(ret)

        else:
            print(f"WARNING: Could not fit a curve to the datapoints of solver {solver}. Ignoring the solver.")

    zipped = list(zip(successful_solvers, coefs))
    zipped.sort(key=lambda tup: tup[1])

    # Plot the coefs as a barplot
    fig, ax = plt.subplots()
    bars = ax.barh([solver for solver, coef in zipped], [coef for solver, coef in zipped])
    ax.bar_label(bars)
    ax.set_ylabel("Solver")
    ax.set_xlabel(f"$b$ solved from: $t = a \cdot  n ^ b$")
    ax.set_title(f"Scaling coefficients ({data['partitions'][0]} partitions)")

    plt.show()


main()
