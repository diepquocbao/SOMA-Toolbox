function [x, fval, exitflag, mig, FEs, history, message] = soma_alltoall(evalPop, pop, fit, FEs, lb, ub, cfg)
%SOMA_ALLTOALL Classical SOMA AllToAll migration strategy.
%   Every migration, EVERY individual travels toward EVERY other individual.
%   Positions are updated immediately (asynchronously): as soon as an
%   individual's journey toward a target improves it, it moves, and its next
%   journey (and other individuals' journeys) use the updated position. Each
%   journey jumps from the individual's current position toward the target in
%   steps of Step up to PathLength, perturbed dimension-wise by the PRT vector.
%
%   Implemented from the strategy description in Zelinka (2004). The immediate
%   (asynchronous) update reproduces the published SOMA-AllToAll baseline; the
%   synchronous/deferred reading does not (see DEVIATIONS.md).

PathLength = cfg.params.PathLength;
Step = cfg.params.Step;
PRT = cfg.params.PRT;

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
            startPos = pop(j, :);          % immediate: current position
            target = pop(i, :);            % immediate: current population
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
