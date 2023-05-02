%Variables in columns of matrix: holes10/poisson_1_1.dat
%   1: Line Marker
%   2: dofs: temperature
%   3: value: number of partitions
%   4: max: temperature
%   5: norm: temperature
%   6: res: linsys cpu time temperature
%   7: res: linsys real time temperature
%   8: res: solver cpu time heatsolver
%   9: res: solver real time heatsolver

load poisson_1_1.dat
f=poisson_1_1;
fid = fopen('poisson_1_1.dat.marker');

% Read the linear solver strings
clear lins;
i=0;
while 1
  i=i+1;
  str = fgets(fid);
  if(~ischar(str)) 
    break;
  end 
  colpos = strfind(str,':');
  ind = sscanf(str(1:colpos-1),'%d');
  strsize = size(str,2);
  lins(ind)=cellstr(str(colpos+2:strsize));
end 
lins=lins';
fclose(fid);

% plot some timings  
m = 9;
[x,xperm]=sort(f(:,m));
for i=1:size(xperm,1)
  fprintf('%30s :: %f\n',char(lins(f(xperm(i),1))),f(xperm(i),m))
end 
