## CPU testing

### FETI errors
logs/run_complete_301387.out shows some errors when using Feti. Is this expected?

** Error/warning return ** from Analysis *  INFO(1:2)=   1           37020

Seems to converge to a solution though for 128 cores.

### Solver elmer_iter_GCR_BP_CMG_SGS.sif
Not sure what this solver is supposed to be - sets both GCR and FETI. FETI overrides GCR

### Total Feti?

In feti solver, total feti is set to true. But in elmer source code examples, Total Feti is set to False with a comment that it provides incorrect results

### Small test case for Navier (1 node)
comparing: 
linsys/elmer_iter_BiCGStab2_ILU0.sif
linsys/elmer_feti_mumps_10.sif
linsys/elmer_iter_CG_ILU0.sif
linsys/elmer_iter_Idrs5_ILU0.sif

For 384 cores (full 1 node)
linsys/elmer_iter_BiCGStab2_ILU0.sif doesnt converge
linsys/elmer_feti_mumps_10.sif runs out of memory

Test log: logs/run_complete_302717.out (no BiCGStab2)

Next: try to test same mesh, but only CG and Idrs5





## GPU testing

### Containers
Container needs to be used when running on the GPU partition. The usage is 

` srun apptainer run --nv --bind="$(csc-common-bind)" $container_path ElmerSolver case.sif -ipar 2 $mesh_level $partitions `

### Solvers incorrect solutions
In the case of Poisson/WinkelUnstructured - amgx-block_jacobi gives an incorrect solution
In the case of Navier/WinkelStructured - amgx-bicgstab_amg, amgx-gmres, amgx-block_jacobi, amgx-fgmres_none give incorrect solutions

### Tips
- When writing a new test case, read the README of each test case to see how to invoke ElmerGrid (what parameters)


### Failing test cases when running Navier problem with gpu solvers

WARNING:: CompareToReferenceSolution: Solver 1 FAILED:  Norm = 1.89078666E-02  RefNorm = 2.33900606E-02
CompareToReferenceSolution: Relative Error to reference norm: 1.916281E-01
WARNING:: CompareToReferenceSolution: FAILED 1 tests out of 1!
MAIN: *** Elmer Solver: ALL DONE ***
MAIN: The end
SOLVER TOTAL TIME(CPU,REAL):        17.52       15.66
ELMER SOLVER FINISHED AT: 2026/07/16 11:08:45

Ending linsysAMGX/amgx_bicgstab_amg.sif with mesh level 1
Elapsed time: 19 s

-----------------------------------

CompareToReferenceSolution: Solver 1 PASSED:  Norm = 2.33900607E-02  RefNorm = 2.33900606E-02
CompareToReferenceSolution: Relative Error to reference norm: 5.018953E-09
CompareToReferenceSolution: PASSED all 1 tests!
MAIN: *** Elmer Solver: ALL DONE ***
MAIN: The end
SOLVER TOTAL TIME(CPU,REAL):         6.06        3.30
ELMER SOLVER FINISHED AT: 2026/07/16 11:08:52

Ending linsysAMGX/amgx_bicgstab_none.sif with mesh level 1
Elapsed time: 6 s

-----------------------------------
CompareToReferenceSolution: Solver 1 PASSED:  Norm = 2.33900606E-02  RefNorm = 2.33900606E-02
CompareToReferenceSolution: Relative Error to reference norm: 1.167048E-09
CompareToReferenceSolution: PASSED all 1 tests!
MAIN: *** Elmer Solver: ALL DONE ***
MAIN: The end
SOLVER TOTAL TIME(CPU,REAL):         5.94        3.17
ELMER SOLVER FINISHED AT: 2026/07/16 11:08:58

Ending linsysAMGX/amgx_cg_dilu.sif with mesh level 1
Elapsed time: 6 s

-----------------------------------

CompareToReferenceSolution: Solver 1 PASSED:  Norm = 2.33900605E-02  RefNorm = 2.33900606E-02
CompareToReferenceSolution: Relative Error to reference norm: 4.615594E-09
CompareToReferenceSolution: PASSED all 1 tests!
MAIN: *** Elmer Solver: ALL DONE ***
MAIN: The end
SOLVER TOTAL TIME(CPU,REAL):        19.31       16.59
ELMER SOLVER FINISHED AT: 2026/07/16 11:09:17

