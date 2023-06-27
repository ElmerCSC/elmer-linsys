"""
Library of useful helper functions
"""
import numpy as np


# Function for computing the mode of a list of floating point values with a given tolerance
def float_mode(vals, tol=10 ** (-6)):
    count = -1
    mode = -1
    max_iter = len(vals)
    i = 0
    while len(vals) > 0 and i < max_iter:
        val = vals[0]
        within_tol = np.isclose(vals, val, atol=tol)
        c = within_tol.sum()
        if c >= count:
            mode = val
            count = c

        vals = vals[np.invert(within_tol)]

        i++

    return mode


# Function for generating the column names automatically from dat_file.names file
def read_names(dat_file):
    filename = f"{dat_file}.names"
    columns = []
    with open(filename) as f:
        column_lines = f.readlines()[9:]
        for line in column_lines:
            columns.append(line.strip().split(': ', 1)[1])

    return columns
    

# Function for going through the dat_file.marker file containing the solver names
def read_markers(dat_file):
    filename = f"{dat_file}.marker"
    solvers = []
    with open(filename) as f:
        for line in f:
            solvers.append(line.strip().split(': ', 1)[1])

    return solvers
