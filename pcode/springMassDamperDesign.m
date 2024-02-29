function design = springMassDamperDesign(dampingType, mass)
% This is the proprietary design of our toolbox
% 
% You can't see inside but I can let you know 
% how to use it if you want.

arguments
    dampingType (1,1) string = "underdamped";
    mass (1,1) double = 1500
end

design.k = 5e5; % Spring Constant

switch dampingType
    case "overdamped"
        design.c = 5e5;
    case "underdamped"
        design.c = 1e4; 
    case "nicelydamped"
        design.c = 3.5e4;
    case "criticallydamped"
        design.c = 2*mass*sqrt(design.k/mass); 
end
end


