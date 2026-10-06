! Updated version where all parameters may be set.

MODULE FilterParams

  USE DefUtils

  IMPLICIT NONE  
  LOGICAL, SAVE :: InitDone = .FALSE.
  REAL(KIND=dp), SAVE :: te, fa, fe, df, a, b, c0, kc

  TYPE(ValueList_t), POINTER :: Vlist

CONTAINS 

  SUBROUTINE InitFilter(model)
    TYPE(Model_t) :: model
    
    IF(InitDone) RETURN
    Vlist => Model % Simulation

    ! Original values
    ! te = 151
    ! fa = 35.0D09
    ! fe = 38.0D09
    ! $a = 25.4e-03*0.28

    te = ListGetInteger( VList,'Timestep Intervals')
    fa = ListGetConstReal( Vlist,'Filter fa')
    fe = ListGetConstReal( Vlist,'Filter fe')
    a = ListGetConstReal( Vlist,'Filter a')

    b = a/2
    c0 = 1/SQRT(8.854D-12*4.0*pi*1D-7)
    kc = pi/a
    
    IF( te==1 ) THEN
      df = 0.0_dp
    ELSE
      df = (fe-fa)/(te-1.0)
    END IF
      
    InitDone = .TRUE.

  END SUBROUTINE InitFilter

END MODULE FilterParams


FUNCTION omega( model, n, time ) RESULT(omg)
  USE DefUtils
  USE FilterParams 

  IMPLICIT NONE
  ! variables in function header
  TYPE(Model_t) :: model
  INTEGER :: n
  REAL(KIND=dp) :: time, omg

  CALL InitFilter(model)

  IF( te == 1 ) THEN
    omg = pi*(fa+fe)
  ELSE
    omg = 2.0*pi*(df*(time-1.0)+fa)
  END IF
    
END FUNCTION omega

FUNCTION betaNull( model, n, time ) RESULT(bt0)
  USE DefUtils
  USE FilterParams
  IMPLICIT None

  TYPE(Model_t) :: model
  INTEGER :: n
  REAL(KIND=dp) :: time, omg
  REAL(KIND=dp) :: k0, bt0

  CALL InitFilter(model)
  
  IF( te == 1 ) THEN
    omg = pi*(fa+fe)
  ELSE
    omg = 2.0*pi*(df*(time-1.0)+fa)
  END IF
  k0 = omg/c0
  bt0 = sqrt(k0**2.0-kc**2.0)

END FUNCTION betaNull


FUNCTION MagnBndLoad( model, n, time ) RESULT(mbl)
  USE DefUtils
  USE FilterParams
  IMPLICIT NONE

  TYPE(Model_t) :: model
  INTEGER :: n
  REAL(KIND=dp) :: time, mbl
  REAL(KIND=dp) :: x, y, z
  REAL(KIND=dp) :: omg, k0, bt0

  TYPE(Variable_t), POINTER :: TimeVar

  CALL InitFilter(model)
  
  x = Model % Nodes % x(n)
  IF( te == 1 ) THEN
    omg = pi*(fa+fe)
  ELSE
    omg = 2.0*pi*(df*(time-1.0)+fa)
  END IF
  k0 = omg/c0
  bt0 = sqrt(k0**2.0-kc**2.0)
  mbl = -2.0*bt0*k0/kc*sin(kc*(x+a/2.0))

END FUNCTION MagnBndLoad
