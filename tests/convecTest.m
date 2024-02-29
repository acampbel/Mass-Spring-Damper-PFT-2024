%% Matches Conv Baseline

x = [3-1i, 4+2i, 7-3i];
y = [8-6i, 12+16i, 40-42i];

assert(isequal(convec(x,y), conv(x,y)), ...
    "Mex implmentation of convolution does not match MATLAB builtin");







