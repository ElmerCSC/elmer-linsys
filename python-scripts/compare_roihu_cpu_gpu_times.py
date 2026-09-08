"""
Compares the "linsys cpu time" scaling of the CPU (Hypre/Elmer) solver against the GPU (AMGX)
solver on Roihu, for a fixed mesh/density.

Expects, for both the CPU and GPU side, one subdirectory per partition count following the
naming convention used by vizualize.sh: <path>/Navier-WinkelStructured-partitions-<n>/f<n>.dat
(plus the matching .dat.marker/.dat.names files written by Elmer's SaveScalars solver).

The CPU .dat files may contain more than one solver appended together (e.g. "cg + ilu0" and
"hypre: bicgstab + parasails") -- pass -cs/--cpu_solver to select which one to plot; rows
belonging to other solvers are ignored.

CPU partition counts and GPU node counts are different units with no inherent equivalence (a
"partition" is an MPI task on the CPU side; a GPU node here runs several MPI tasks per node).
Both series are drawn on one plot, but each gets its own independently-scaled x-axis (CPU on the
bottom, GPU on top) -- the two axes are positionally overlaid for compactness only; a given x
position does NOT mean the CPU and GPU values there are an equivalent amount of resources.

Usage:
    python3 compare_roihu_cpu_gpu_times.py
    python3 compare_roihu_cpu_gpu_times.py -cp path/to/cpu -gp path/to/gpu -cparts 1536 3072 6144 -gparts 12 16 24 -gnodes 3 4 6 -s comparison.png

The optional passable cmd args
   1. -cp     (--cpu_path) path to the directory holding the CPU partitions-<n> subdirectories
   2. -gp     (--gpu_path) path to the directory holding the GPU partitions-<n> subdirectories
   3. -cparts (--cpu_partitions) list of CPU partition counts to plot on the x-axis
   4. -gparts (--gpu_partitions) list of GPU partition counts, used to locate each f<n>.dat file
   5. -gnodes (--gpu_nodes) list of GPU node counts, one per entry in -gparts; plotted on the GPU subplot's x-axis
   6. -cs     (--cpu_solver) substring identifying which solver's rows to use from the CPU files
   7. -t      (--tolerance) tolerance used when checking that the norm is consistent between repeated runs
   8. -s      (--save_as) path to where the figure should be saved. If not passed the figure will be visualized
   9. -c      (--test_case) name of the test case shown in the figure title
"""

import argparse
import os

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import NullFormatter

from tools.tools import read_names, read_markers, float_mode

################# PREDEFINED ####################

time_col = "linsys cpu time"  # The measured time of interest
norm_col = "norm"  # The norm of interest
element_col = "elements"  # The number of elements in the mesh

# Predefined paths used if nothing is passed on the command line
cpu_path = "../results_2026/roihu/Navier-CPU/mesh-3-density-015"
gpu_path = "../results_2026/roihu/Navier-AMGX/mesh-3-density-015"

# Predefined partition counts, each corresponding to a Navier-WinkelStructured-partitions-<n> dir
cpu_partitions = [1536, 2304, 3072, 6144]
gpu_partitions = [12, 16, 24, 32]

# Predefined GPU node counts, one per entry in gpu_partitions, plotted on the GPU subplot's x-axis
gpu_nodes = [3, 4, 6, 8]

# Predefined CPU solver to filter for (the .dat files may contain more than one solver)
cpu_solver = "cg + ilu0"

# Predefined tolerance used in float mode and numpy.isclose
tolerance = 10 ** (-6)

# Predefined test case name shown in the figure title
test_case = "Navier-WinkelStructured"

#################################################


def set_plain_number_ticks(ax, values):
    """Force an x-axis to show the exact data values as plain (non-scientific) tick labels."""
    ax.set_xticks(values)
    ax.set_xticklabels([str(v) for v in values])
    ax.xaxis.set_minor_formatter(NullFormatter())


def dat_file_path(path, n):
    return os.path.join(path, f"Navier-WinkelStructured-partitions-{n}", f"f{n}.dat")


