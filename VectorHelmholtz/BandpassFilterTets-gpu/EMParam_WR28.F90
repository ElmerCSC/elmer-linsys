FUNCTION omega( model, n, dummyArgument ) RESULT(omg)
  ! modules needed
  USE DefUtils
  IMPLICIT None
  ! variables in function header
  TYPE(Model_t) :: model
  INTEGER :: n, stp
  REAL(KIND=dp) :: dummyArgument, x, y, z
  REAL(KIND=dp) :: fa, fe, a, b, c0, kc, omg, k0, bt0
  INTEGER, SAVE :: te=0
  
  TYPE(Variable_t), POINTER :: TimeVar
  Real(KIND=dp) :: Time

  !x = model % Nodes % x(n)
  !y = model % Nodes % y(n)
  !z = model % Nodes % z(n)
  time = GetTime()
  !stp = GetTimeStep()

  IF(te==0) te = ListGetInteger( Model % Simulation,'Timestep Intervals')
  fa = 35.0D09
  fe = 38.0D09
  a= 25.4D-03*0.28
  b=a/2
  c0=1/sqrt(8.854D-12*4.0*pi*1D-7)
  kc=pi/a

  IF( te == 1 ) THEN
    ! If we have just one value take the average
    omg = 2.0*pi*(fe+fa)/2.0_dp
  ELSE
    omg = 2.0*pi*((fe-fa)/(te-1.0)*(time-1.0)+fa)
  END IF
    
END FUNCTION omega

FUNCTION betaNull( model, n, dummyArgument ) RESULT(bt0)
  ! modules needed
  USE DefUtils
  IMPLICIT None
  ! variables in function header
  TYPE(Model_t) :: model
  INTEGER :: n, stp
  REAL(KIND=dp) :: dummyArgument, x, y, z
  REAL(KIND=dp) :: fa, fe, a, b, c0, kc, omg, k0, bt0, omega
  INTEGER, SAVE :: te=0
  
  TYPE(Variable_t), POINTER :: TimeVar
  Real(KIND=dp) :: Time

  !x = model % Nodes % x(n)
  !y = model % Nodes % y(n)
  !z = model % Nodes % z(n)
  time = GetTime()
  !stp = GetTimeStep()

  IF(te==0) te = ListGetInteger( Model % Simulation,'Timestep Intervals')
!  te = 151
  fa = 35.0D09
  fe = 38.0D09
  a= 25.4D-03*0.28
  b=a/2
  c0=1/sqrt(8.854D-12*4.0*pi*1D-7)
  kc=pi/a

  !omg = omega(model, n, dummyArgument)

  IF(te == 1) THEN
    omg = 2.0*pi*(fe+fa)/2.0_dp
  ELSE
    omg = 2.0*pi*((fe-fa)/(te-1.0)*(time-1.0)+fa)
  END IF
  k0 = omg/c0
  bt0 = sqrt(k0**2.0-kc**2.0)

END FUNCTION betaNull

FUNCTION MagnBndLoad( model, n, dummyArgument ) RESULT(mbl)

  USE DefUtils
  IMPLICIT None
  TYPE(Model_t) :: model
  INTEGER :: n, stp
  REAL(KIND=dp) :: dummyArgument, x, y, z
  REAL(KIND=dp) :: fa, fe, a, b, c0, kc, omg, k0, bt0, mbl
  INTEGER, SAVE :: te=0
  
  TYPE(Variable_t), POINTER :: TimeVar
  Real(KIND=dp) :: Time
  
  x = model % Nodes % x(n)
  !y = model % Nodes % y(n)
  !z = model % Nodes % z(n)
  time = GetTime()
  !stp = GetTimeStep()

  IF(te==0) te = ListGetInteger( Model % Simulation,'Timestep Intervals')
!  te = 151
  fa = 35.0D09
  fe = 38.0D09
  a= 25.4D-03*0.28
  b=a/2
  c0=1/sqrt(8.854D-12*4.0*pi*1D-7)
  kc=pi/a

  IF(te == 1) THEN
    omg = 2.0*pi*(fe+fa)/2.0_dp
  ELSE 
    omg = 2.0*pi*((fe-fa)/(te-1.0)*(time-1.0)+fa)
  END IF
    
  k0 = omg/c0
  bt0 = sqrt(k0**2.0-kc**2.0)
  mbl = -2.0*bt0*k0/kc*sin(kc*(x+a/2.0))

END FUNCTION MagnBndLoad
