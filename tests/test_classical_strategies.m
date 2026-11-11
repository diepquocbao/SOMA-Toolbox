function tests = test_classical_strategies
%TEST_CLASSICAL_STRATEGIES The classical strategies follow their definitions.
%   With PRT = 1 the perturbation vector is all ones, so one migration loop
%   is deterministic. Every path the solver evaluates is then compared with
%   a direct statement of the strategy definition (Zelinka, 2016, Sec. 5):
%     AllToOne          every individual travels toward the Leader;
%     AllToAll          every individual travels toward every other one,
%                       always from the same start position;
%     AllToAllAdaptive  as AllToAll, but each journey starts from the best
%                       position found so far;
%     AllToRand         every individual travels toward one randomly
%                       selected other individual.
tests = functiontests(localfunctions);
end

% ------------------------------------------------------------------ helpers
function [X0, steps, base] = fixedProblem()
X0 = [ 4  3 -2  1;
      -3  5  2 -4;
       1 -2  4  3;
      -5 -1 -3  2;
       2  4  1 -5];
steps = (0:0.25:1).';
base = {'Display', 'off', 'UseVectorized', true, 'Seed', 1, ...
    'InitialPopulation', X0, 'PopulationSize', size(X0, 1), ...
    'PRT', 1, 'Step', 0.25, 'PathLength', 1, 'MaxMigrations', 1};
end

function f = sphere(X)
f = sum(X.^2, 2);
end

function f = recordingSphere(X, calls)
calls(calls.Count + 1) = X;
f = sphere(X);
end

function f = recordingConstant(X, calls)
calls(calls.Count + 1) = X;
f = zeros(size(X, 1), 1);
end

function calls = newLog()
calls = containers.Map('KeyType', 'double', 'ValueType', 'any');
end

% -------------------------------------------------------------------- tests
function testAllToOnePathsFollowDefinition(t)
[X0, steps, base] = fixedProblem();
calls = newLog();
opts = somaoptions('Variant', 'AllToOne', base{:});
[x, fval, ~, output] = somamin(@(X) recordingSphere(X, calls), 4, -10, 10, opts);

NP = size(X0, 1);
pop = X0; fit = sphere(X0);
t.verifyEqual(calls(1), X0, 'AbsTol', 1e-12);
[~, idLeader] = min(fit);
leader = pop(idLeader, :);
k = 1;
for j = 1:NP
    if j == idLeader; continue; end
    k = k + 1;
    expected = pop(j, :) + (leader - pop(j, :)) .* steps;
    t.verifyEqual(calls(k), expected, 'AbsTol', 1e-12, sprintf('individual %d', j));
    [m, id] = min(sphere(expected));
    if m <= fit(j); pop(j, :) = expected(id, :); fit(j) = m; end
end
t.verifyEqual(double(calls.Count), 1 + (NP - 1));
t.verifyEqual(output.funccount, NP + (NP - 1) * numel(steps));
[best, idBest] = min(fit);
t.verifyEqual(fval, best, 'AbsTol', 1e-12);
t.verifyEqual(x, pop(idBest, :), 'AbsTol', 1e-12);
end

function testAllToAllStartsEveryJourneyFromSamePosition(t)
[X0, steps, base] = fixedProblem();
calls = newLog();
opts = somaoptions('Variant', 'AllToAll', base{:});
[x, fval, ~, output] = somamin(@(X) recordingSphere(X, calls), 4, -10, 10, opts);

NP = size(X0, 1);
pop = X0; fit = sphere(X0);
k = 1;
for j = 1:NP
    start = pop(j, :);
    bestPos = start; bestCost = fit(j);
    for i = 1:NP
        if i == j; continue; end
        k = k + 1;
        expected = start + (pop(i, :) - start) .* steps;
        t.verifyEqual(calls(k), expected, 'AbsTol', 1e-12, sprintf('journey %d -> %d', j, i));
        [m, id] = min(sphere(expected));
        if m <= bestCost; bestCost = m; bestPos = expected(id, :); end
    end
    pop(j, :) = bestPos; fit(j) = bestCost;
end
t.verifyEqual(double(calls.Count), 1 + NP * (NP - 1));
t.verifyEqual(output.funccount, NP + NP * (NP - 1) * numel(steps));
[best, idBest] = min(fit);
t.verifyEqual(fval, best, 'AbsTol', 1e-12);
t.verifyEqual(x, pop(idBest, :), 'AbsTol', 1e-12);
end

function testAllToAllAdaptiveStartsFromBestPositionSoFar(t)
[X0, steps, base] = fixedProblem();
calls = newLog();
opts = somaoptions('Variant', 'AllToAllAdaptive', base{:});
[x, fval, ~, output] = somamin(@(X) recordingSphere(X, calls), 4, -10, 10, opts);

