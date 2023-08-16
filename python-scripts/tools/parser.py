"""
Separate file containing everything needed to parse the command line args
"""
import argparse


def parse_cmd():

    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--path', type=str)
    parser.add_argument('-f', '--file', type=str)
    parser.add_argument('-i', '--ignore', type=int)
    parser.add_argument('-m', '--mesh_level', type=int)
    parser.add_argument('-s', '--save_as', type=str)
    parser.add_argument('-t', '--tolerance', type=float)
    parser.add_argument('-v', '--viz_total_time', action="store_true")
    parser.add_argument('-r', '--nrows', type=int)
    parser.add_argument('-c', '--ncols', type=int)
    
    args = parser.parse_args()

    return vars(args)
