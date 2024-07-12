!-----------------------------------------------------------------------------
!> A prototype solver for advection-diffusion-reaction equation.
!> This equation is generic and intended for education purposes
!> but may also serve as a starting point for more complex solvers.
!> Version supporting multithreading and SIMD friendly ElmerSolver
!> kernels. 
!------------------------------------------------------------------------------
SUBROUTINE AdvDiffSolver_init( Model,Solver,dt,TransientSimulation )
!------------------------------------------------------------------------------
  USE DefUtils
  IMPLICIT NONE
!------------------------------------------------------------------------------
  TYPE(Solver_t) :: Solver
  TYPE(Model_t) :: Model
  REAL(KIND=dp) :: dt
  LOGICAL :: TransientSimulation
!------------------------------------------------------------------------------
  CHARACTER(*), PARAMETER :: Caller = 'AdvDiffSolver_init'
  
  IF ( CurrentCoordinateSystem() /= Cartesian ) THEN
    CALL Fatal(Caller,'Implemented only in cartesian coordinates')
  END IF

END SUBROUTINE AdvDiffSolver_Init


!------------------------------------------------------------------------------
SUBROUTINE AdvDiffSolver( Model,Solver,dt,TransientSimulation )
!------------------------------------------------------------------------------
  USE DefUtils

  IMPLICIT NONE
!------------------------------------------------------------------------------
  TYPE(Solver_t) :: Solver
  TYPE(Model_t) :: Model
  REAL(KIND=dp) :: dt
  LOGICAL :: TransientSimulation
!------------------------------------------------------------------------------
! Local variables
!------------------------------------------------------------------------------
  TYPE(Element_t),POINTER :: Element
  REAL(KIND=dp) :: Norm
  INTEGER :: n, nb, nd, t, active
  INTEGER :: iter, maxiter, nColours, col, totelem, nthr
  LOGICAL :: Found, VecAsm, InitHandles
  CHARACTER(*), PARAMETER :: Caller = 'AdvDiffSolver'
