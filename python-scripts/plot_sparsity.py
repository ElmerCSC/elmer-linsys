"""
Wrapper implementation for scipy spy function for plotting the sparsity
structure of a given coefficient matrix
"""
import matplotlib.pyplot as plt
import scipy.sparse as sps
import numpy as np
import argparse
import os
import sys


def main():

    ################# PREDEFINED ###################

    # Give the name of the .dat file containing the information of the matrix
    dat_filename = "linsys_a.dat"

    # Give the number of rows in the matrix. For FEM coefficient matrices this is
    # the number of dofs
    nrows = 4 * 20030

    # Give the number of columns in the matrix. If None the matrix is assumed square
    ncols = None
    
    # Change directory to a predefined location
    cwd_arr = os.getcwd().split('/')
    cwd_arr[-1] = "Stokes/Circular"
    os.chdir('/'.join(cwd_arr))

    ################################################

    if len(sys.argv) > 1:
        parser = argparse.ArgumentParser()
        parser.add_argument('-p', '--path', type=str)
        parser.add_argument('-f', '--file', type=str)
        parser.add_argument('-n', '--nrows', type=int)
        parser.add_argument('-m', '--ncols', type=int)
        
        args = parser.parse_args()

        if args.path is not None:
            os.chdir(args.path)
        
        if args.file is not None:
            dat_filename = args.file

        if args.nrows is not None:
            nrows = args.nrows

        if args.ncols is not None:
            ncols = args.ncols

    if ncols is None:
        ncols = nrows

    A = np.loadtxt(dat_filename)
    
    A = sps.csr_matrix((A[:,2], (A[:, 0] - 1, A[:, 1] - 1)), shape=[nrows, ncols])

    plt.figure()
    
    plt.spy(A, markersize=0.01)

    plt.xticks([])
    plt.yticks([])

    # plt.title(f"Sparsity structure for case: {'-'.join(os.getcwd().split('/')[-2:])}")

    plt.show()


if __name__ == "__main__":
    main()
    