Ending linsysAMGX/amgx_fgmres_dilu.sif with mesh level 1
Elapsed time: 20 s

-----------------------------------

WARNING:: CompareToReferenceSolution: Solver 1 FAILED:  Norm = 2.33865718E-02  RefNorm = 2.33900606E-02
CompareToReferenceSolution: Relative Error to reference norm: 1.491590E-04
WARNING:: CompareToReferenceSolution: FAILED 1 tests out of 1!
MAIN: *** Elmer Solver: ALL DONE ***
MAIN: The end
SOLVER TOTAL TIME(CPU,REAL):        17.89       15.11
ELMER SOLVER FINISHED AT: 2026/07/16 11:09:35

Ending linsysAMGX/amgx_fgmres_none.sif with mesh level 1
Elapsed time: 18 s

-----------------------------------
CompareToReferenceSolution: Solver 1 PASSED:  Norm = 2.33900604E-02  RefNorm = 2.33900606E-02
CompareToReferenceSolution: Relative Error to reference norm: 7.029097E-09
CompareToReferenceSolution: PASSED all 1 tests!
MAIN: *** Elmer Solver: ALL DONE ***
MAIN: The end
SOLVER TOTAL TIME(CPU,REAL):         6.52        4.42
ELMER SOLVER FINISHED AT: 2026/07/16 11:09:43

Ending linsysAMGX/amgx_gmres_amg.sif with mesh level 1
Elapsed time: 7 s

-----------------------------------
WARNING:: CompareToReferenceSolution: Solver 1 FAILED:  Norm = 1.77382387E-03  RefNorm = 2.33900606E-02
CompareToReferenceSolution: Relative Error to reference norm: 9.241633E-01
WARNING:: CompareToReferenceSolution: FAILED 1 tests out of 1!
MAIN: *** Elmer Solver: ALL DONE ***
MAIN: The end
SOLVER TOTAL TIME(CPU,REAL):         5.49        3.21
ELMER SOLVER FINISHED AT: 2026/07/16 11:09:49

Ending linsysAMGX/amgx_gmres_none.sif with mesh level 1
Elapsed time: 6 s

-----------------------------------

CompareToReferenceSolution: Solver 1 PASSED:  Norm = 2.33900607E-02  RefNorm = 2.33900606E-02
CompareToReferenceSolution: Relative Error to reference norm: 3.284875E-09
CompareToReferenceSolution: PASSED all 1 tests!
MAIN: *** Elmer Solver: ALL DONE ***
MAIN: The end
SOLVER TOTAL TIME(CPU,REAL):         8.43        5.77
ELMER SOLVER FINISHED AT: 2026/07/16 11:09:57

Ending linsysAMGX/amgx_idr_dilu.sif with mesh level 1
Elapsed time: 9 s

-----------------------------------
WARNING:: CompareToReferenceSolution: Solver 1 FAILED:  Norm = 4.22435863E+16  RefNorm = 2.33900606E-02
CompareToReferenceSolution: Relative Error to reference norm: 1.806049E+18
WARNING:: CompareToReferenceSolution: FAILED 1 tests out of 1!
MAIN: *** Elmer Solver: ALL DONE ***
MAIN: The end
SOLVER TOTAL TIME(CPU,REAL):         5.83        3.05
ELMER SOLVER FINISHED AT: 2026/07/16 11:10:03

Ending linsysAMGX/amgx_jacobi_none.sif with mesh level 1
Elapsed time: 6 s

-----------------------------------

### Memory leaks
When ran with multi-GPUs on one node:

!!! detected some memory leaks in the code: trying to free non-empty temporary device pool !!!
ptr:        0x62d202000 size: 4096
ptr:        0x62d203000 size: 24576
ptr:        0x62e90c000 size: 106496
ptr:        0x62d201000 size: 4096
ptr:        0x62e9aa000 size: 8192
ptr:        0x62e9ac000 size: 8192
ptr:        0x62e9ae000 size: 8192
ptr:        0x62d209000 size: 4096
ptr:        0x62e9b2000 size: 4096
ptr:        0x62e940000 size: 12288
ptr:        0x62d200000 size: 4096
ptr:        0x62e9b0000 size: 4096
ptr:        0x62e943000 size: 118784
ptr:        0x62e960000 size: 118784

