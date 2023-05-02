These are some old Matlab/Octave scripts that could be used for inspiration.

1) timecomp.m + poisson_1_1*
- files show how to use the line marker

2) solution_scale*.png
- examples showing how one could plot the scaling
  * Assumes a*(n/1e6)^b
  * Uses 1M dofs as the unit
  * a is then time needed for 1M dofs
  * b is the scaling law, ideally ~1, typically ~1.1--2.0
  
Below is some saved *.m code that could help in making such figures.

xa=N/1e6;
ca = polyfit(log(xa),log(Ta),1);
loglog(xa,Ta,'o',xa,exp(polyval(ca,log(xa))));

xlabel('N_n (M)');
ylabel('T (s)');
title('CPU time for structured ElmerGrid meshing')
at=exp(ca(2)),bt=ca(1)

text(x0,y2,'T = a N_n^b');
[str,err]=sprintf('a = %.3f s/M\n',at);
text(x0,y1,str);
[str,err]=sprintf('b = %.3f\n',bt);
text(x0,y0,str);




