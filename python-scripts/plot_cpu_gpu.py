"""
Compares CPU (Hypre) linear system solve time scaling against a fixed GPU (AMGX / Hypre-CUDA)
reference time, for a single mesh level, to see at what CPU partition count the CPU solve time
drops below a one-GPU-run's time.

For the CPU side, every f*.dat file found in --cpu_path is read (together with its matching
.dat.marker/.dat.names files written by Elmer's SaveScalars solver) and concatenated into one
table. The partition count for each row is taken from the "value: number of partitions" column
recorded by Elmer -- not from the filename -- so adding more f<n>.dat files to --cpu_path (e.g.
more partition counts, more repeats) is picked up automatically without any change to this
script. Two CPU solvers are plotted as lines, selected by substring on the marker name:
--cpu_solver_pcg (default "pcg + ams + smoother 0") and --cpu_solver_cg (default "cg + none").

For the GPU side, two single reference times are computed the same way (mean over all matching
rows, after dropping rows whose norm deviates from the run's mode) and drawn as flat horizontal
lines: --gpu_amgx_path/--gpu_amgx_file/--gpu_amgx_solver (default AMGX "cg + none") and
--gpu_hypre_path/--gpu_hypre_file/--gpu_hypre_solver (default Hypre-CUDA "bicgstab + boomeramg +
smoother 3"). The GPU side is not scaled by partition/node count -- the point of the graph is to
compare a fixed one-GPU-run time against CPU scaling, not to scale the GPU side.

Usage:
    python3 plot_cpu_gpu.py -cp path/to/results_cpu -gap path/to/results_amgx -ghp path/to/results_hypre_cuda
    python3 plot_cpu_gpu.py -cp ... -gap ... -ghp ... -m 2 -s figure.png

The optional passable cmd args
   1. -cp   (--cpu_path) directory containing the CPU f*.dat/.marker/.names files
   2. -gap  (--gpu_amgx_path) directory containing the AMGX GPU .dat/.marker/.names files
   3. -gaf  (--gpu_amgx_file) filename of the AMGX GPU data file (default "f1.dat")
   4. -gas  (--gpu_amgx_solver) substring identifying the AMGX solver row to use
   5. -ghp  (--gpu_hypre_path) directory containing the Hypre-CUDA GPU .dat/.marker/.names files
   6. -ghf  (--gpu_hypre_file) filename of the Hypre-CUDA GPU data file (default "f1.dat")
   7. -ghs  (--gpu_hypre_solver) substring identifying the Hypre-CUDA GPU solver row to use
   8. -cs1  (--cpu_solver_pcg) substring identifying the first CPU solver's rows
   9. -cs2  (--cpu_solver_cg) substring identifying the second CPU solver's rows
   10. -m   (--mesh_level) mesh level ("expression 1") to filter all series to
   11. -t   (--tolerance) tolerance used when checking that the norm is consistent between runs
   12. -s   (--save_as) path to where the figure should be saved. If not passed the figure is shown
   13. -c   (--test_case) name of the test case shown in the figure title
"""

import argparse
import glob
import os

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import NullFormatter, ScalarFormatter

from tools.tools import read_names, read_markers, float_mode

################# PREDEFINED ####################

time_col = "linsys cpu time"  # The measured time of interest
norm_col = "magnetic norm"  # The norm of interest (WhitneyAVSolver; use "norm" for other cases)
partition_col = "partitions"  # The number of partitions used
mesh_level_col = "expression 1"  # The used mesh level
element_col = "elements"  # The number of elements in the mesh

# Predefined paths/files used if nothing is passed on the command line
cpu_path = "../results_2026/roihu/EndWindings-08-17/results_cpu_08_17"

gpu_amgx_path = "../results_2026/roihu/EndWindings-08-17/results_amgx_08_17"
gpu_amgx_file = "f1.dat"
gpu_amgx_solver = "cg_none"

gpu_hypre_path = "../results_2026/roihu/EndWindings-08-17/results_hypre_cuda_08_17"
gpu_hypre_file = "f1.dat"
gpu_hypre_solver = "boomeramg + smoother 3"

# Predefined CPU solvers to filter for (the CPU .dat files contain several solvers)
cpu_solver_pcg = "pcg + ams + smoother 0"
cpu_solver_cg = "cg + none"

