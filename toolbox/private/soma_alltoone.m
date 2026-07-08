function [x, fval, exitflag, mig, FEs, history, message] = soma_alltoone(evalPop, pop, fit, FEs, lb, ub, cfg)
%SOMA_ALLTOONE Classical SOMA AllToOne migration strategy.
%   In every migration loop the best individual (Leader) is fixed and every
%   other individual jumps toward it in steps of cfg.params.Step up to
%   cfg.params.PathLength, perturbed dimension-wise by the PRT vector; the
%   best point on the path replaces the individual if it is not worse.
%
%   Faithful port of the author's reference implementation (Quoc Bao Diep,
%   2020), transposed to row-individuals.
%   References:
%     I. Zelinka, "SOMA - Self-Organizing Migrating Algorithm", in New
%     Optimization Techniques in Engineering, Springer, 2004, pp. 167-217.
%   Note: like the reference code, the jump sequence is t = 0:Step:PathLength
%   (the t = 0 point re-evaluates the current position). Strict budget
%   enforcement stops before a path that would exceed MaxFunctionEvaluations;
%   both points are recorded in DEVIATIONS.md.

PathLength = cfg.params.PathLength;
Step = cfg.params.Step;
PRT = cfg.params.PRT;

steps = (0:Step:PathLength).';          % nJump-by-1, matches reference code
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
    % ----- Pre-migration stopping checks -----------------------------------
    if FEs + nJump > cfg.MaxFunctionEvaluations
        exitflag = 0; message = 'Maximum number of function evaluations reached.'; break
    end
    if mig >= cfg.MaxMigrations
        exitflag = 0; message = 'Maximum number of migrations reached.'; break
    end

    mig = mig + 1;
    fvalBefore = fval;

    [~, idLeader] = min(fit);           % Leader fixed for the whole migration
    leader = pop(idLeader, :);

    for j = 1:NP
        if j == idLeader
            continue
        end
        if FEs + nJump > cfg.MaxFunctionEvaluations
            break                        % strict budget: skip unaffordable paths
        end
        % One PRT vector per jump, per dimension (reference behavior).
        PRTVector = rand(nJump, D) < PRT;
        path = pop(j, :) + (leader - pop(j, :)) .* steps .* PRTVector;
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

    % ----- Post-migration bookkeeping ---------------------------------------
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
