function [x, fval, exitflag, mig, FEs, history, message] = soma_alltorand(evalPop, pop, fit, FEs, lb, ub, cfg)
%SOMA_ALLTORAND Classical SOMA AllToRand (AllToOne-Rand) migration strategy.
%   Like AllToOne, but the migration target is not the best individual:
%   every migration, each individual jumps toward a RANDOMLY selected other
%   individual (chosen from the population as it was at the start of the
%   migration). The best point on the jump path replaces the individual if
%   it is not worse.
%
%   Implemented from the strategy description in:
%     I. Zelinka, "SOMA - Self-Organizing Migrating Algorithm", in New
%     Optimization Techniques in Engineering, Springer, 2004, pp. 167-217.
%   Jump sequence t = 0:Step:PathLength matches this toolbox's AllToOne.

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

    for j = 1:NP
        if FEs + nJump > cfg.MaxFunctionEvaluations
            break                          % strict budget enforcement
        end
        % Random target distinct from the moving individual (current pop).
        idTarget = randi(NP - 1);
        if idTarget >= j
            idTarget = idTarget + 1;
        end
        target = pop(idTarget, :);         % immediate: current population

        PRTVector = rand(nJump, D) < PRT;
        path = pop(j, :) + (target - pop(j, :)) .* steps .* PRTVector;
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
