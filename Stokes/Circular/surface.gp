spy=31556926
pa_to_mpa=1.0E-6

#g=9.81*spy**(2.0)
g=9.81
#rho=910.0*(spy**(-2.0))*pa_to_mpa
rho=910.0

n=3.0
#Ao=1.0E-16*(pa_to_mpa**(3.0))
Ao=1.0E-16/spy
a=0.3/spy
#a=0.3
L=750.0e03
hmin = 10.0

#rate factors and molar activiation energies
#after Paterson 2010
A1 = 2.89165e-13*spy*(pa_to_mpa**3) 
A2 = 2.42736e-02*spy*(pa_to_mpa**3) 
Q1 = 60.0e3
Q2 = 115.0e3


Z(A)=( 5.0*a*(L**4.0)/( 2.0*A*((rho*g)**3.0)) )**(1.0/8.0)
print "Z(",Ao,")=", Z(Ao)
s(r)=( 4.0 * ( (1.0/2.0)**(4.0/3.0) - (r/2.0)**(4.0/3.0) ) )**(3.0/8.0)
plot [r=0:L] (Z(Ao)-hmin)*s(r/L) + hmin
