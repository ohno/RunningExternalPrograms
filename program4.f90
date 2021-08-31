program main
  implicit none
  double precision x, y
  read(5,*) x, y
  write(6,*) 100.*(x*x-y)**2+(1.-x)**2
end program main