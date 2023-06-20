# Test case and mesh generator for Transcranial Magnetic Stimulation (TMS)

TODO: Readme

## Possible errors

After using the python API on Ubuntu 22.04 the error:

"/usr/bin/env: 'python': No such file or directory"

might arise when calling the standard gmsh from command line. This is caused by the fact
that by default Ubuntu 22.04 comes with python3. To fix this 'python' needs to be made
an alias for 'python3', which can be accomplished with python-is-python3 package that
can be installed as:

"sudo apt -y install python-is-python3"