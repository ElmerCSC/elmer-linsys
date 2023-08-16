"""
Wrapper implementation for scipy spy function for plotting the sparsity
structure of a given coefficient matrix

This script has five optional passable cmd args
   1. -f (--file) for using a different file than the one predefined
   2. -p (--path) for using a different path than the one predefined
   3. -r (--nrows) for defining a different number of rows for the matrix
   4. -c (--ncols ) for defining a different number of columns for the matrix
   4. -s (--save_as) for defining the filename as which the figure will be saved. If not passed the figure will be visualized
"""
import matplotlib.pyplot as plt
import scipy.sparse as sps
import numpy as np
import argparse
import os
import sys
from tools.tools import *
from tools.parser import *



################# PREDEFINED ###################

# Give the name of the .dat file containing the information of the matrix
dat_filename = "linsys_a.dat"

# Give the number of rows in the matrix. For FEM coefficient matrices this is
# the number of dofs
nrows = 4 * 20030

# Give the number of columns in the matrix. If None the matrix is assumed square
ncols = None
    
# Change directory to a predefined location
org_cwd = os.getcwd()
cwd_arr = os.getcwd().split('/')
cwd_arr[-1] = "Stokes/Circular"
os.chdir('/'.join(cwd_arr))

################################################


def main():
    global dat_filename, nrows, ncols

    save_as = None

    if len(sys.argv) > 1:
        args = parse_cmd()

        if args['path'] is not None:
            os.chdir(args['path'])

        if args['file'] is not None:
            dat_filename = args['file']

        if args['nrows'] is not None:
            nrows = args['nrows']

        if args['ncols'] is not None:
            ncols = args['ncols']

        if args['save_as'] is not None:
            save_as = args['save_as']

    if ncols is None:
        ncols = nrows

    A = np.loadtxt(dat_filename)
    
    A = sps.csr_matrix((A[:,2], (A[:, 0] - 1, A[:, 1] - 1)), shape=[nrows, ncols])

    plt.figure(figsize=(8, 8))
    
    plt.spy(A, markersize=0.01)

    plt.xticks([])
    plt.yticks([])

    plt.title(f"Sparsity structure for case: {'-'.join(os.getcwd().split('/')[-2:])} (DOFs: {nrows})")

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
    


