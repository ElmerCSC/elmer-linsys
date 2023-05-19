"""
Basic Python script that finds and plots the "scaling coefficients" for all solvers in a given file 
The file should contain data for multiple mesh levels

This script has three optional passable cmd args
   1. -f (--file) for using a different file than the one predefined
   2. -p (--path) for using a different path than the one predefined
   4. -i (--ignore) for ignoring solvers with highest mesh level lower than the one passed as argument 
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


# Function for computing the mode of a list of floating point values with a given tolerance
def float_mode(vals, tol=10 ** (-6)):
    count = -1
    mode = -1
    while len(vals) > 0:
        val = vals[0]
        within_tol = np.isclose(vals, val, atol=tol)
        c = within_tol.sum()
        if c >= count:
            mode = val
            count = c

        vals = vals[np.invert(within_tol)]

    return mode
        

# Function for computing the scaling coefficient b from equation t = a * n ^ b for a given solver
def comp_coef(times, n_dofs):
    try:
        popt, pcov = curve_fit(lambda n, a, b: a * n ** b, n_dofs, times)
    except (RuntimeError, TypeError):
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
        mode = float_mode(temp['norm'].values)
        temp = temp[~np.isclose(temp['norm'], mode, atol=10 ** (-6))]
        ret += temp['Solver'].values.tolist()

    return ret


def main():
    global dat_filename  # Python isn't smart enough so this needs to be declared
    ignore_mesh_level = None
    
    if len(sys.argv) > 1:
        parser = argparse.ArgumentParser()
        parser.add_argument('-p', '--path', type=str)
        parser.add_argument('-f', '--file', type=str)
        parser.add_argument('-i', '--ignore', type=int)
        args = parser.parse_args()

        if args.path is not None:
            os.chdir(args.path)

        if args.file is not None:
            dat_filename = args.file

        if args.ignore is not None:
            ignore_mesh_level = float(args.ignore)
        
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

        temp = grouped[grouped['Solver'] == solver]
        
        times = temp[use_time].values.tolist()
        dofs = temp['dofs'].values / 1_000_000  # Unit should be 1M dofs

        if ignore_mesh_level is not None and max(temp['MeshLevel'].values) < ignore_mesh_level:
            continue

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
    ax.set_title(f"Scaling coefs for {'-'.join(os.getcwd().split('/')[-3:-1])} ({data['partitions'][0]} partitions)")

    plt.show()


main()
