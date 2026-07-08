function [x, fval, exitflag, mig, FEs, history, message] = soma_t3a(evalPop, pop, fit, FEs, lb, ub, cfg)
%SOMA_T3A Self-Organizing Migrating Algorithm Team To Team Adaptive (T3A).
%   Every migration, m individuals are sampled at random and the best n of
%   them migrate; each migrant jumps NJump times toward a Leader chosen as
%   the best of k randomly sampled individuals. PRT and Step adapt with the
%   consumed evaluation budget:
%       PRT  = 0.05 + 0.90 * FEs/MaxFEs        (paper Eq. 4)
%       Step = 0.15 - 0.08 * FEs/MaxFEs        (paper Eq. 5)
%   If the migrant and the Leader are the same individual the move is
%   skipped (reference behavior).
%
%   Faithful port of the author's 2020 reference implementation (Quoc Bao
%   Diep), transposed to row-individuals.
%   Reference:
%     Q. B. Diep, "Self-Organizing Migrating Algorithm Team To Team
%     Adaptive - SOMA T3A", IEEE CEC 2019, pp. 1182-1187.

NJump = round(cfg.params.NJump);
m = round(cfg.params.m);
n = round(cfg.params.n);
k = round(cfg.params.k);

NP = size(pop, 1);
D = size(pop, 2);
if NP < max(m, k)
    error('soma:populationTooSmall', ...
        'Variant "T3A" requires PopulationSize >= max(m, k) = %d (got %d).', max(m, k), NP);
end
n = min(n, m);   % cannot move more migrants than were sampled

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
    if FEs + NJump > cfg.MaxFunctionEvaluations
        exitflag = 0; message = 'Maximum number of function evaluations reached.'; break
    end
    if mig >= cfg.MaxMigrations
        exitflag = 0; message = 'Maximum number of migrations reached.'; break
    end

    mig = mig + 1;
    fvalBefore = fval;

    % Adaptive control parameters, updated once per migration (reference).
    PRT  = 0.05 + 0.90 * (FEs / cfg.MaxFunctionEvaluations);
    Step = 0.15 - 0.08 * (FEs / cfg.MaxFunctionEvaluations);
    steps = (1:NJump).' * Step;                    % NJump-by-1

    % Migrant selection: best n of m randomly sampled individuals.
    M = randperm(NP, m);
    [~, orderM] = sort(fit(M));
    migrants = M(orderM(1:n));

    for j = 1:n
        if FEs + NJump > cfg.MaxFunctionEvaluations
            break                                   % strict budget enforcement
        end
        % Leader selection: best of k randomly sampled individuals.
        K = randperm(NP, k);
        [~, idxK] = min(fit(K));
        idLeader = K(idxK);
        if migrants(j) == idLeader
            continue                                % migrant coincides with Leader
        end
        migrant = pop(migrants(j), :);
        leader = pop(idLeader, :);

        PRTVector = rand(NJump, D) < PRT;           % one PRT vector per jump
        path = migrant + (leader - migrant) .* steps .* PRTVector;
        path = somaApplyBoundary(path, lb, ub, cfg.BoundaryHandling);
        cost = evalPop(path);
        FEs = FEs + NJump;
        [minCost, idz] = min(cost);
        if minCost <= fit(migrants(j))
            pop(migrants(j), :) = path(idz, :);
            fit(migrants(j)) = minCost;
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
