import gmsh
import numpy as np
import argparse
import sys
import os


gmsh.initialize()
geo = gmsh.model.occ


def read_points(filename, delim=',', ignore_header=False):

    with open(filename) as f:
        points = np.loadtxt(f, delimiter=delim)

        if ignore_header:
            return points[1:, :]

        return points


def gen_test_mesh(save_points=False):

    gmsh.model.add("figure_8")

    d_x = 75  # mm
    d_y = 150  # mm
    d_z = 10  # mm
    r_wire = 2  # mm
    
    assert d_z > 4 * r_wire
    
    n_points = 100
    mesh_size = 0.066

    gmsh.option.setNumber("Mesh.MeshSizeFactor", mesh_size);

    x = d_x * np.sin(2 * np.linspace(0, 2 * np.pi, n_points))
    y = d_y * np.cos(np.linspace(0, 2 * np.pi, n_points))
    z = d_z * np.linspace(0, 1, n_points)

    if save_points:
        arr = np.concatenate((x.reshape(-1, 1), y.reshape(-1, 1), z.reshape(-1, 1)), axis=1)
        np.savetxt("figure_8.csv", arr, delimiter=',')

    points = []
    for i in range(n_points):
        points.append(geo.addPoint(x[i], y[i], z[i]))

    spline = geo.addSpline(points, tag=n_points + 1)
    spline_tag = n_points + 1
    
    wire = geo.addWire([spline], tag=n_points + 2)
    wire_tag = n_points + 2

    disk = geo.addDisk(x[0], y[0], z[0], r_wire, r_wire, zAxis=[x[1] - x[0], y[1] - y[0], z[1] - z[0]], tag=n_points + 3)
    disk_tag = n_points + 3
    
    pipe = geo.addPipe([(2, disk_tag)], wire_tag)

    head = geo.addSphere(0, 0, -d_y - d_z / 2, d_y, tag=n_points + 4)
    head_tag = n_points + 4

    air = geo.addSphere(0, 0, -d_y + d_z / 2, 2 * d_y, tag=n_points + 5)
    air_tag = n_points + 5

    air_without_objects = geo.cut([(3, air_tag)], [(3, head_tag)] + pipe, tag=n_points + 6, removeTool=False)
  
    gmsh.model.occ.synchronize()

    gmsh.model.mesh.generate()

    gmsh.write("figure_8.msh")


def gen_mesh(points, model_name, radius, mesh_size=0.25, coil_center=(0, 0, 0)):
    
    gmsh.model.add(model_name)
    gmsh.option.setNumber("Mesh.MeshSizeFactor", mesh_size);

    n_points = len(points)
    d_x = max(points[:, 0]) - coil_center[0]  # mm
    d_y = max(points[:, 1]) - coil_center[1]  # mm
    d_z = max(points[:, 2]) - coil_center[2]  # mm
    r_wire = radius  # mm

    gmsh_points = []
    for i in range(points.shape[0]):
        gmsh_points.append(geo.addPoint(points[i, 0] - coil_center[0],
                                        points[i, 1] - coil_center[0],
                                        points[i, 2] - coil_center[0]))

    spline = geo.addSpline(gmsh_points)
    spline_tag = n_points + 1
    
    wire = geo.addWire([spline])
    wire_tag = n_points + 2

    disk = geo.addDisk(points[0, 0], points[0, 1], points[0, 2],
                       radius, radius, zAxis=[points[1, 0] - points[0, 0],
                                              points[1, 1] - points[0, 1],
                                              points[1, 2] - points[0, 2]])
    disk_tag = n_points + 3
    
    pipe = geo.addPipe([(2, disk)], wire)

    head = geo.addSphere(0, 0, -d_y - d_z / 2, d_y, tag=n_points + 4)
    head_tag = n_points + 4

    air = geo.addSphere(0, 0, -d_y + d_z / 2, 2 * d_y, tag=n_points + 5)
    air_tag = n_points + 5

    air_without_objects = geo.cut([(3, air_tag)], [(3, head_tag)] + pipe, tag=n_points + 6, removeTool=False)
  
    gmsh.model.occ.synchronize()

    gmsh.model.mesh.generate()

    gmsh.write(model_name + ".msh")


if __name__ == "__main__":

    if len(sys.argv) > 1:
        parser = argparse.ArgumentParser()
        parser.add_argument('-p', '--path', type=str)
        parser.add_argument('-f', '--filename', type=str)
        parser.add_argument('-m', '--model', type=str)
        parser.add_argument('-r', '--radius', type=float)
        parser.add_argument('-s', '--mesh_size', type=float)
        parser.add_argument('-d', '--delimiter', type=str)
        parser.add_argument('-i', '--ignore_header', action="store_true")
        parser.add_argument('-c', '--coil_center', type=str)
        
        args = parser.parse_args()

        if args.path is not None:
            os.chdir(args.path)

        if args.filename is not None:
            filename = args.filename
        else:
            raise RuntimeError("Name of the file containing the points must be specified!")

        if args.model is not None:
            model_name = args.model
        else:
            model_name = "untitled"

        if args.radius is not None:
            radius = args.radius
        else:
            raise RuntimeError("Radius of the wire must be specified!")

        if args.mesh_size is not None:
            mesh_size = args.mesh_size
        else:
            mesh_size = 0.25

        if args.delimiter is not None:
            delim = args.delim
        else:
            delim = ","

        if args.coil_center is not None:
            coil_center = map(float, args.coil_center.split(delim))
        else:
            coil_center = (0, 0, 0)
            
        ignore_header = args.ignore_header

        gen_mesh(read_points(filename, delim=delim, ignore_header=ignore_header),
                 model_name, radius, mesh_size=mesh_size, coil_center=coil_center)
        
    else:
        # if not os.path.exists("figure_8.msh"):
        gen_test_mesh()

            
gmsh.finalize()
