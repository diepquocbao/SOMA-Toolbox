function [x, fval, exitflag, mig, FEs, history, message] = soma_alltoalladaptive(evalPop, pop, fit, FEs, lb, ub, cfg)
%SOMA_ALLTOALLADAPTIVE SOMA AllToAll with adaptive perturbation.
%   Same all-to-all topology and immediate (asynchronous) update as
%   soma_alltoall, but the PRT perturbation probability ADAPTS with the
%   consumed evaluation budget using the SOMA T3A schedule
%       PRT = 0.05 + 0.90 * FEs/MaxFEs
%   so the search explores broadly early (low PRT) and focuses later (high
%   PRT). This is the SOMA sense of "adaptive": adaptive control parameters
%   (as in T3A), reusing that published schedule rather than a fixed PRT.
%
%   Provided as a classical strategy; there is no separate published
%   reproduction target for this variant (the papers baseline AllToOne and
%   AllToAll). See DEVIATIONS.md.

PathLength = cfg.params.PathLength;
Step = cfg.params.Step;

steps = (0:Step:PathLength).';
nJump = numel(steps);
NP = size(pop, 1);
D = size(pop, 2);

[fval, idBest] = min(fit);
x = pop(idBest, :);

mig = 0;
stall = 0;
history = zeros(1, 0);
exitflag = [];
message = '';

ov = struct('iteration', 0, 'funccount', FEs, 'bestfval', fval, 'bestx', x);
if somaHooks("init", cfg, ov)
    exitflag = -1; message = 'Stopped by an output or plot function.';
end

while isempty(exitflag)
    if FEs + nJump > cfg.MaxFunctionEvaluations
        exitflag = 0; message = 'Maximum number of function evaluations reached.'; break
    end
    if mig >= cfg.MaxMigrations
        exitflag = 0; message = 'Maximum number of migrations reached.'; break
    end

    mig = mig + 1;
    fvalBefore = fval;
    PRT = 0.05 + 0.90 * (FEs / cfg.MaxFunctionEvaluations);   % adaptive (T3A schedule)
    outOfBudget = false;

    for j = 1:NP
        for i = 1:NP
            if i == j
                continue
            end
            if FEs + nJump > cfg.MaxFunctionEvaluations
                outOfBudget = true;
                break
            end
            startPos = pop(j, :);
            target = pop(i, :);
            PRTVector = rand(nJump, D) < PRT;
            path = startPos + (target - startPos) .* steps .* PRTVector;
            path = somaApplyBoundary(path, lb, ub, cfg.BoundaryHandling);
            cost = evalPop(path);
            FEs = FEs + nJump;
            [minCost, idz] = min(cost);
            if minCost <= fit(j)
                pop(j, :) = path(idz, :);
                fit(j) = minCost;
                if minCost < fval
                    fval = minCost;
                    x = path(idz, :);
                end
            end
        end
        if outOfBudget
            break
        end
    end

    if cfg.RecordHistory
        history(1, mig) = fval; %#ok<AGROW>
    end
    if fvalBefore - fval > cfg.FunctionTolerance
        stall = 0;
    else
        stall = stall + 1;
    end

    ov = struct('iteration', mig, 'funccount', FEs, 'bestfval', fval, 'bestx', x);
    if somaHooks("iter", cfg, ov)
        exitflag = -1; message = 'Stopped by an output or plot function.'; break
    end
    if fval <= cfg.ObjectiveLimit
        exitflag = 1; message = 'ObjectiveLimit reached.'; break
    end
    if stall >= cfg.MaxStallMigrations
        exitflag = 3; message = sprintf('No improvement above FunctionTolerance for %d migrations.', stall); break
    end
end

ov = struct('iteration', mig, 'funccount', FEs, 'bestfval', fval, 'bestx', x);
somaHooks("done", cfg, ov);
end
