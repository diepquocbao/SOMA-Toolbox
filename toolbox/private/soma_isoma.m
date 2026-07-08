function [x, fval, exitflag, mig, FEs, history, message] = soma_isoma(evalPop, pop, fit, FEs, lb, ub, cfg)
%SOMA_ISOMA iSOMA: SOMA with narrowing search space strategy.
%   Every migration, the best n of m randomly sampled individuals migrate.
%   Each migrant jumps toward a Leader (best of k randomly sampled; the
%   second best if the migrant itself is the best) with DESCENDING step
%   (NJump-move+1)*Step, evaluating one jump at a time and stopping the jump
%   sequence at the FIRST improvement (immediate update). Control parameters
%   follow the author's REFERENCE CODE (which generated the published tables),
%   which differs slightly from the paper's idealized equations (see below):
%       PRT = 0.10 + 0.90*FEs/MaxFEs                      (updated per jump)
%       PRTVector_j = 1 if rand_j < PRT, else 0.5*FEs/MaxFEs   (soft PRT vector)
%   Partial replacement: a per-evaluation counter triggers re-initialization of
%   10% of the population when it exceeds 10*PopulationSize while the global best
%   is stagnant (matches the reference code's Count>1000 rule at PopSize=100).
%
%   Port of the author's reference implementations (Quoc Bao Diep, 2020/2022):
%   the mink-selection follows the later layout, the migrant/leader-coincidence
%   rule matches the paper.
%   IMPORTANT (see DEVIATIONS.md): the paper states Eq. 5 PRT = 0.05 + 0.90*t
%   and Eq. 4 soft vector else = t, but the reference code that produced the
%   published CEC2017 results uses 0.10 and 0.5*t and a per-evaluation
%   replacement counter. Only the reference-code values reproduce the published
%   means, so the toolbox follows the reference code by default.
%   Reference:
%     Q. B. Diep, T. C. Truong, S. Das, I. Zelinka, "Self-Organizing
%     Migrating Algorithm with narrowing search space strategy for robot
%     path planning", Applied Soft Computing 116 (2022) 108270.

NJump = round(cfg.params.NJump);
m = round(cfg.params.m);
n = round(cfg.params.n);
k = round(cfg.params.k);
Step = cfg.params.Step;
softPRT = cfg.params.PRTVectorMode ~= "binary";   % adaptive (paper) vs classical

NP = size(pop, 1);
D = size(pop, 2);
if NP < max(m, k)
    error('soma:populationTooSmall', ...
        'Variant "iSOMA" requires PopulationSize >= max(m, k) = %d (got %d).', max(m, k), NP);
end
n = min(n, m);

[fval, idBest] = min(fit);
x = pop(idBest, :);

mig = 0;
stall = 0;
history = zeros(1, 0);
exitflag = [];
message = '';
count = 0;                 % accepted moves that did not improve the global best
fvalStagnant = fval;       % global best value at the last replacement check

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

    % Migrant selection: best n of m randomly sampled individuals.
    M = randperm(NP, m);
    [~, Im] = mink(fit(M), n);

    for j = 1:n
        if FEs + NJump > cfg.MaxFunctionEvaluations
            break                                   % strict budget enforcement
        end
        idMigrant = M(Im(j));

        % Leader: best of k random individuals; second best on coincidence.
        K = randperm(NP, k);
        [~, Ik] = mink(fit(K), 2);
        idLeader = K(Ik(1));
        if idMigrant == idLeader
            idLeader = K(Ik(2));
        end
        migrant = pop(idMigrant, :);
        leader = pop(idLeader, :);

        % Jumping with descending steps, stop at the first improvement.
        move = 1;
        improved = false;
        while ~improved && move <= NJump && FEs < cfg.MaxFunctionEvaluations
            nstep = (NJump - move + 1) * Step;
            t = FEs / cfg.MaxFunctionEvaluations;
            PRT = 0.10 + 0.90 * t;                   % reference code (see DEVIATIONS #8)
            PRTVector = double(rand(1, D) < PRT);
            if softPRT
                PRTVector(PRTVector == 0) = 0.5 * t; % reference soft/adaptive PRTVector
            end
            offspring = migrant + (leader - migrant) .* nstep .* PRTVector;
            offspring = somaApplyBoundary(offspring, lb, ub, cfg.BoundaryHandling);
            newCost = evalPop(offspring);
            FEs = FEs + 1;
            count = count + 1;                       % reference: count every evaluation
            if newCost <= fit(idMigrant)
                improved = true;
                pop(idMigrant, :) = offspring;
                fit(idMigrant) = newCost;
                if newCost <= fval
                    fval = newCost;
                    x = offspring;
                end
            end
            move = move + 1;
        end
    end

    % Partial replacement of the population on long stagnation.
    if count > NP * 10
        rat = round(0.1 * NP);
        if fval == fvalStagnant && rat >= 1 && FEs + rat <= cfg.MaxFunctionEvaluations
            fresh = lb + rand(rat, D) .* (ub - lb);
            freshFit = evalPop(fresh);
            FEs = FEs + rat;
            idx = randperm(NP, rat);
            pop(idx, :) = fresh;
            fit(idx) = freshFit;
        else
            fvalStagnant = fval;
        end
        count = 0;
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
