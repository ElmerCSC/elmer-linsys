"""
Compares the energy consumed by the linear solver phase only (not the whole simulation) between
Roihu's CPU (Hypre/Elmer) solver and GPU (AMGX) solver, for a fixed mesh/density.

Energy is estimated as:

    Energy (kWh) = node_power (W) * num_nodes * linsys_real_time (s) / 3.6e6

using each node's rated max power (TDP-based, "running at maximum") and the "linsys real time"
column (wall-clock time spent in the linear solve), NOT "linsys cpu time" (aggregated per-process
CPU time) or the whole-simulation time -- this isolates the solver's own energy use.

Both CPU partition counts and GPU partition counts are converted to physical NODE counts
(CPU: partitions / cores-per-node, GPU: explicit -gnodes) before computing energy. Unlike the
timing comparison (compare_roihu_cpu_gpu_times.py), this makes the two series genuinely
comparable on one shared x-axis, since "number of nodes" is the same physical unit for both.

Expects, for both the CPU and GPU side, one subdirectory per partition count following the
naming convention used by vizualize.sh: <path>/Navier-WinkelStructured-partitions-<n>/f<n>.dat
(plus the matching .dat.marker/.dat.names files written by Elmer's SaveScalars solver).

The CPU .dat files may contain more than one solver appended together (e.g. "cg + ilu0" and
"hypre: bicgstab + parasails") -- pass -cs/--cpu_solver to select which one to plot; rows
belonging to other solvers are ignored.

Usage:
    python3 compare_roihu_cpu_gpu_energy.py
    python3 compare_roihu_cpu_gpu_energy.py -cp path/to/cpu -gp path/to/gpu -cparts 1536 3072 6144 -gparts 12 16 24 -gnodes 3 4 6 -s energy.png

The optional passable cmd args
    1. -cp     (--cpu_path) path to the directory holding the CPU partitions-<n> subdirectories
    2. -gp     (--gpu_path) path to the directory holding the GPU partitions-<n> subdirectories
    3. -cparts (--cpu_partitions) list of CPU partition counts
    4. -gparts (--gpu_partitions) list of GPU partition counts, used to locate each f<n>.dat file
    5. -gnodes (--gpu_nodes) list of GPU node counts, one per entry in -gparts
    6. -cnpn   (--cpu_cores_per_node) CPU cores per node, used to convert -cparts into node counts
    7. -cpw    (--cpu_node_power) assumed max power draw of one CPU node, in watts
    8. -gpw    (--gpu_node_power) assumed max power draw of one GPU node, in watts
    9. -cs     (--cpu_solver) substring identifying which solver's rows to use from the CPU files
   10. -t      (--tolerance) tolerance used when checking that the norm is consistent between repeated runs
   11. -s      (--save_as) path to where the figure should be saved. If not passed the figure will be visualized
   12. -c      (--test_case) name of the test case shown in the figure title
"""

import argparse
import os

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import NullFormatter

from tools.tools import read_names, read_markers, float_mode

################# PREDEFINED ####################

time_col = "linsys real time"  # The measured time of interest (wall-clock time in the solver)
norm_col = "norm"  # The norm of interest
element_col = "elements"  # The number of elements in the mesh

# Predefined paths used if nothing is passed on the command line
cpu_path = "../results_2026/roihu/Navier-CPU/mesh-3-density-015"
gpu_path = "../results_2026/roihu/Navier-AMGX/mesh-3-density-015"

# Predefined partition counts, each corresponding to a Navier-WinkelStructured-partitions-<n> dir
cpu_partitions = [1536, 3072, 6144]
gpu_partitions = [12, 16, 24]

# Predefined GPU node counts, one per entry in gpu_partitions
gpu_nodes = [3, 4, 6]

# Predefined CPU cores per node, used to convert cpu_partitions into node counts
cpu_cores_per_node = 384

# Predefined assumed max power draw per node, in watts (see conversation/README for sourcing):
# - CPU node: 2x AMD EPYC 9965 (Turin) @ 500 W TDP each = 1000 W (compute-only, excludes RAM/NIC/etc.)
# - GPU node: 4x NVIDIA GH200 Grace Hopper Superchip @ ~1000 W each = 4000 W (compute-only)
cpu_node_power = 1000.0
gpu_node_power = 4000.0

# Predefined CPU solver to filter for (the CPU files may contain more than one solver)
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