### Mesh Level 4 solvers failing

All AMGX solvers tested (`amgx_bicgstab_none`, `amgx_cg_dilu`) crash at mesh level 4
(Navier/WinkelStructured), right as the matrix is handed to AMGX:

```
SolveLinearSystem: Parallel linear System Solver: amgx
pml_ucx.c:806  Error: bsend: failed to allocate buffer
pml_ucx.c:962  Error: ucx send failed: No pending message
srun: error: ...: Killed
```
Logs: logs/amgx_all_{315436,315588,318069,318221,318689,318975}.err

Ruled out:
- Host RAM / GPU memory ceilings — host never exceeds ~287/858GB, GPU HBM stays at
  0-4MB the whole run (nothing ever reaches the device). See logs/mem_poll_*.csv.
- `UCX_RNDV_THRESH=0` (eager vs. rendezvous protocol) — no effect (job 318069).
- ulimits (`-l` locked mem, `-v` virtual mem) — unlimited, host and in-container match
  (job 318221).
- Per-rank chunk size — tested 3/4/8 ranks, all crash identically. Time-to-crash
  scales *inversely* with rank count (3 ranks: 12m46s, 4: 7m55s, 8: 4m19s), pointing
  at a fixed-size buffered-send resource exhausted by rank/connection count, not
  data volume.

Separate bug at **1 rank**: mesh level 4 segfaults earlier with a 32-bit nnz overflow
(`nofs: -294966967`) in `CreateMatrix`/`InitializeMatrix` (logs/amgx_all_318865.err).
Per-rank mesh multiplication means 1 rank ends up holding the entire ~50M-row/~4B-nonzero
global problem, overflowing Elmer's 32-bit nnz counter. Avoid 1-2 rank tests at mesh
level 4 for this reason.

Conclusion: likely a bug/hard limit in Elmer's AMGX interface (or its internal MPI
matrix-redistribution), independent of memory/UCX/ulimit tuning. Next: report upstream
(CSC support / Elmer or AMGX issue tracker) with the above.

 Title: Fix MPI_BSEND buffer overflow in AMGXSolver's matrix collection step

  ---
  Summary

  Running the AMGX linear solver on sufficiently large parallel problems (e.g. Navier/elasticity mesh level 4 on 3, 4, or 8 MPI ranks) reliably crashes right as the matrix is handed off to AMGX:

  SolveLinearSystem: Parallel linear System Solver: amgx
  [pml_ucx.c:806]  Error: bsend: failed to allocate buffer
  [pml_ucx.c:962]  Error: ucx send failed: No pending message
  srun: error: ...: Killed

  The crash is independent of total available memory (host RAM and GPU memory both had large amounts of headroom in every failing run) and independent of rank count — 3, 4, and 8 ranks all fail identically, with time-to-crash scaling inversely with rank count.
  
  Root cause

  AMGXSolver (fem/src/SolveCore.F90) builds a "collection matrix" for AMGX by having each rank ship its non-locally-owned rows (column indices + values) to their owning rank via raw MPI_BSEND, one row at a time:

  DO i=1,ParEnV % PEs
    IF(i-1==me .OR. .NOT. ParEnv % IsNeighbour(i)) CYCLE
    CALL MPI_BSEND(SendTo(i),1,MPI_INTEGER,i-1,1200,ELMER_COMM_WORLD, ierr)
    ...
    DO j=1,SendTo(i)
      CALL MPI_BSEND(APerm(A % Cols(...)),SendStuff(i) % Size(j),MPI_INTEGER,i-1,1203,...)
      CALL MPI_BSEND(A % Values(...),SendStuff(i) % Size(j),MPI_DOUBLE_PRECISION,i-1,1204,...)
    END DO
  END DO
      
  MPI_BSEND requires the application to pre-attach a large-enough buffer via MPI_BUFFER_ATTACH. Every other MPI_BSEND call site in the codebase (VankaCreate.F90, SParIterComm.F90, MeshPartition.F90, MeshBasics.F90, ParticleUtils.F90, InterpVarToVar.F90, SolverBasics.F90, and even the structurally-analogous ROCSolver matrix-collection loop ~150 lines below this one in the same file) calls the codebase's CheckBuffer(n) helper
  right before issuing its bsends, to attach a buffer sized for what's about to be sent. This one call site never does. It relies entirely on whatever buffer happens to be attached from some earlier, unrelated CheckBuffer call — sized for that call's much smaller needs. Once the redistribution volume at large mesh sizes exceeds that stale buffer, Open MPI's UCX PML fails exactly as observed.

  Fix

  Add a CheckBuffer call sized for this loop's actual traffic, following the same idiom used everywhere else in the codebase:

  totcnt = SUM(SendTo)
  totnnz = 0
  DO i=1,ParEnV % PEs
    IF(i-1==me .OR. .NOT. ParEnv % IsNeighbour(i)) CYCLE
    IF(SendTo(i)>0) totnnz = totnnz + SUM(SendStuff(i) % Size)
  END DO
  CALL CheckBuffer( ParEnv % PEs*(1+MPI_BSEND_OVERHEAD) + 2*totcnt + 3*totnnz + &
             (3*COUNT(SendTo/=0) + 2*totcnt)*MPI_BSEND_OVERHEAD )

  totcnt = total non-local rows being sent, totnnz = their total nonzero count. Byte accounting matches the codebase's convention (CheckBuffer internally multiplies its argument by 4, so callers pass byte-estimates pre-divided by 4).
             
  Testing    

  - Not yet compile-tested in this environment (no Fortran toolchain available here) — needs a build in the actual cluster/container environment before merge.
  - The bug was reproduced identically across three independent configurations (3, 4, and 8 MPI ranks, Navier/WinkelStructured mesh level 4, amgx_bicgstab_none/amgx_cg_dilu solvers) with memory profiling ruling out host RAM, GPU memory, UCX_RNDV_THRESH, and ulimits as the cause in each case.
  - Note: a separate, unrelated bug exists at 1 rank (32-bit integer overflow in CRS_CreateMatrix, fem/src/CRSMatrix.F90, when the whole mesh-level-4 problem — ~4B nonzeros — is held by a single rank). Not addressed by this PR.



