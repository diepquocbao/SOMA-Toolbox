function [x, fval, exitflag, mig, FEs, history, message] = soma_pareto(evalPop, pop, fit, FEs, lb, ub, cfg)
%SOMA_PARETO Pareto-based Self-Organizing Migrating Algorithm.
%   Every migration the population is sorted and the Pareto principle drives
%   the Organization process: the Leader is drawn from the best C = 4% of the
%   population and the Migrant from the band between A = 20% and A+D = 36%.
%   The Migrant jumps NJump times toward the Leader. Control parameters adapt
%   with the consumed budget (paper Eq. 4-6, with T1 = T2 = 1):
%       PRT  = 0.50 + 0.45*cos(pi*FEs/MaxFEs + pi)
%       Step = 0.35 + 0.15*cos(pi*FEs/MaxFEs)
%       PRTVector_j = 1 if rand_j < PRT, else FEs/MaxFEs   (soft PRT vector)
%
%   Port of the author's 2020 reference implementation (Quoc Bao Diep),
%   transposed to row-individuals. The soft PRT vector of paper Eq. 6 is
%   enabled by default; see DEVIATIONS.md.
%   Reference:
%     Q. B. Diep, I. Zelinka, S. Das, "Self-Organizing Migrating Algorithm
%     Pareto", MENDEL 25(1):111-120, 2019. DOI 10.13164/mendel.2019.1.111.

NJump = round(cfg.params.NJump);
softPRT = cfg.params.PRTVectorMode ~= "binary";   % adaptive (paper Eq.6) vs classical
NP = size(pop, 1);
D = size(pop, 2);

% Pareto group sizes (reference code uses ceil of 4%/20%/16%).
C = ceil(NP * 0.04);
A = ceil(NP * 0.20);
G = ceil(NP * 0.16);   % width of the Migrant band ("D" in the reference code)

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

    % Adaptive control parameters (paper Eq. 4-5 with T1 = T2 = 1).
    t = FEs / cfg.MaxFunctionEvaluations;
    PRT  = 0.50 + 0.45 * cos(pi * t + pi);
    Step = 0.35 + 0.15 * cos(pi * t);
    steps = (1:NJump).' * Step;

    % Organization: sort, then pick Leader and Migrant by the Pareto rule.
    [fit, order] = sort(fit);
    pop = pop(order, :);
    idMigrant = randi([A + 1, A + G]);
    idLeader = randi([1, C]);
    migrant = pop(idMigrant, :);
    leader = pop(idLeader, :);

    % Migration: soft PRT vector (paper Eq. 6) unless PRTVectorMode="binary".
    PRTVector = double(rand(NJump, D) < PRT);
    if softPRT
        PRTVector(PRTVector == 0) = t;
    end
    path = migrant + (leader - migrant) .* steps .* PRTVector;
    path = somaApplyBoundary(path, lb, ub, cfg.BoundaryHandling);
    cost = evalPop(path);
    FEs = FEs + NJump;

    % Update: accept the best jump if it does not worsen the Migrant.
    [minCost, idz] = min(cost);
    if minCost <= fit(idMigrant)
        pop(idMigrant, :) = path(idz, :);
        fit(idMigrant) = minCost;
        if minCost <= fval
            fval = minCost;
            x = path(idz, :);
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
