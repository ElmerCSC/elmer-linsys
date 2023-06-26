"""
Basic Python script that finds and plots the "scaling coefficients" for all solvers in a given file 
The file should contain data for multiple mesh levels

This script has three optional passable cmd args
   1. -f (--file) for using a different file than the one predefined
   2. -p (--path) for using a different path than the one predefined
   3. -i (--ignore) for ignoring solvers with highest mesh level lower than the one passed as argument
   4. -s (--save_as) for defining the filename as which the figure will be saved. If not passed the figure will be visualized
   5. -t (--tolerance) for defining the tolerance used in float mode and numpy.isclose
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import sys
import argparse
from scipy.optimize import curve_fit
from tools.tools import *
from tools.parser import *

################# PREDEFINED ####################

# Substrings defining the column names with wanted values
time_col = "linsys cpu"  # The measured time of interest
norm_col = "norm"  # The norm of interest
partition_col = "partitions"  # The number of partitions used
dof_col = "dofs"  # The number of degrees of freedom
mesh_level_col = "expression"  # The used mesh level

# Predefined .dat files that the code will look for if nothing is passed as argument
dat_filename = "f.dat"

# Change directory to predefined location from where the results can be read
# (in this case WinkelStructed/results)
org_cwd = os.getcwd()
cwd_arr = os.getcwd().split('/')
cwd_arr[-1] = "Poisson/WinkelStructured/results"
os.chdir('/'.join(cwd_arr))

#################################################
        

# Function for computing the scaling coefficient b from equation t = a * n ^ b for a given solver
def comp_coef(times, n_dofs):
    try:
        popt, pcov = curve_fit(lambda n, a, b: a * n ** b, n_dofs, times)
    except (RuntimeError, TypeError):
        return None
    else:
        return popt[1]


def failed_solvers(data, tol):
    ret = []
    for ml in data[mesh_level_col].unique():
        temp = data[data[mesh_level_col] == ml]
        # Find the mode of the norm values and remove the rows where the
        # norm varies significantly
        mode = float_mode(temp[norm_col].values, tol=tol)
        temp = temp[~np.isclose(temp[norm_col], mode, atol=tol)]
        ret += temp['Solver'].values.tolist()

    return ret


def main():
    global dat_filename, time_col, norm_col, partition_col, dof_col, mesh_level_col
    ignore_mesh_level = None
    save_as = None
    tolerance = 10 ** (-6)
    
    if len(sys.argv) > 1:
        args = parse_cmd()

        if args['path'] is not None:
            os.chdir(args['path'])

        if args['file'] is not None:
            dat_filename = args['file']

        if args['ignore'] is not None:
            ignore_mesh_level = float(args['ignore'])

        if args['tolerance'] is not None:
            tolerance = args['tolerance']

        if args['save_as'] is not None:
            save_as = args['save_as']
        
    data = pd.read_table(dat_filename, delim_whitespace=True, header=None)
    solvers = read_markers(dat_filename)

    column_names = read_names(dat_filename)

    time_col = [s for s in column_names if time_col in s][0]
    norm_col = [s for s in column_names if norm_col in s][0]
    partition_col = [s for s in column_names if partition_col in s][0]
    dof_col = [s for s in column_names if dof_col in s][0]
    mesh_level_col = [s for s in column_names if mesh_level_col in s][0]
    
    data.columns = column_names
    data['Solver'] = solvers

    # Drop the row if the solver failed
    remove_solvers = list(set(failed_solvers(data, tolerance)))

    if len(remove_solvers) != 0:
        data = data[~data['Solver'].isin(remove_solvers)]
        print(f"WARNING: Solvers: {', '.join(remove_solvers)} had incorrect solution")

    grouped = data.groupby('Solver', group_keys=True).apply(lambda x: x)

    successful_solvers = []
    coefs = []

    for solver in data['Solver'].values:

        temp = grouped[grouped['Solver'] == solver]
        
        times = temp[time_col].values.tolist()
        dofs = temp[dof_col].values / 1_000_000  # Unit should be 1M dofs

        if ignore_mesh_level is not None and max(temp[mesh_level_col].values) < ignore_mesh_level:
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
    fig, ax = plt.subplots(figsize=(14, 8))
    bars = ax.barh([solver for solver, coef in zipped], [coef for solver, coef in zipped])
    ax.bar_label(bars)
    ax.set_ylabel("Solver")
    ax.set_xlabel(f"$b$ solved from: $t = a \cdot  n ^ b$")
    ax.set_title(f"Scaling coefs for {'-'.join(os.getcwd().split('/')[-3:-1])} ({data[partition_col][0]} partitions)")

    plt.tight_layout()

    if save_as is not None:
        if len(save_as.split('/')) == 1:
            plt.savefig(str(org_cwd) + '/' + save_as)
        else:
            plt.savefig(save_as)
    else:
        plt.show()

    os.chdir(org_cwd)


if __name__ == "__main__":
    main()