### OMP_NUM_THREADS
results_2026/roihu/Navier-AMGX-WinkelStructured/Navier-AMGX-WinkelStructured-4 (OMP_NUM_THREADS=1)
results_2026/roihu/Navier-AMGX-WinkelStructured/Navier-AMGX-WinkelStructured-4-1 (OMP_NUM_THREADS=72)
results_2026/roihu/Navier-AMGX-WinkelStructured/Navier-AMGX-WinkelStructured-4-2 (OMP_NUM_THREADS=72, export OMP_PROC_BIND=spread, export OMP_PLACES=cores)

The tests show, that Elmer can't utilize 72 cores (the times in the graphics are total CPU time). 

TODO check what actually gets plotted in the graph



### GPU container
On roihu-gpu partition, the recommended way of running Elmer is via containers (for testing). The container and build script for it is included in this repo.


# EndWindings

## HYPRE on GPU:

what is the correct magnetic norm?
I thought it was 1.415160201606E-04

but mesh lvl 1 (both row and bulk assembly) report 1.406563E-04

Added error checks in Hypre. Seems that there has been an error before the matrix assembly rewrite (see hypre_gpu_endwindings_586366.err ran with diagnostics with old container with row/row assembly). 

Norm mesh lvl 1 1.40656300E-04


## CPU
these probably dont really work, test them

linsys/hypre_GMRes_BoomerAMG.sif
linsys/elmer_P_Idrs5_CG_none.sif
linsys/hypre_FlexGmres_BoomerAMG.sif

these should work for lower meshes at least

linsys/elmer_iter_BiCGStab4_none.sif
linsys/elmer_iter_BiCGStab_none.sif
linsys/elmer_iter_CG_none.sif
linsys/hypre_pcg_AMS_smoother0.sif

## AMGX
out of these:

linsysAMGX/amgx_gmres_none.sif
linsysAMGX/amgx_fgmres_none.sif
linsysAMGX/amgx_bicgstab_none.sif
linsysAMGX/amgx_cg_amg.sif
linsysAMGX/amgx_cg_none.sif

probably only cg and bicgstab works for lower and higher meshes

Norm mesh lvl 1 for amgx is 1.406563E-04
mesh lvl 2, probably 1.41318692E-04


## Testing

Hypre + Elmer CPU
lvl 2 - mpi: 64, 32
lvl 1 - 8