!------------------------------------------------------------------------------

  CALL Info(Caller,'------------------------------------------------')
  CALL Info(Caller,'Solving generic advection-diffusion-reaction PDE')

  CALL DefaultStart()

  
  
  maxiter = ListGetInteger( GetSolverParams(),&
      'Nonlinear System Max Iterations',Found,minv=1)
  IF(.NOT. Found ) maxiter = 1

  nthr = 1
  !$ nthr = omp_get_max_threads()

  ! Nonlinear iteration loop:
  !--------------------------
  DO iter=1,maxiter

    ! System assembly:
    !----------------
    CALL DefaultInitialize()

    totelem = 0

    nColours = GetNOFColours(Solver)
    VecAsm = (nColours > 1) .OR. (nthr == 1)
    
    CALL ResetTimer( Caller//'BulkAssembly' )

    !$OMP PARALLEL &
    !$OMP SHARED(Solver, Active, nColours, VecAsm) &
    !$OMP PRIVATE(t, Element, n, nd, nb,col, Inithandles) &
    !$OMP REDUCTION(+:totelem) DEFAULT(NONE)
   
    DO col=1,nColours
      
      !$OMP SINGLE
      CALL Info( Caller,'Assembly of colour: '//I2S(col),Level=15)
      Active = GetNOFActive(Solver)
      !$OMP END SINGLE

      InitHandles = .TRUE.
      !$OMP DO
      DO t=1,Active
        Element => GetActiveElement(t)
        totelem = totelem + 1
        n  = GetElementNOFNodes(Element)
        nd = GetElementNOFDOFs(Element)
        nb = GetElementNOFBDOFs(Element)
        CALL LocalMatrixVec(  Element, n, nd+nb, nb, VecAsm )
      END DO
      !$OMP END DO
    END DO
    !$OMP END PARALLEL 

    CALL CheckTimer(Caller//'BulkAssembly',Delete=.TRUE.)
    totelem = 0

    CALL DefaultFinishBulkAssembly()

    nColours = GetNOFBoundaryColours(Solver)
    VecAsm = (nColours > 1) .OR. (nthr == 1)

    CALL ResetTimer(Caller//'BCAssembly')
    
    !$OMP PARALLEL &
    !$OMP SHARED(Active, Solver, nColours, VecAsm) &
    !$OMP PRIVATE(t, Element, n, nd, nb, col, InitHandles) & 
    !$OMP REDUCTION(+:totelem) DEFAULT(NONE)
    DO col=1,nColours
       !$OMP SINGLE
       CALL Info('ModelPDEthreaded','Assembly of boundary colour: '//I2S(col),Level=10)
       Active = GetNOFBoundaryActive(Solver)
       !$OMP END SINGLE

       InitHandles = .TRUE. 
       !$OMP DO
       DO t=1,Active
          Element => GetBoundaryElement(t)
          ! WRITE (*,*) Element % ElementIndex
          totelem = totelem + 1
          IF(ActiveBoundaryElement(Element)) THEN
             n  = GetElementNOFNodes(Element)
             nd = GetElementNOFDOFs(Element)
             nb = GetElementNOFBDOFs(Element)
             CALL LocalMatrixBC(  Element, n, nd+nb, nb, VecAsm, InitHandles )
          END IF
       END DO
       !$OMP END DO
    END DO
    !$OMP END PARALLEL

    CALL CheckTimer(Caller//'BCAssembly',Delete=.TRUE.)
        
    CALL DefaultFinishBoundaryAssembly()
    CALL DefaultFinishAssembly()
    CALL DefaultDirichletBCs()

    ! And finally, solve:
    !--------------------
    Norm = DefaultSolve()

    IF( Solver % Variable % NonlinConverged == 1 ) EXIT

  END DO

  CALL DefaultFinish()

  
CONTAINS

! Assembly of the matrix entries arising from the bulk elements. SIMD version.
!------------------------------------------------------------------------------
  SUBROUTINE LocalMatrixVec( Element, n, nd, nb, VecAsm )
!------------------------------------------------------------------------------
    USE LinearForms
    IMPLICIT NONE
    INTEGER, INTENT(IN) :: n, nd, nb
    TYPE(Element_t), POINTER :: Element
    LOGICAL, INTENT(IN) :: VecAsm
!------------------------------------------------------------------------------
    REAL(KIND=dp), ALLOCATABLE, SAVE :: Basis(:,:),dBasisdx(:,:,:), DetJ(:)
    REAL(KIND=dp), ALLOCATABLE, SAVE :: MASS(:,:), STIFF(:,:), FORCE(:)
    REAL(KIND=dp), SAVE, ALLOCATABLE  :: DiffCoeff(:), ConvCoeff(:), ReactCoeff(:), &
         TimeCoeff(:), SourceCoeff(:), Velo1Coeff(:), Velo2Coeff(:), Velo3Coeff(:)
    REAL(KIND=dp), SAVE, ALLOCATABLE  :: VeloCoeff(:,:)
    LOGICAL :: Stat,Found
    INTEGER :: i,t,p,q,dim,ngp,allocstat
    TYPE(GaussIntegrationPoints_t) :: IP
    TYPE(Nodes_t), SAVE :: Nodes
    !LOGICAL, SAVE :: FirstTime=.TRUE.
    
    !$OMP THREADPRIVATE(Basis, dBasisdx, DetJ, &
    !$OMP               MASS, STIFF, FORCE, Nodes, &
    !$OMP               SourceCoeff, DiffCoeff, ReactCoeff, TimeCoeff, &
    !$OMP               ConvCoeff, Velo1Coeff, Velo2Coeff, Velo3Coeff, VeloCoeff )
    !DIR$ ATTRIBUTES ALIGN:64 :: Basis, dBasisdx, DetJ
    !DIR$ ATTRIBUTES ALIGN:64 :: MASS, STIFF, FORCE
!------------------------------------------------------------------------------



    
    dim = CoordinateSystemDimension()
    IP = GaussPoints( Element )
    ngp = IP % n

    ! THIS IS UGLY AND DIRTY - assuming all elements are same!
!!$    IF (FirstTime) THEN
!!$      ALLOCATE(DiffCoeff(ngp), ConvCoeff(ngp), ReactCoeff(ngp), &
!!$           TimeCoeff(ngp), SourceCoeff(ngp), Velo1Coeff(ngp), Velo2Coeff(ngp),&
!!$           Velo3Coeff(ngp), VeloCoeff(ngp,3), MASS(nd,nd), STIFF(nd,nd), FORCE(nd),&
!!$           Basis(ngp,nd), dBasisdx(ngp,nd,3), DetJ(ngp), &
!!$           STAT=allocstat)
!!$      DiffCoeff = 1.0_dp
!!$      ConvCoeff=0.0_dp
!!$      ReactCoeff=0.0_dp
!!$      TimeCoeff=0.0_dp
!!$      SourceCoeff=1.0_dp
!!$      Velo1Coeff=0.0_dp
!!$      Velo2Coeff=0.0_dp
!!$      Velo3Coeff=0.0_dp
!!$      IF (allocstat /= 0) THEN
!!$        CALL Fatal(Caller,'Local storage allocation failed')
!!$      END IF
!!$      FirstTime=.FALSE.
!!$    END IF
    
    ! Deallocate storage if needed
    IF (ALLOCATED(Basis)) THEN
      IF (SIZE(Basis,1) < ngp .OR. SIZE(Basis,2) < nd) &
            DEALLOCATE(Basis,dBasisdx, DetJ, MASS, STIFF, FORCE, VeloCoeff, DiffCoeff, ConvCoeff, ReactCoeff, &
            TimeCoeff, SourceCoeff, Velo1Coeff, Velo2Coeff, Velo3Coeff)
    END IF

    ! Allocate storage if needed
    IF (.NOT. ALLOCATED(Basis)) THEN
      ALLOCATE(Basis(ngp,nd), dBasisdx(ngp,nd,3), DetJ(ngp), &
           MASS(nd,nd), STIFF(nd,nd), FORCE(nd), &
           DiffCoeff(ngp), ConvCoeff(ngp), ReactCoeff(ngp), &
           TimeCoeff(ngp), SourceCoeff(ngp), Velo1Coeff(ngp), Velo2Coeff(ngp),&
           Velo3Coeff(ngp), VeloCoeff(ngp,3), &
           STAT=allocstat)
      
      IF (allocstat /= 0) THEN
        CALL Fatal(Caller,'Local storage allocation failed')
      END IF
      DiffCoeff = 1.0_dp
      ConvCoeff=0.0_dp
      ReactCoeff=0.0_dp
      TimeCoeff=0.0_dp
      SourceCoeff=1.0_dp
      Velo1Coeff=0.0_dp
      Velo2Coeff=0.0_dp
      Velo3Coeff=0.0_dp
     END IF

    CALL GetElementNodesVec( Nodes, UElement=Element )

    ! Initialize
    MASS  = 0._dp
    STIFF = 0._dp
    FORCE = 0._dp

    ! Numerical integration:
    ! Compute basis function values and derivatives at integration points
    !--------------------------------------------------------------
    stat = ElementInfoVec( Element, Nodes, ngp, IP % U, IP % V, IP % W, detJ, &
         SIZE(Basis,2), Basis, dBasisdx )

    ! Compute actual integration weights (recycle the memory space of DetJ)
    DO t=1,ngp
      DetJ(t) = IP % s(t) * Detj(t)
    END DO

    ! diffusion term     
    ! STIFF=STIFF+(D*grad(u),grad(v))
    !DiffCoeff => ListGetElementRealVec( DiffCoeff_h, ngp, Basis, Element, Found )
    
    Found = .TRUE.
    
    IF( Found ) THEN
      CALL LinearForms_GradUdotGradU(ngp, nd, Element % TYPE % DIMENSION, dBasisdx, DetJ, STIFF, DiffCoeff )
    END IF

    ! reaction term 
    ! STIFF=STIFF+(R*u,v)
    !ReactCoeff => ListGetElementRealVec( ReactCoeff_h, ngp, Basis, Element, Found ) 
    IF( Found ) THEN    
      CALL LinearForms_UdotU(ngp, nd, Element % TYPE % DIMENSION, Basis, DetJ, STIFF, ReactCoeff )
    END IF
    
    ! time derivative
    ! MASS=MASS+(rho*du/dt,v)
    !TimeCoeff => ListGetElementRealVec( TimeCoeff_h, ngp, Basis, Element, Found ) 
    IF( Found ) THEN
      CALL LinearForms_UdotU(ngp, nd, Element % TYPE % DIMENSION, Basis, DetJ, MASS, TimeCoeff )
    END IF
      
    ! FORCE=FORCE+(u,f)
    !SourceCoeff => ListGetElementRealVec( SourceCoeff_h, ngp, Basis, Element, Found ) 
    IF( Found ) THEN
      CALL LinearForms_UdotF(ngp, nd, Basis, DetJ, SourceCoeff, FORCE)
    END IF

    
    ! advection term
    ! STIFF=STIFF+(C*grad(u),v)
 
    
    IF(TransientSimulation) CALL Default1stOrderTime(MASS,STIFF,FORCE,UElement=Element)
    CALL CondensateP( nd-nb, nb, STIFF, FORCE )
    CALL DefaultUpdateEquations(STIFF,FORCE,UElement=Element, VecAssembly=VecAsm)
!------------------------------------------------------------------------------
  END SUBROUTINE LocalMatrixVec
!------------------------------------------------------------------------------


! Assembly of the matrix entries arising from the Neumann and Robin conditions
!------------------------------------------------------------------------------
  SUBROUTINE LocalMatrixBC( Element, n, nd, nb, VecAsm, InitHandles )
!------------------------------------------------------------------------------
    IMPLICIT NONE
    INTEGER :: n, nd, nb
    TYPE(Element_t), POINTER :: Element
    LOGICAL :: VecAsm
    LOGICAL, INTENT(INOUT) :: InitHandles
!------------------------------------------------------------------------------
    REAL(KIND=dp) :: F,C,Ext, Weight
    REAL(KIND=dp) :: Basis(nd),dBasisdx(nd,3),DetJ
    REAL(KIND=dp) :: STIFF(nd,nd), FORCE(nd), LOAD(n)
    LOGICAL :: Stat,Found
    INTEGER :: i,t,p,q,dim
    TYPE(GaussIntegrationPoints_t) :: IP

    TYPE(ValueList_t), POINTER :: BC
       
    TYPE(Nodes_t) :: Nodes
    TYPE(ValueHandle_t), SAVE :: Flux_h, Robin_h, Ext_h

    SAVE Nodes
    !$OMP THREADPRIVATE(Nodes,Flux_h,Robin_h,Ext_h)
!------------------------------------------------------------------------------
    BC => GetBC(Element)
    IF (.NOT.ASSOCIATED(BC) ) RETURN

    IF( InitHandles ) THEN
      CALL ListInitElementKeyword( Flux_h,'Boundary Condition','Field Flux')
      CALL ListInitElementKeyword( Robin_h,'Boundary Condition','Robin Coefficient')
      CALL ListInitElementKeyword( Ext_h,'Boundary Condition','External Field')
      InitHandles = .FALSE.
    END IF
    
    dim = CoordinateSystemDimension()

    CALL GetElementNodes( Nodes, UElement=Element )
    STIFF = 0._dp
    FORCE = 0._dp
    LOAD = 0._dp
           

    ! Numerical integration:
    !-----------------------
    IP = GaussPoints( Element )
    DO t=1,IP % n
      ! Basis function values & derivatives at the integration point:
      !--------------------------------------------------------------
      stat = ElementInfo( Element, Nodes, IP % U(t), IP % V(t), &
              IP % W(t), detJ, Basis, dBasisdx )

      Weight = IP % s(t) * DetJ

      ! Evaluate terms at the integration point:
      !------------------------------------------

      ! Given flux:
      ! -----------
      F = ListGetElementReal( Flux_h, Basis, Element, Found )
      IF( Found ) THEN
        FORCE(1:nd) = FORCE(1:nd) + Weight * F * Basis(1:nd)
      END IF

      ! Robin condition (C*(u-u_0)):
      ! ---------------------------
      C = ListGetElementReal( Robin_h, Basis, Element, Found )

      IF( Found ) THEN
        Ext = ListGetElementReal( Ext_h, Basis, Element, Found )
        DO p=1,nd
          DO q=1,nd
            STIFF(p,q) = STIFF(p,q) + Weight * C * Basis(q) * Basis(p)
          END DO
        END DO
        FORCE(1:nd) = FORCE(1:nd) + Weight * C * Ext * Basis(1:nd)
      END IF
    END DO
    
    CALL DefaultUpdateEquations(STIFF,FORCE,UElement=Element,VecAssembly=VecAsm)
!------------------------------------------------------------------------------
  END SUBROUTINE LocalMatrixBC
!------------------------------------------------------------------------------

!------------------------------------------------------------------------------
END SUBROUTINE AdvDiffSolver
!------------------------------------------------------------------------------