def energy_kwh(power_w, n_nodes, real_time_s):
    return power_w * n_nodes * real_time_s / 3.6e6


def main():
    global cpu_path, gpu_path, cpu_partitions, gpu_partitions, gpu_nodes, cpu_cores_per_node
    global cpu_node_power, gpu_node_power, cpu_solver, tolerance, test_case

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-cp', '--cpu_path', type=str, default=cpu_path)
    parser.add_argument('-gp', '--gpu_path', type=str, default=gpu_path)
    parser.add_argument('-cparts', '--cpu_partitions', nargs='*', type=int, default=cpu_partitions)
    parser.add_argument('-gparts', '--gpu_partitions', nargs='*', type=int, default=gpu_partitions)
    parser.add_argument('-gnodes', '--gpu_nodes', nargs='*', type=int, default=gpu_nodes)
    parser.add_argument('-cnpn', '--cpu_cores_per_node', type=int, default=cpu_cores_per_node)
    parser.add_argument('-cpw', '--cpu_node_power', type=float, default=cpu_node_power)
    parser.add_argument('-gpw', '--gpu_node_power', type=float, default=gpu_node_power)
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
    cpu_cores_per_node = args.cpu_cores_per_node
    cpu_node_power = args.cpu_node_power
    gpu_node_power = args.gpu_node_power
    cpu_solver = args.cpu_solver
    tolerance = args.tolerance
    test_case = args.test_case

    if len(gpu_nodes) != len(gpu_partitions):
        raise ValueError("-gnodes must have the same number of entries as -gparts")

    for p in cpu_partitions:
        if p % cpu_cores_per_node != 0:
            print(f"WARNING: {p} CPU partitions is not evenly divisible by "
                  f"{cpu_cores_per_node} cores/node; rounding down to {p // cpu_cores_per_node} nodes")

    cpu_nodes = [p // cpu_cores_per_node for p in cpu_partitions]

    elements = None

    cpu_energies = []
    for n, nodes in zip(cpu_partitions, cpu_nodes):
        real_time, elements = read_time(cpu_path, n, tolerance, solver_filter=cpu_solver)
        cpu_energies.append(energy_kwh(cpu_node_power, nodes, real_time))

    gpu_energies = []
    for n, nodes in zip(gpu_partitions, gpu_nodes):
        real_time, elements = read_time(gpu_path, n, tolerance)
        gpu_energies.append(energy_kwh(gpu_node_power, nodes, real_time))

    print(f"Assumed max power: CPU {cpu_node_power:.0f} W/node, GPU {gpu_node_power:.0f} W/node")

    print(f"CPU ({cpu_solver}), linear solver energy:")
    for nodes, e in zip(cpu_nodes, cpu_energies):
        print(f"  {nodes:<6} nodes: {e:.3f} kWh")

    print("GPU (AMGX), linear solver energy:")
    for nodes, e in zip(gpu_nodes, gpu_energies):
        print(f"  {nodes:<6} nodes: {e:.3f} kWh")

    print("Energy ratio CPU/GPU at matching (or nearest) node counts (>1 means GPU used less energy):")
    for cnodes, ce in zip(cpu_nodes, cpu_energies):
        for gnodes, ge in zip(gpu_nodes, gpu_energies):
            print(f"  CPU@{cnodes} nodes vs GPU@{gnodes} nodes: {ce / ge:.2f}x")

    fig, ax = plt.subplots(figsize=(10, 6))

    ax.plot(cpu_nodes, cpu_energies, marker='o', color='tab:blue', label=f"CPU ({cpu_solver})")
    ax.plot(gpu_nodes, gpu_energies, marker='s', color='tab:orange', label="GPU (AMGX)")

    ax.set_xscale('log')
    ax.set_xlabel("Number of nodes")
    ax.set_ylabel("Linear solver energy (kWh)")
    ax.grid(True, which='both', alpha=0.3)
    set_plain_number_ticks(ax, sorted(set(cpu_nodes) | set(gpu_nodes)))

    ax.legend()
    ax.set_title(f"{test_case}: linear solver energy, CPU vs GPU at rated max power (Elements: {int(elements)})")

    plt.tight_layout()

    if args.save_as is not None:
        plt.savefig(args.save_as)
    else:
        plt.show()


if __name__ == "__main__":
    main()