def read_time(path, n, tol, solver_filter=None):
    dat_file = dat_file_path(path, n)

    column_names = read_names(dat_file)
    data = pd.read_table(dat_file, sep=r"\s+", header=None)
    data.columns = column_names
    data['Solver'] = read_markers(dat_file)

    if solver_filter is not None:
        data = data[data['Solver'].str.contains(solver_filter, regex=False)]

    time_column = [c for c in column_names if time_col in c][0]
    norm_column = [c for c in column_names if norm_col in c][0]
    element_column = [c for c in column_names if element_col in c][0]

    # Drop rows where the norm deviates from the mode, i.e. runs with an incorrect solution
    mode = float_mode(data[norm_column].values, tol=tol)
    data = data[np.isclose(data[norm_column], mode, atol=tol)]

    return data[time_column].mean(), data[element_column].iloc[0]


def main():
    global cpu_path, gpu_path, cpu_partitions, gpu_partitions, gpu_nodes, cpu_solver, tolerance, test_case

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-cp', '--cpu_path', type=str, default=cpu_path)
    parser.add_argument('-gp', '--gpu_path', type=str, default=gpu_path)
    parser.add_argument('-cparts', '--cpu_partitions', nargs='*', type=int, default=cpu_partitions)
    parser.add_argument('-gparts', '--gpu_partitions', nargs='*', type=int, default=gpu_partitions)
    parser.add_argument('-gnodes', '--gpu_nodes', nargs='*', type=int, default=gpu_nodes)
    parser.add_argument('-cs', '--cpu_solver', type=str, default=cpu_solver)
    parser.add_argument('-t', '--tolerance', type=float, default=tolerance)
    parser.add_argument('-s', '--save_as', type=str)
    parser.add_argument('-c', '--test_case', type=str, default=test_case)
    args = parser.parse_args()

    cpu_path = args.cpu_path
    gpu_path = args.gpu_path
    cpu_partitions = args.cpu_partitions
    gpu_partitions = args.gpu_partitions
    gpu_nodes = args.gpu_nodes
    cpu_solver = args.cpu_solver
    tolerance = args.tolerance
    test_case = args.test_case

    if len(gpu_nodes) != len(gpu_partitions):
        raise ValueError("-gnodes must have the same number of entries as -gparts")

    elements = None

    cpu_times = []
    for n in cpu_partitions:
        cpu_time, elements = read_time(cpu_path, n, tolerance, solver_filter=cpu_solver)
        cpu_times.append(cpu_time)

    gpu_times = []
    for n in gpu_partitions:
        gpu_time, elements = read_time(gpu_path, n, tolerance)
        gpu_times.append(gpu_time)

    print(f"CPU ({cpu_solver}):")
    for n, t in zip(cpu_partitions, cpu_times):
        print(f"  {n:<6} partitions: {t:.2f} s")

    print("GPU (AMGX):")
    for nodes, t in zip(gpu_nodes, gpu_times):
        print(f"  {nodes:<6} nodes: {t:.2f} s")

    print("Speedup of GPU vs CPU (>1 means GPU is faster):")
    for nodes, gt in zip(gpu_nodes, gpu_times):
        for cn, ct in zip(cpu_partitions, cpu_times):
            print(f"  GPU@{nodes} nodes vs CPU@{cn} partitions: {ct / gt:.2f}x")

    fig, ax = plt.subplots(figsize=(10, 6))

    ax.plot(gpu_nodes, gpu_times, marker='s', color='tab:orange', label="GPU (AMGX)")
    ax.set_xscale('log')
    ax.set_yscale('log')
    ax.set_xlabel("Number of GPU nodes")
    ax.set_ylabel(f"{time_col} (s)")
    ax.grid(True, which='both', alpha=0.3)
    set_plain_number_ticks(ax, gpu_nodes)

    # CPU partitions and GPU nodes are different units (see docstring), so the CPU line gets
    # its own x-axis (top) overlaid on the same plot rather than sharing the GPU x-axis.
    ax2 = ax.twiny()
    ax2.plot(cpu_partitions, cpu_times, marker='o', color='tab:blue', label=f"CPU ({cpu_solver})")
    ax2.set_xscale('log')
    ax2.set_xlabel("Number of CPU partitions")
    set_plain_number_ticks(ax2, cpu_partitions)

    lines, labels = ax2.get_legend_handles_labels()
    lines2, labels2 = ax.get_legend_handles_labels()
    ax.legend(lines + lines2, labels + labels2)

    ax.set_title(f"{test_case}: CPU vs GPU linsys cpu time (Elements: {int(elements)})")

    plt.tight_layout()

    if args.save_as is not None:
        plt.savefig(args.save_as)
    else:
        plt.show()


if __name__ == "__main__":
    main()
