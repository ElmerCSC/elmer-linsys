"""
Basic Python script that plots the execution times of all solvers with a given mesh level
There are two ways for running this script. Either the required information can be provided
from the command line (see this docstring) or the information can be predefined (see PREDEFINED)
The values passed on the command line will override the predefined ones. 

To plot the valid values all of the files (*.dat, *.dat.marker, *.dat.names) written by the 
SaveScalars function in Elmer needs to be available in the same directory. Additionally,
user must specify the columns of interest in the *.dat.names file by providing unambigous substrings
defining them in the PREDEFINED section.

The optional passable cmd args
   1. -f (--file) for using a different file than the one predefined
   2. -p (--path) for using a different path than the one predefined
   3. -v (--viz_total_time) for plotting the total time as well (the flag is enough)
   4. -m (--mesh_level) for choosing the wanted mesh level if selected file contains multiple
   5. -s (--save_as) for defining the filename as which the figure will be saved. If not passed the figure will be visualized
   6. -t (--tolerance) for defining the tolerance used in float mode and numpy.isclose

Note it is not recommended to plot total times as well if file contains results for a large number of solvers
as the figure will get very crowded
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import sys
from tools.tools import *
from tools.parser import *


################# PREDEFINED ####################

# Substrings defining the column names with wanted values
time_col = "linsys cpu time"  # The measured time of interest
tot_time_col = "value: cpu time"  # Total time
norm_col = "norm"  # The norm of interest
partition_col = "partitions"  # The number of partitions used
mesh_level_col = "expression 1"  # The used mesh level
dof_col = "dofs"  # The number of degrees of freedom

# Predefine this if P-multigrid was used. Ignore otherwise
p_level_col = "_______"

# Predefined .dat files that the code will look for if nothing is passed as argument
dat_filename = "f.dat"

# Predefined tolerance used in float mode and other functions
tolerance = 10 ** (-6)

# Change directory to predefined location from where the results can be read
# (in this case WinkelStructed/results)
org_cwd = os.getcwd()
cwd_arr = os.getcwd().split('/')
cwd_arr[-1] = "Poisson/WinkelUnstructured/results"
os.chdir('/'.join(cwd_arr))

#################################################


def main():
    global time_col, norm_col, partition_col, mesh_level_col, tot_time_col, dof_col, p_level_col
    global dat_filename, viz_total_time, tolerance
    
    mesh_level = None  # Specifies the mesh level of which results are plotted
    viz_total_time = None  # Flag telling if total times should be plotted as well
    save_as = None  # Path to where the figure should be saved
    
    if len(sys.argv) > 1:
        args = parse_cmd()

        if args['path'] is not None:
            os.chdir(args['path'])

        if args['file'] is not None:
            dat_filename = args['file']

        if args['mesh_level'] is not None:
            mesh_level = float(args['mesh_level'])

        if args['tolerance'] is not None:
            tolerance = args['tolerance']

        if args['save_as'] is not None:
            save_as = args['save_as']

        viz_total_time = args['viz_total_time']
        
    data = pd.read_table(dat_filename, delim_whitespace=True, header=None)
    solvers = read_markers(dat_filename)

    column_names = read_names(dat_filename)

    time_col = [s for s in column_names if time_col in s][0]
    tot_time_col = [s for s in column_names if tot_time_col in s][0]
    norm_col = [s for s in column_names if norm_col in s][0]
    partition_col = [s for s in column_names if partition_col in s][0]
    mesh_level_col = [s for s in column_names if mesh_level_col in s][0]
    dof_col = [s for s in column_names if dof_col in s][0]

    data.columns = column_names
    data['Solver'] = solvers

    # Check for P-values
    try:
        p_level_col = [s for s in column_names if p_level_col in s][0]
    except:
        pass
    else:
        # Add the p-values to solver names
        data['Solver'] = data['Solver'] + " + P{" + data[p_level_col].astype(str) + "}"
        

    # Find the most common mesh level value and drop all rows with different mesh level
    # if no chosen mesh level was passed
    if mesh_level is None:
        mesh_level = data[mesh_level_col].mode()[0]

    data = data[data[mesh_level_col] == float(mesh_level)]

    dofs = data[dof_col].iloc[0]

    solvers = data['Solver'].values
    n_solvers = len(solvers)

    # Find the mode of the norm values and remove the rows where the
    # norm varies significantly
    mode = float_mode(data[norm_col].values, tol=tolerance)
    data = data[np.isclose(data[norm_col], mode, atol=tolerance)]

    if len(data) != n_solvers:
        print(f"WARNING: Solver(s): {', '.join(list(set(solvers).difference(set(data['Solver'].values.tolist()))))} had incorrect solution")

    data.sort_values(by=[time_col], ascending=True, inplace=True)

    use_times = data[time_col].values
    total_times = data[tot_time_col].values
    solvers = data['Solver'].values

    y_axis = np.linspace(0, len(solvers), len(solvers))

    # Plot the times as a barplot
    fig, ax = plt.subplots(figsize=(12, 6))

    if viz_total_time:
        total_time_bars = ax.barh(y_axis + 0.2, total_times, 0.4, label=tot_time_col)
        use_time_bars = ax.barh(y_axis - 0.2, use_times, 0.4, label=time_col)
        ax.bar_label(use_time_bars)
        ax.bar_label(total_time_bars)

    else:
        use_time_bars = ax.barh(y_axis, use_times, label=time_col)
        ax.bar_label(use_time_bars)

    ax.set_yticks(y_axis, solvers)
    ax.set_ylabel("Solver")
    ax.set_xlabel("Time (s)")
    ax.set_title(f"Runtimes for {'-'.join(os.getcwd().split('/')[-3:-1])} with DOFs: {dofs} ({data[partition_col].iloc[0]} partitions)")
    ax.legend(loc='lower right')

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
    
