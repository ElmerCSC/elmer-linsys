resbound = 4.0;
rescent = 50.0;
reshalo = 5.0;
r0 = 750.0;
halo = 50.0;
layersperquarter=20;
//+
Point(1) = {0, 0, 0, rescent};
//+
Point(2) = {r0, 0, 0, resbound};
//+
Point(3) = {r0 + halo, 0.0, 0, reshalo};
//+
Line(1) = {1,2};
Line(2) = {2,3};


//+
Extrude {{0, 0, -1}, {0, 0, 0}, -Pi/2} {
  Line{1,2};
}



//+
Extrude {{0, 0, 1}, {0, 0, 0}, Pi/2} {
  Curve{3}; Curve{6}; 
}
//+
Extrude {{0, 0, 1}, {0, 0, 0}, Pi/2} {
  Curve{10}; Curve{13}; 
}
//+
Extrude {{0, 0, 1}, {0, 0, 0}, Pi/2} {
  Curve{20}; Curve{17}; 
}
//+
Physical Surface(31) = {5, 9, 12, 16, 19, 23, 27, 30};
//+
Physical Curve(32) = {15, 22, 26, 8};
