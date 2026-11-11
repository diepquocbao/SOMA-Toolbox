function err = pareto_cosine(evalPop, D, lb, ub, maxFEs)
%PARETO_COSINE SOMA Pareto with the cosine PRT and Step schedules printed in
%its article (Eqs. 4-5); otherwise identical to the toolbox Pareto variant
%(soft PRT vector, strict acceptance, population 100, 10 jumps).
NP = 100; NJump = 10; C = NP * 0.04; A = NP * 0.20; G = NP * 0.16;
pop = lb + rand(NP, D) .* (ub - lb);
fit = evalPop(pop);
FEs = NP;
err = min(fit);
while FEs + NJump <= maxFEs && err > 1e-8
    t = FEs / maxFEs;
    PRT = 0.50 + 0.45 * cos(pi * t + pi);
    Step = 0.35 + 0.15 * cos(pi * t);
    [fit, order] = sort(fit);
    pop = pop(order, :);
    idM = randi([A + 1, A + G]);
    idL = randi([1, C]);
    migrant = pop(idM, :);
    leader = pop(idL, :);
    V = double(rand(NJump, D) < PRT);
    V(V == 0) = t;
    path = migrant + (leader - migrant) .* ((1:NJump).' * Step) .* V;
    bad = (path < lb) | (path > ub);
    if any(bad(:))
        R = lb + rand(NJump, D) .* (ub - lb);
        path(bad) = R(bad);
    end
    cost = evalPop(path);
    FEs = FEs + NJump;
    [c, k] = min(cost);
    if c < fit(idM)
        fit(idM) = c;
        pop(idM, :) = path(k, :);
        err = min(err, c);
    end
end
end
