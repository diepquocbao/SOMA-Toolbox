%% Engineering example: pressure vessel design with SOMA
% The classic pressure vessel design problem minimizes the fabrication cost
% (material, forming, welding) of a cylindrical vessel with hemispherical
% heads, subject to four design constraints. It is a standard constrained
% benchmark; SOMA is a bound-constrained optimizer, so the constraints are
% handled with a static exterior penalty.
%
% Variables:
%   x1 = Ts, shell thickness      x2 = Th, head thickness
%   x3 = R,  inner radius         x4 = L,  cylindrical length
% Best-known cost (with Ts, Th as multiples of 0.0625"): ~6059.71.
%
% Uses only base MATLAB.

%% Problem setup
nvars = 4;
lb = [0.0625, 0.0625,  10,  10];
ub = [6.1875, 6.1875, 200, 200];

penalty = 1e7;                        % static penalty weight
objective = @(x) pressureVesselCost(x, penalty);

%% Optimize
% Averaging several seeds gives a stable picture of a stochastic optimizer.
nRuns = 10;
best = struct('cost', Inf, 'x', []);
costs = zeros(nRuns, 1);
for run = 1:nRuns
    opts = somaoptions('Variant', 'iSOMA', 'Seed', run, ...
        'MaxFunctionEvaluations', 2e4, 'Display', 'off');
    [x, f] = somamin(objective, nvars, lb, ub, opts);
    costs(run) = f;
    if f < best.cost
        best.cost = f;
        best.x = x;
    end
end

fprintf('Penalized cost over %d runs: best = %.2f, mean = %.2f, std = %.2f\n', ...
    nRuns, min(costs), mean(costs), std(costs));

%% Report the best design
x = best.x;
[trueCost, g] = pressureVesselRaw(x);
fprintf('\nBest design:\n');
fprintf('  Ts = %.4f in, Th = %.4f in, R = %.4f in, L = %.4f in\n', x(1), x(2), x(3), x(4));
fprintf('  Fabrication cost = %.2f\n', trueCost);
fprintf('  Constraints g1..g4 (feasible if <= 0): %s\n', mat2str(g, 4));
fprintf('  Feasible: %d\n', all(g <= 1e-6));

% For comparison, the discrete-thickness convention rounds Ts, Th to the
% nearest multiple of 0.0625" (available plate thicknesses).
xd = x;
xd(1:2) = round(xd(1:2) / 0.0625) * 0.0625;
[costD, gD] = pressureVesselRaw(xd);
fprintf('\nWith plate thicknesses rounded to 0.0625" multiples:\n');
fprintf('  Ts = %.4f, Th = %.4f -> cost = %.2f, feasible = %d\n', ...
    xd(1), xd(2), costD, all(gD <= 1e-6));

%% ------------------------------------------------------------------------
% Local functions
% -------------------------------------------------------------------------
function J = pressureVesselCost(x, penalty)
% Penalized objective: fabrication cost plus squared constraint violations.
[cost, g] = pressureVesselRaw(x);
viol = max(0, g);
J = cost + penalty * sum(viol.^2);
end

function [cost, g] = pressureVesselRaw(x)
% Raw fabrication cost and constraint values g (feasible when g <= 0).
Ts = x(1); Th = x(2); R = x(3); L = x(4);
cost = 0.6224*Ts*R*L + 1.7781*Th*R^2 + 3.1661*Ts^2*L + 19.84*Ts^2*R;
g = [ ...
    -Ts + 0.0193*R; ...
    -Th + 0.00954*R; ...
    -pi*R^2*L - (4/3)*pi*R^3 + 1296000; ...
     L - 240];
end
