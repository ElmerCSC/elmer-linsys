"""
Basic Python script that finds and plots the slope associated with Gustafson's law of weak scaling for multiple 
solvers on multiple different partition counts but on the same problem

This script has two optional passable cmd args
   1. -f (--file) for using a different file than the one predefined
   2. -p (--path) for using a different path than the one predefined
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
dat_filename = "f_ml4.dat"

# Change directory to predefined location from where the results can be read
# (in this case WinkelStructed/results)
cwd_arr = os.getcwd().split('/')
cwd_arr[-1] = "Poisson/WinkelUnstructured/results"
os.chdir('/'.join(cwd_arr))

#################################################


# Function for computing the mode of a list of floating point values with a given tolerance
def float_mode(vals, tol=10 ** (-6)):
    count = -1
    mode = -1

    # Iterate at most len(vals) number of times
    max_iter = len(vals)
    i = 0
    
    while len(vals) > 0:
        if i >= max_iter:
            break
        
        val = vals[0]
        within_tol = np.isclose(vals, val, atol=tol)
        c = within_tol.sum()
        if c >= count:
            mode = val
            count = c

        vals = vals[np.invert(within_tol)]
        
        i += 1

    return mode
        

# Function for computing the scaling coefficient b from equation speedup = s + p * N for a given solver
def comp_slope(speedups, partitions):
    try:
        popt, pcov = curve_fit(lambda N, s, p: s + p * N, partitions, speedups)
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
    for partitions in data['partitions'].unique():
        temp = data[data['partitions'] == partitions]
        # Find the median of the norm values and remove the rows where the
        # norm varies significantly
        mode = float_mode(temp['norm'].values)
        temp = temp[~np.isclose(temp['norm'], mode, atol=10 ** (-6))]
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
    slopes = []

    for solver in np.unique(data['Solver'].values):
        temp = grouped[grouped['Solver'] == solver]
        
        times = temp[use_time].values
        partitions = temp['partitions'].values

        min_partition = np.argmin(partitions)

        speedups = times[min_partition] / times

        partitions = partitions / partitions[min_partition]

        ret = comp_slope(speedups, partitions)

        if ret is not None:
            successful_solvers.append(solver)
            slopes.append(ret)

        else:
            print(f"WARNING: Could not fit a curve to the datapoints of solver {solver}. Ignoring the solver.")

    zipped = list(zip(successful_solvers, slopes))
    zipped.sort(key=lambda tup: tup[1], reverse=True)

    # Plot the coefs as a barplot
    fig, ax = plt.subplots()
    bars = ax.barh([solver for solver, slope in zipped], [slope for solver, slope in zipped])
    ax.bar_label(bars)
    ax.set_ylabel("Solver")
    ax.set_xlabel(f"Scaled $p$ solved from: $speedup = s +  p \cdot N$")
    ax.set_title(f"Slopes for {'-'.join(os.getcwd().split('/')[-3:-1])} (Mesh Level: {int(data['MeshLevel'].iloc[0])})")

    plt.show()


main()
