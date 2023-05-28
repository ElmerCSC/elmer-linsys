mlev=10
hmin=10.0
g=9.81
rho=910
Ao=1/31556926 * 1E-16
a=0.3/31556926
L=750.0e03
Z=( 5*a*L^4/( 2 * Ao * (rho*g)^3 ) )^ (1/8) 

function nodimelev(x,y)
	 r = math.sqrt(x*x + y*y)/L
	 if (r > 1.0) then
	   r = 1.0
	 end  
	 s=( 4 * ( (1/2)^(4/3) - (r/2)^(4/3) ) )^ (3/8)
	 return (Z-hmin)*s + hmin
end	 
