mlev=5
hmin=10.0
spy=31556926
pa_to_mpa=1.0E-6

-- g=9.81*spy^(2.0)
-- rho=910*spy^(-2.0)*pa_to_mpa
g=9.81
rho=910.0
n=3.0
-- Ao=1.0E-16*(pa_to_mpa^(3))
-- a=0.3
Ao=1.0E-16/spy
a=0.3/spy
L=750.0e03

-- rate factors and molar activiation energies
-- after Paterson 2010
A1 = 2.89165e-13*spy*(pa_to_mpa^3) 
A2 = 2.42736e-02*spy*(pa_to_mpa^3) 
Q1 = 60.0e3
Q2 = 115.0e3


Z=( 5*a*L^4/( 2 * (Ao) * (rho*g)^3 ) )^ (1/8) 

function elev(x,y)
	 r = math.sqrt(x*x + y*y)/L
	 if (r > 1.0) then
	   r = 1.0
	 end  
	 s=( 4 * ( (1/2)^(4/3) - (r/2)^(4/3) ) )^ (3/8)
	 return (Z-hmin)*s + hmin
end	 
