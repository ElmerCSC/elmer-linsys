# ChEESE performance audit 

This document describes how to prepare Elmer for ChEESE performance audits on LUMI. 

Essentially this requires three steps:
1. Prepare Spack for tools installation
1. Install tools through Spack
1. Runscripts
1. Determine baselines 

Well, that is four steps :smile:.

## Prepare Spack for tool installation

We will leverage LUMI's Spack facility for installation of tools. Any version of Spack will do, but it need to be the same at the time of tool installation and when doing the runs. For the purpose of this document we will use LUMI's module `spack/23.03-2`.

First of all, setup your (module) environemt as usual for doing runs or compiling your code. Repeat this everytime that you install/modify your private spack installation. Check with 
```bash
module load ....
# for Elmer environment: 
# module use /appl/local/csc/modulefiles
# module load spack/23.03 elmer/gcc-cray 
ml use /appl/local/csc/modulefiles
ml use /appl/lumi/spack/23.03/0.19.2/share/spack/modules/linux-sles15-zen2
ml use /appl/local/csc/soft/eng/elmer/spack/23.03/0.19.2/modules/tcl/linux-sles15-zen2/
ml load elmer/gcc-spack
module list
```

Spack requires disk space to install packages, book-keeping, etc. On LUMI this is controlled by the environment variable `$SPACK_USER_PREFIX` which needs to be set before the Spack module can even be loaded. It is recommended to point this variable to a directory which is readable by the whole LUMI compute project.

```bash 
export PROJECT_ID=465000533    # put your own here
export SPACK_USER_PREFIX=/project/project_${PROJECT_ID}/spack_ChEESE
module load spack/23.03-2
```
You might consider putting this in you `.bashrc` or similar as this will be used at every stage of this document.

Now, it is time to bootstrap Spack to install dependencies, etc. This needs to be done only once. Actually, this is step is optional, as it will be executed at your first usage of spack. But it takes some time and might make you nervous. Anyway, *make it so!* with:
```bash
spack bootstrap now
```

Next, we need to do some configuration in various files. Make sure that the listed files contain at least the shown lines.

This allows us to use our own private Spack recipes. 
```bash
spack repo create $SPACK_USER_PREFIX/cheese_local_repo cheese
sapck repo add $SPACK_USER_PREFIX/cheese_local_repo  # doesn't work for me
# edit this file instead
cat  $SPACK_USER_PREFIX/repos.yaml
repos:
# Private local repo for cheese project audits campaign
  - $SPACK_USER_PREFIX/cheese_local_repo
```

Now install Spack recipe for DLB.
```
mkdir -p $SPACK_USER_PREFIX/cheese_local_repo/packages/dlb
curl --output-dir $SPACK_USER_PREFIX/cheese_local_repo/packages/dlb -fO https://raw.githubusercontent.com/spack/spack/develop/var/spack/repos/builtin/packages/dlb/package.py
```


## Install tools through Spack
Setup your usual environment and Spack as in the previous section.

And install the tools mpiP, Extrae and XXX with 
```bash
# spack spec -I  mpip ^python@3.10
spack install mpip

# spack spec -I extrae@3.8.3~~cuda 
spack install extrae@3.8.3~~cuda 

spack --config-scope=$SPACK_USER_PREFIX install dlb@3.3.1
```

Extrae needs a configuration file `extrae_detail_circular.xml` 
```
curl -fO https://code.hlrs.de/hpcjgrac/hawk-utils-scripts/raw/branch/main/performance/extrae/share/extrae_detail_circular.xml
```
Place this in your job folder.

And here is a script to calculate basic performance metrics from mpiP reports
```
curl -fO https://code.hlrs.de/hpcjgrac/hawk-utils-scripts/raw/branch/main/performance/mpiP/share/mpip2POP.py
```

## Runscript

You need to modify your runscripts to attach the tools to your executable.

For mpiP runs add something like this to your jobscript
```bash
# setup modules, etc
module load mpip
export MPIP="-c -d"
TRACE="env LDPRELOAD=libmpip.so"

# add $TRACE before you application executable
mpirun -np XXX ... ${TRACE} ./appl ...
```
This will produce mpiP reports which end in `*.1.mpiP` or `*.2.mpiP`.

For Extrae add the follwing to your jobscript
```bash
# setup modules, etc
module load extrae
export EXTRAE_CONFIG_FILE=/PATH/TO/extrae_detail_circular.xml
TRACE="env LD_PRELOAD=libmpitracecf.so"

# add $TRACE before you application executable
srun ... ${TRACE} ./appl ...
```
This will create files `TRACE.*` and directories `set-*` which hold the raw traces. You need to _merge_ these into regular traces with the command
```bash
module load extrae
mpi2prv -f TRACE.mpits -o trace_YOUR_FAVORITE_NAME_NRANKS.prv
```



