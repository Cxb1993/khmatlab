function [II, CoM, mass]  = combine_inertia(I1, CoM1, mass1, I2, CoM2, mass2)
%%  [II, CoM, mass]  = combine_inertia(I1, CoM1, mass1, I2, CoM2, mass2)
%% Combines the inertial parameters of two parts of the same rigid body. The CoM and
%% inertia matrices must be with respect to the same coordinate system.

%% Kjartan Halvorsen
%% 2013-08-23

if (nargin == 0)
   do_unit_test();
   return;
end

mass = mass1 + mass2;
CoM = (CoM1*mass1 + CoM2*mass2) / mass;

v1 = CoM1 - CoM;
v2 = CoM2 - CoM;

II = I1 + I2 + mass1 * diag( [v1(2:3)'*v1(2:3)
			      v1([1 3])'*v1([1 3])
			      v1(1:2)'*v1(1:2)] ) ...
    + mass2 * diag( [v2(2:3)'*v2(2:3)
			      v2([1 3])'*v2([1 3])
			      v2(1:2)'*v2(1:2)] );


function do_unit_test()

%% Create two bodies. Known geometries
ex = randn(3,1);
ex = ex / norm(ex);

ey = randn(3,1);
ey = ey - (ey'*ex)*ex;
ey = ey/norm(ey);

ez = cross(ex, ey);

m1 = 1;
m2 = 2;

com1 = [1;0;0];
com2 = [-1;0;0];

I1 = eye(3);
I1(1,3) = 1.1111;
I1(3,1) = 1.1111;

I2 = eye(3);
I2(1,2) = 1.222;
I2(2,1) = 1.222;

[II, com, mass] = combine_inertia(I1, com1, m1, I2, com2, m2);

assert(mass, m1+m2, 1e-14);
assert(com, [-1/3;0;0], 1e-14);

II