# Predefined mesh level and tolerance
mesh_level = 2
tolerance = 10 ** (-6)

# Predefined test case name shown in the figure title
test_case = "EndWindings"

#################################################


def set_plain_number_ticks(ax, values):
    """Force an x-axis to show the exact partition counts as plain (non-scientific) tick labels."""
    ax.set_xticks(values)
    ax.set_xticklabels([str(v) for v in values])
    ax.xaxis.set_minor_formatter(NullFormatter())


def load_dat(dat_file):
    column_names = read_names(dat_file)
    data = pd.read_table(dat_file, sep=r"\s+", header=None)
    data.columns = column_names
    data['Solver'] = read_markers(dat_file)
    return data


def load_dir(path, pattern="f*.dat"):
    """Read and concatenate every file matching pattern in path (ignoring the .marker/.names
    side files), so newly added f<n>.dat files are picked up without changing this script."""
    dat_files = sorted(
        f for f in glob.glob(os.path.join(path, pattern))
        if not f.endswith(('.marker', '.names'))
    )
    if not dat_files:
        raise FileNotFoundError(f"No files matching '{pattern}' found in {path}")
    return pd.concat([load_dat(f) for f in dat_files], ignore_index=True)


def resolve_columns(data):
    columns = data.columns.tolist()
    time_column = [c for c in columns if time_col in c][0]
    norm_column = [c for c in columns if norm_col in c][0]
    partition_column = [c for c in columns if partition_col in c][0]
    mesh_level_column = [c for c in columns if mesh_level_col in c][0]
    element_column = [c for c in columns if element_col in c][0]
    return time_column, norm_column, partition_column, mesh_level_column, element_column


def elements_at_mesh_level(data, mesh_level_column, element_column):
    subset = data[data[mesh_level_column] == float(mesh_level)]
    return int(subset[element_column].iloc[0])


def filter_solver_mesh_level(data, solver_filter, mesh_level_column, norm_column, tol):
    subset = data[data['Solver'].str.contains(solver_filter, regex=False)]
    subset = subset[subset[mesh_level_column] == float(mesh_level)]

    if len(subset) == 0:
        return subset

    # Drop rows where the norm deviates from the mode, i.e. runs with an incorrect solution
    mode = float_mode(subset[norm_column].values, tol=tol)
    return subset[np.isclose(subset[norm_column], mode, atol=tol)]


def cpu_series(data, solver_filter, columns, tol):
    time_column, norm_column, partition_column, mesh_level_column, element_column = columns
    subset = filter_solver_mesh_level(data, solver_filter, mesh_level_column, norm_column, tol)

    if len(subset) == 0:
        raise ValueError(f"No rows found for solver '{solver_filter}' at mesh level {mesh_level} in {cpu_path}")

    grouped = subset.groupby(partition_column)[time_column].mean().sort_index()
    return grouped.index.values.astype(int), grouped.values


def gpu_reference_time(path, filename, solver_filter, tol):
    dat_file = os.path.join(path, filename)
    data = load_dat(dat_file)
    time_column, norm_column, partition_column, mesh_level_column, element_column = resolve_columns(data)

    subset = filter_solver_mesh_level(data, solver_filter, mesh_level_column, norm_column, tol)
    if len(subset) == 0:
        raise ValueError(f"No rows found for solver '{solver_filter}' at mesh level {mesh_level} in {dat_file}")

    return subset[time_column].mean()


