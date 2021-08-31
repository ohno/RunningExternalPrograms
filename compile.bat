REM gfortran
for %%F in (*.f90) do (
  gfortran -o %%~nF %%F
)