"""
Compares the "linsys cpu time" measured on Mahti against Roihu for a set of GPU counts.

Expects, for each system, a directory containing the f<n>.dat/.dat.marker/.dat.names files
written by Elmer's SaveScalars solver, where <n> is the number of GPUs used for that run
(e.g. f1.dat -> 1 GPU, f2.dat -> 2 GPUs, f4.dat -> 4 GPUs).

Usage:
    python3 compare_roihu_mahti_times.py
    python3 compare_roihu_mahti_times.py -mp path/to/mahti -rp path/to/roihu -g 1 2 4 -s comparison.png

The optional passable cmd args
   1. -mp (--mahti_path) path to the directory with Mahti's f<n>.dat files
   2. -rp (--roihu_path) path to the directory with Roihu's f<n>.dat files
   3. -g  (--gpus) list of GPU counts to compare, each corresponding to a file f<n>.dat
   4. -t  (--tolerance) tolerance used when checking that the norm is consistent between repeated runs
   5. -s  (--save_as) path to where the figure should be saved. If not passed the figure will be visualized
   6. -c  (--test_case) name of the test case shown in the figure title
"""

import argparse
import os

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from tools.tools import read_names, float_mode

################# PREDEFINED ####################

time_col = "linsys cpu time"  # The measured time of interest
norm_col = "norm"  # The norm of interest
element_col = "elements"  # The number of elements in the mesh

# Predefined paths used if nothing is passed on the command line
mahti_path = "../raw_results/mahti/results_amgx_compare"
roihu_path = "../raw_results/roihu/results_amgx_compare"

# Predefined GPU counts, each corresponding to a file f<n>.dat
gpus = [1, 2, 4]

# Predefined tolerance used in float mode and numpy.isclose
tolerance = 10 ** (-6)

# Predefined test case name shown in the figure title
test_case = "Navier-WinkelStructured"

#################################################


def read_data(path, n_gpus, tol):
    dat_file = os.path.join(path, f"f{n_gpus}.dat")

    column_names = read_names(dat_file)
    data = pd.read_table(dat_file, sep=r"\s+", header=None)
    data.columns = column_names

    time_column = [c for c in column_names if time_col in c][0]
    norm_column = [c for c in column_names if norm_col in c][0]
    element_column = [c for c in column_names if element_col in c][0]

    # Drop rows where the norm deviates from the mode, i.e. runs with an incorrect solution
    mode = float_mode(data[norm_column].values, tol=tol)
    data = data[np.isclose(data[norm_column], mode, atol=tol)]

    return data[time_column].mean(), data[element_column].iloc[0]


def main():
    global mahti_path, roihu_path, gpus, tolerance, test_case

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-mp', '--mahti_path', type=str, default=mahti_path)
    parser.add_argument('-rp', '--roihu_path', type=str, default=roihu_path)
    parser.add_argument('-g', '--gpus', nargs='*', type=int, default=gpus)
    parser.add_argument('-t', '--tolerance', type=float, default=tolerance)
    parser.add_argument('-s', '--save_as', type=str)
    parser.add_argument('-c', '--test_case', type=str, default=test_case)
    args = parser.parse_args()

    mahti_path = args.mahti_path
    roihu_path = args.roihu_path
    gpus = args.gpus
    tolerance = args.tolerance
    test_case = args.test_case

    mahti_times = []
    roihu_times = []
    elements = None

    for n in gpus:
        m_time, m_elements = read_data(mahti_path, n, tolerance)
        r_time, _ = read_data(roihu_path, n, tolerance)
        mahti_times.append(m_time)
        roihu_times.append(r_time)
        elements = m_elements

    # Speedup of Roihu relative to Mahti: >1 means Roihu is faster
    speedups = [m / r for m, r in zip(mahti_times, roihu_times)]

    print(f"{'GPUs':<6}{'Mahti (s)':<12}{'Roihu (s)':<12}{'Speedup (Roihu vs Mahti)'}")
    for n, m, r, s in zip(gpus, mahti_times, roihu_times, speedups):
        print(f"{n:<6}{m:<12.2f}{r:<12.2f}{s:.2f}x")

    fig, ax = plt.subplots(figsize=(10, 6))

    ax.plot(gpus, mahti_times, marker='o', label="Mahti A100")
    ax.plot(gpus, roihu_times, marker='o', label="Roihu GH200")

    for n, m, r, s in zip(gpus, mahti_times, roihu_times, speedups):
        ax.annotate(f"{s:.2f}x", (n, max(m, r)), textcoords="offset points", xytext=(0, 10), ha='center')

    ax.set_xticks(gpus)
    ax.set_xlabel("Number of GPUs")
    ax.set_ylabel(f"{time_col} (s)")
    ax.set_title(f"{test_case}: linsys cpu time, Mahti vs Roihu (Elements: {int(elements)})")
    ax.legend()
    ax.grid(True, alpha=0.3)

    plt.tight_layout()

    if args.save_as is not None:
        plt.savefig(args.save_as)
    else:
        plt.show()


if __name__ == "__main__":
    main()