NP = size(X0, 1);
pop = X0; fit = sphere(X0);
k = 1;
moved = false;
for j = 1:NP
    for i = 1:NP
        if i == j; continue; end
        k = k + 1;
        start = pop(j, :);
        expected = start + (pop(i, :) - start) .* steps;
        t.verifyEqual(calls(k), expected, 'AbsTol', 1e-12, sprintf('journey %d -> %d', j, i));
        [m, id] = min(sphere(expected));
        if m <= fit(j)
            moved = moved || any(expected(id, :) ~= start);
            pop(j, :) = expected(id, :); fit(j) = m;
        end
    end
end
t.verifyTrue(moved, 'the problem must make at least one individual move between journeys');
t.verifyEqual(double(calls.Count), 1 + NP * (NP - 1));
t.verifyEqual(output.funccount, NP + NP * (NP - 1) * numel(steps));
[best, idBest] = min(fit);
t.verifyEqual(fval, best, 'AbsTol', 1e-12);
t.verifyEqual(x, pop(idBest, :), 'AbsTol', 1e-12);
end

function testAllToAllAndAdaptiveDiffer(t)
% The two strategies must evaluate different points on the same problem.
[~, ~, base] = fixedProblem();
a = newLog(); b = newLog();
somamin(@(X) recordingSphere(X, a), 4, -10, 10, somaoptions('Variant', 'AllToAll', base{:}));
somamin(@(X) recordingSphere(X, b), 4, -10, 10, somaoptions('Variant', 'AllToAllAdaptive', base{:}));
different = false;
for k = 2:double(a.Count)
    different = different || any(any(abs(a(k) - b(k)) > 1e-9));
end
t.verifyTrue(different);
end

function testAllToRandOneJourneyTowardAnotherIndividual(t)
[X0, steps, base] = fixedProblem();
calls = newLog();
opts = somaoptions('Variant', 'AllToRand', base{:});
[x, fval, ~, output] = somamin(@(X) recordingSphere(X, calls), 4, -10, 10, opts);

NP = size(X0, 1);
pop = X0; fit = sphere(X0);
for j = 1:NP
    path = calls(j + 1);
    start = pop(j, :);
    target = path(end, :);                      % t = 1 lands on the target
    others = pop([1:j-1, j+1:NP], :);
    dist = min(max(abs(others - target), [], 2));
    t.verifyLessThan(dist, 1e-12, sprintf('individual %d: target is not another individual', j));
    t.verifyEqual(path, start + (target - start) .* steps, 'AbsTol', 1e-12);
    [m, id] = min(sphere(path));
    if m <= fit(j); pop(j, :) = path(id, :); fit(j) = m; end
end
t.verifyEqual(double(calls.Count), 1 + NP);
t.verifyEqual(output.funccount, NP + NP * numel(steps));
[best, idBest] = min(fit);
t.verifyEqual(fval, best, 'AbsTol', 1e-12);
t.verifyEqual(x, pop(idBest, :), 'AbsTol', 1e-12);
end

function testAllToRandTargetsAreUniformOverOthers(t)
% On a constant objective nobody moves, so every target can be identified.
X0 = [1 1; 2 -3; -4 2; 5 5; -1 -6; 3 -2];
NP = size(X0, 1);
nMig = 300;
calls = newLog();
opts = somaoptions('Variant', 'AllToRand', 'Display', 'off', 'UseVectorized', true, ...
    'Seed', 11, 'InitialPopulation', X0, 'PopulationSize', NP, ...
    'PRT', 1, 'Step', 1, 'PathLength', 1, 'MaxMigrations', nMig);
somamin(@(X) recordingConstant(X, calls), 2, -10, 10, opts);
t.verifyEqual(double(calls.Count), 1 + nMig * NP);
counts = zeros(NP, NP);
for q = 1:nMig * NP
    j = mod(q - 1, NP) + 1;
    path = calls(q + 1);
    t.verifyEqual(path(1, :), X0(j, :), 'AbsTol', 1e-12);
    [d, i] = min(max(abs(X0 - path(end, :)), [], 2));
    t.verifyLessThan(d, 1e-12);
    counts(j, i) = counts(j, i) + 1;
end
t.verifyEqual(diag(counts), zeros(NP, 1), 'an individual travelled toward itself');
off = counts(~eye(NP));
expected = nMig / (NP - 1);
t.verifyGreaterThan(min(off), 0.5 * expected);
t.verifyLessThan(max(off), 1.5 * expected);
end
