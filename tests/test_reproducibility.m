function tests = test_reproducibility
%TEST_REPRODUCIBILITY Seeded runs are bit-exact; unseeded state is restored.
tests = functiontests(localfunctions);
end

function testSameSeedSameResult(t)
opts = somaoptions('Seed', 123, 'Display', 'off', 'MaxFunctionEvaluations', 4000, ...
    'UseVectorized', true, 'RecordHistory', true);
[x1, f1, ~, o1] = somamin(@(X) sum(X.^2, 2), 5, -10, 10, opts);
[x2, f2, ~, o2] = somamin(@(X) sum(X.^2, 2), 5, -10, 10, opts);
t.verifyEqual(x1, x2);
t.verifyEqual(f1, f2);
t.verifyEqual(o1.funccount, o2.funccount);
t.verifyEqual(o1.bestfvalhistory, o2.bestfvalhistory);
end

function testDifferentSeedDifferentResult(t)
opts1 = somaoptions('Seed', 1, 'Display', 'off', 'MaxFunctionEvaluations', 4000, 'UseVectorized', true);
opts2 = somaoptions(opts1, 'Seed', 2);
[x1] = somamin(@(X) sum(X.^2, 2), 5, -10, 10, opts1);
[x2] = somamin(@(X) sum(X.^2, 2), 5, -10, 10, opts2);
t.verifyNotEqual(x1, x2);
end

function testSeedRestoresGlobalRngState(t)
rng(999, 'twister');
before = rng;
opts = somaoptions('Seed', 5, 'Display', 'off', 'MaxFunctionEvaluations', 2000);
somamin(@(x) sum(x.^2), 3, -1, 1, opts);
after = rng;
t.verifyEqual(after.Type, before.Type);
t.verifyEqual(after.Seed, before.Seed);
t.verifyEqual(after.State, before.State);
end

function testRngStateRecordedInOutput(t)
opts = somaoptions('Seed', 11, 'Display', 'off', 'MaxFunctionEvaluations', 2000);
[~, ~, ~, output] = somamin(@(x) sum(x.^2), 3, -1, 1, opts);
t.verifyTrue(isfield(output, 'rngstate'));
t.verifyEqual(double(output.rngstate.Seed), 11);
end
