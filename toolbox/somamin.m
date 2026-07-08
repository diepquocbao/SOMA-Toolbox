function [x, fval, exitflag, output] = somamin(fun, nvars, lb, ub, options)
%SOMAMIN Minimize a function using the Self-Organizing Migrating Algorithm family.
%   X = SOMAMIN(FUN, NVARS, LB, UB) minimizes FUN over the box LB <= x <= UB
%   using the default variant (classical SOMA AllToOne). FUN accepts a
%   1-by-NVARS row vector and returns a scalar. LB and UB are finite scalars
%   or 1-by-NVARS vectors (SOMA requires a bounded search space).
%
%   X = somamin(FUN, NVARS, LB, UB, OPTIONS) uses settings created with
%   SOMAOPTIONS, e.g. somaoptions('Variant',"T3A"). Available variants:
%   AllToOne, AllToAll, AllToAllAdaptive, AllToRand (Zelinka, 2004),
%   T3A (Diep, IEEE CEC 2019), Pareto (Diep, Zelinka, Das, MENDEL 2019),
%   iSOMA (Diep, Truong, Das, Zelinka, Applied Soft Computing, 2022).
%   Each implementation follows its original paper; defaults are the
%   published parameter values.
%
%   X = somamin(PROBLEM) uses a struct with fields: objective, nvars, lb, ub,
%   and (optionally) options.
%
%   [X, FVAL] = somamin(...) also returns the objective value at X.
%
%   [X, FVAL, EXITFLAG, OUTPUT] = somamin(...) returns an exit code and an
%   information struct. EXITFLAG:
%      1  ObjectiveLimit reached (or degenerate bounds lb == ub)
%      0  budget exhausted (MaxFunctionEvaluations or MaxMigrations)
%      3  no improvement for MaxStallMigrations migrations
%     -1  stopped by OutputFcn/PlotFcn
%   OUTPUT fields: variant, migrations, funccount, message, rngstate,
%   bestfvalhistory (when options.RecordHistory is true).
%
%   Example:
%     opts = somaoptions('Variant','AllToOne', 'Seed',1, 'Display','iter');
%     [x, fval] = somamin(@(x) sum(x.^2), 5, -100, 100, opts);
%
%   See also SOMAOPTIONS, SOMAPLOTBESTF.

%   Copyright 2026 Quoc Bao Diep. MIT license.

% ----- Problem-struct form -------------------------------------------------
if nargin == 1
    if isstruct(fun) && all(isfield(fun, {'objective','nvars','lb','ub'}))
        problem = fun;
        fun   = problem.objective;
        nvars = problem.nvars;
        lb    = problem.lb;
        ub    = problem.ub;
        if isfield(problem, 'options') && ~isempty(problem.options)
            options = problem.options;
        end
    else
        error('soma:invalidProblem', ...
            'Single-argument call requires a struct with fields objective, nvars, lb, ub.');
    end
end
if nargin >= 2 && nargin < 4
    error('soma:unboundedProblem', ...
        'SOMA requires finite bounds: call somamin(fun, nvars, lb, ub). Unbounded search is not supported.');
end
if ~exist('options', 'var') || isempty(options)
    options = somaoptions();
elseif ~isstruct(options)
    error('soma:invalidOptionValue', 'OPTIONS must be a struct created by somaoptions.');
else
    options = somaoptions(options);   % normalize/validate a raw struct
end

% ----- Core input validation ------------------------------------------------
if ~isa(fun, 'function_handle')
    error('soma:invalidObjective', 'FUN must be a function handle.');
end
if ~(isnumeric(nvars) && isscalar(nvars) && isreal(nvars) && nvars >= 1 && mod(nvars,1) == 0)
    error('soma:invalidNvars', 'NVARS must be a positive integer scalar.');
end
nvars = double(nvars);
lb = expandBound(lb, nvars, 'LB');
ub = expandBound(ub, nvars, 'UB');
if any(~isfinite(lb)) || any(~isfinite(ub))
    error('soma:unboundedProblem', ...
        'SOMA requires finite bounds on every variable (no Inf/NaN in LB/UB).');
end
if any(lb > ub)
    error('soma:invalidBounds', 'Every element of LB must be <= the matching element of UB.');
end

cfg = somaResolveOptions(options, nvars);

% ----- Reproducibility ------------------------------------------------------
if ~isempty(cfg.Seed)
    previousRng = rng;
    restoreRng = onCleanup(@() rng(previousRng));
    rng(cfg.Seed, 'twister');
end
rngStateAtStart = rng;

evalPop = somaMakeObjective(fun, cfg, nvars);

% ----- Degenerate box: nothing to search ------------------------------------
if all(lb == ub)
    warning('soma:degenerateBounds', ...
        'All bounds satisfy lb == ub; the problem has a single feasible point.');
    x = lb;
    fval = evalPop(x);
    exitflag = 1;
    output = makeOutput(cfg, 0, 1, 'Bounds are degenerate (lb == ub).', rngStateAtStart, fval, []);
    reportFinal(cfg, output);
    return
end

% ----- Initial population -----------------------------------------------------
pop = somaInitPop(cfg, nvars, lb, ub);
fit = evalPop(pop);
FEs = size(pop, 1);
if cfg.MaxFunctionEvaluations <= FEs
    warning('soma:budgetExhaustedAtInit', ...
        'MaxFunctionEvaluations (%d) does not exceed PopulationSize (%d); returning the best initial individual.', ...
        cfg.MaxFunctionEvaluations, FEs);
    [fval, id] = min(fit);
    x = pop(id, :);
    exitflag = 0;
    output = makeOutput(cfg, 0, FEs, 'Function-evaluation budget exhausted by initialization.', ...
        rngStateAtStart, fval, []);
    reportFinal(cfg, output);
    return
end

% ----- Dispatch to the variant implementation --------------------------------
if isempty(cfg.impl)
    error('soma:variantNotImplemented', ...
        'Variant "%s" is registered but not implemented yet in this development version.', cfg.Variant);
end
[x, fval, exitflag, migrations, FEs, history, message] = ...
    cfg.impl(evalPop, pop, fit, FEs, lb, ub, cfg);

output = makeOutput(cfg, migrations, FEs, message, rngStateAtStart, fval, history);
reportFinal(cfg, output);
end

% =============================================================================
function b = expandBound(b, nvars, name)
if ~(isnumeric(b) && isreal(b) && isvector(b))
    error('soma:invalidBounds', '%s must be a real scalar or vector.', name);
end
b = double(b(:).');
if isscalar(b)
    b = repmat(b, 1, nvars);
elseif numel(b) ~= nvars
    error('soma:invalidBounds', '%s must be a scalar or have NVARS = %d elements.', name, nvars);
end
end

function output = makeOutput(cfg, migrations, funccount, message, rngstate, bestfval, history)
output.variant = char(cfg.Variant);
output.migrations = migrations;
output.funccount = funccount;
output.message = message;
output.rngstate = rngstate;
output.bestfval = bestfval;
if cfg.RecordHistory
    output.bestfvalhistory = history;
end
end

function reportFinal(cfg, output)
if cfg.Display ~= "off"
    fprintf('soma (%s): %s Migrations: %d, function evaluations: %d, best f(x): %.6g\n', ...
        output.variant, output.message, output.migrations, output.funccount, output.bestfval);
end
end
