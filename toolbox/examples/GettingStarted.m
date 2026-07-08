%% Getting Started with the SOMA Toolbox
% This script introduces the SOMA Toolbox: a unified interface to the family
% of Self-Organizing Migrating Algorithms. It requires only base MATLAB.
%
% Run it section by section (Ctrl+Enter) or all at once.

%% 1. The simplest call
% Minimize the sphere function in 5 dimensions over the box [-100, 100].
% FUN receives a 1-by-nvars row vector and returns a scalar.
rng(0);
fun   = @(x) sum(x.^2);
nvars = 5;
lb    = -100;
ub    =  100;

x = somamin(fun, nvars, lb, ub);
fprintf('Best point found (first 3 coords): [%.3g %.3g %.3g ...]\n', x(1), x(2), x(3));

%% 2. Getting more information back
% soma follows the Global Optimization Toolbox calling convention:
%   [x, fval, exitflag, output] = somamin(...)
[x, fval, exitflag, output] = somamin(fun, nvars, lb, ub);
fprintf('fval = %.4g, exitflag = %d\n', fval, exitflag);
fprintf('variant = %s, migrations = %d, funccount = %d\n', ...
    output.variant, output.migrations, output.funccount);

%% 3. Choosing a variant and options with somaoptions
% Pick any of: AllToOne (default), AllToAll, AllToAllAdaptive, AllToRand,
% T3A, Pareto, iSOMA. Defaults are the values published for each variant.
opts = somaoptions('Variant', 'T3A', 'Display', 'iter', 'Seed', 1, ...
    'MaxFunctionEvaluations', 3e4);
[x, fval] = somamin(fun, nvars, lb, ub, opts);
fprintf('T3A best fval = %.4g\n', fval);

%% 4. Reproducibility
% Set a Seed for bit-exact repeatability. Two runs with the same seed match.
opts = somaoptions('Variant', 'Pareto', 'Seed', 42, 'Display', 'off');
[~, f1] = somamin(fun, nvars, lb, ub, opts);
[~, f2] = somamin(fun, nvars, lb, ub, opts);
fprintf('Two seeded runs identical: %d (f1=%.6g, f2=%.6g)\n', isequal(f1, f2), f1, f2);

%% 5. Vectorized objectives are much faster
% If your objective can score a whole population at once (an N-by-nvars matrix
% returning an N-by-1 column), set UseVectorized = true.
funVec = @(X) sum(X.^2, 2);
opts = somaoptions('Variant', 'iSOMA', 'UseVectorized', true, 'Seed', 7, ...
    'MaxFunctionEvaluations', 5e4, 'Display', 'off');
tic;
[~, fval] = somamin(funVec, 30, -100, 100, opts);
fprintf('iSOMA on 30-D sphere: fval = %.4g (%.2f s)\n', fval, toc);

%% 6. A harder function: Rastrigin
% A highly multimodal benchmark. Compare two variants on the same budget.
rastrigin = @(X) sum(X.^2 - 10*cos(2*pi*X) + 10, 2);
for v = ["AllToOne", "iSOMA"]
    opts = somaoptions('Variant', v, 'UseVectorized', true, 'Seed', 3, ...
        'MaxFunctionEvaluations', 5e4, 'Display', 'off');
    [~, fval] = somamin(rastrigin, 10, -5.12, 5.12, opts);
    fprintf('%-10s Rastrigin(10-D) fval = %.4g\n', v, fval);
end

%% Next steps
% * Example_PID_Tuning.m       - tune a PID controller (an engineering problem)
% * Example_PressureVessel.m   - a constrained engineering design problem
% * help soma / help somaoptions - full documentation
