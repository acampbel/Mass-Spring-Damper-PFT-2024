function [x, t] = simulateSystem(design)

if ~isstruct(design) || ~all(isfield(design,{'c','k'}))
    error('simulateSystem:InvalidDesign:ShouldBeStruct', ...
        'The design should be a structure with fields "c" and "k"');
end

% Design variables
c = design.c;
k = design.k;


% Constant variables
z0 = [-.1; 0];  % Initial Position and Velocity
m = 1500;        % Mass

odefun = @(t,z) [0 1; -k/m -c/m]*z;
[t, z] = ode45(odefun, [0, 1], z0);

% The first column is the position (displacement from equilibrium)
x = z(:, 1);