def main():
    global cpu_path, gpu_amgx_path, gpu_amgx_file, gpu_amgx_solver
    global gpu_hypre_path, gpu_hypre_file, gpu_hypre_solver
    global cpu_solver_pcg, cpu_solver_cg, mesh_level, tolerance, test_case

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-cp', '--cpu_path', type=str, default=cpu_path)
    parser.add_argument('-gap', '--gpu_amgx_path', type=str, default=gpu_amgx_path)
    parser.add_argument('-gaf', '--gpu_amgx_file', type=str, default=gpu_amgx_file)
    parser.add_argument('-gas', '--gpu_amgx_solver', type=str, default=gpu_amgx_solver)
    parser.add_argument('-ghp', '--gpu_hypre_path', type=str, default=gpu_hypre_path)
    parser.add_argument('-ghf', '--gpu_hypre_file', type=str, default=gpu_hypre_file)
    parser.add_argument('-ghs', '--gpu_hypre_solver', type=str, default=gpu_hypre_solver)
    parser.add_argument('-cs1', '--cpu_solver_pcg', type=str, default=cpu_solver_pcg)
    parser.add_argument('-cs2', '--cpu_solver_cg', type=str, default=cpu_solver_cg)
    parser.add_argument('-m', '--mesh_level', type=int, default=mesh_level)
    parser.add_argument('-t', '--tolerance', type=float, default=tolerance)
    parser.add_argument('-s', '--save_as', type=str)
    parser.add_argument('-c', '--test_case', type=str, default=test_case)
    args = parser.parse_args()

    cpu_path = args.cpu_path
    gpu_amgx_path = args.gpu_amgx_path
    gpu_amgx_file = args.gpu_amgx_file
    gpu_amgx_solver = args.gpu_amgx_solver
    gpu_hypre_path = args.gpu_hypre_path
    gpu_hypre_file = args.gpu_hypre_file
    gpu_hypre_solver = args.gpu_hypre_solver
    cpu_solver_pcg = args.cpu_solver_pcg
    cpu_solver_cg = args.cpu_solver_cg
    mesh_level = args.mesh_level
    tolerance = args.tolerance
    test_case = args.test_case

    cpu_data = load_dir(cpu_path)
    columns = resolve_columns(cpu_data)
    _, _, _, mesh_level_column, element_column = columns

    elements = elements_at_mesh_level(cpu_data, mesh_level_column, element_column)

    pcg_partitions, pcg_times = cpu_series(cpu_data, cpu_solver_pcg, columns, tolerance)
    cg_partitions, cg_times = cpu_series(cpu_data, cpu_solver_cg, columns, tolerance)

    amgx_time = gpu_reference_time(gpu_amgx_path, gpu_amgx_file, gpu_amgx_solver, tolerance)
    hypre_cuda_time = gpu_reference_time(gpu_hypre_path, gpu_hypre_file, gpu_hypre_solver, tolerance)

    print(f"CPU hypre: {cpu_solver_pcg}:")
    for n, t in zip(pcg_partitions, pcg_times):
        print(f"  {n:<6} partitions: {t:.2f} s")

    print(f"CPU {cpu_solver_cg}:")
    for n, t in zip(cg_partitions, cg_times):
        print(f"  {n:<6} partitions: {t:.2f} s")

    print(f"GPU AMGX ({gpu_amgx_solver}): {amgx_time:.2f} s")
    print(f"GPU Hypre-CUDA ({gpu_hypre_solver}): {hypre_cuda_time:.2f} s")

    fig, ax = plt.subplots(figsize=(10, 6))

    ax.plot(pcg_partitions, pcg_times, marker='o', color='tab:blue', label="CPU: hypre pcg + ams + smoother 0")
    ax.plot(cg_partitions, cg_times, marker='o', color='tab:green', label="CPU: cg + none")

    ax.axhline(amgx_time, linestyle='--', color='tab:orange', label="GPU: amgx cg + none (1 GPU)")
    ax.axhline(hypre_cuda_time, linestyle='--', color='tab:red',
               label="GPU: hypre bicgstab + boomeramg + smoother 3 (1 GPU)")

    ax.set_xscale('log')
    ax.set_yscale('log')
    ax.set_xlabel("Number of partitions")
    ax.set_ylabel(f"Times (s)")
    ax.grid(True, which='both', alpha=0.3)

    all_partitions = sorted(set(pcg_partitions.tolist()) | set(cg_partitions.tolist()))
    set_plain_number_ticks(ax, all_partitions)

    # Show plain numbers (e.g. "10", "0.6") on the log time axis instead of "10^1"/"6x10^0"
    ax.yaxis.set_major_formatter(ScalarFormatter())
    ax.yaxis.set_minor_formatter(ScalarFormatter())

    elements_str = f"{elements:,}".replace(",", " ")
    ax.set_title(f"{test_case}: CPU vs GPU linear system solution time (Elements: {elements_str})")
    ax.legend()

    plt.tight_layout()

    if args.save_as is not None:
        plt.savefig(args.save_as)
    else:
        plt.show()


if __name__ == "__main__":
    main()
