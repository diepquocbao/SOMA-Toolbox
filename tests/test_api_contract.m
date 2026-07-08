function tests = test_api_contract
%TEST_API_CONTRACT Contract tests for the public soma/somaoptions API.
tests = functiontests(localfunctions);
end

function opts = smallOpts(varargin)
opts = somaoptions('Variant','AllToOne', 'Seed',1, 'Display','off', ...
    'PopulationSize',10, 'MaxFunctionEvaluations',2000, varargin{:});
end

function testInvalidVariant(t)
t.verifyError(@() somaoptions('Variant','NoSuchSOMA'), 'soma:invalidVariant');
end

function testUnknownOption(t)
t.verifyError(@() somaoptions('Bogus', 42), 'soma:unknownOption');
end

function testUnknownOptionStructField(t)
s = somaoptions(); s2 = s; s2.NotAField = 1;
t.verifyError(@() somamin(@(x)sum(x.^2), 2, -1, 1, s2), 'soma:unknownOption');
end

function testUnboundedCallErrors(t)
t.verifyError(@() somamin(@(x)sum(x.^2), 3), 'soma:unboundedProblem');
t.verifyError(@() somamin(@(x)sum(x.^2), 3, -Inf, Inf, smallOpts()), 'soma:unboundedProblem');
end

function testInvalidBounds(t)
t.verifyError(@() somamin(@(x)sum(x.^2), 2, 5, -5, smallOpts()), 'soma:invalidBounds');
t.verifyError(@() somamin(@(x)sum(x.^2), 2, [-1 -1 -1], 1, smallOpts()), 'soma:invalidBounds');
end

function testNaNObjective(t)
t.verifyError(@() somamin(@(x) nan, 2, -1, 1, smallOpts()), 'soma:objectiveNaN');
end

function testObjectiveErrorWrapped(t)
t.verifyError(@() somamin(@(x) error('user:boom','no'), 2, -1, 1, smallOpts()), 'soma:objectiveError');
end

function testObjectiveSizeVectorized(t)
badFun = @(X) ones(size(X,1)+1, 1);   % wrong length on purpose
t.verifyError(@() somamin(badFun, 2, -1, 1, smallOpts('UseVectorized',true)), 'soma:objectiveSize');
end

function testFourOutputsAndFields(t)
[x, fval, exitflag, output] = somamin(@(x)sum(x.^2), 3, -5, 5, smallOpts());
t.verifySize(x, [1 3]);
t.verifyGreaterThanOrEqual(x, -5); t.verifyLessThanOrEqual(x, 5);
t.verifyTrue(isscalar(fval) && isfinite(fval));
t.verifyEqual(exitflag, 0);   % budget exhaustion is the expected stop here
t.verifyTrue(all(isfield(output, {'variant','migrations','funccount','message','rngstate','bestfval'})));
t.verifyEqual(output.variant, 'AllToOne');
t.verifyLessThanOrEqual(output.funccount, 2000);
end

function testObjectiveLimit(t)
[~, fval, exitflag] = somamin(@(x)sum(x.^2), 3, -5, 5, ...
    smallOpts('ObjectiveLimit', 1e-1, 'MaxFunctionEvaluations', 30000));
t.verifyEqual(exitflag, 1);
t.verifyLessThanOrEqual(fval, 1e-1);
end

function testStallStop(t)
% A flat objective cannot improve, so the stall criterion must fire.
[~, ~, exitflag, output] = somamin(@(x) 1, 3, -5, 5, ...
    smallOpts('MaxStallMigrations', 3, 'MaxFunctionEvaluations', 1e6));
t.verifyEqual(exitflag, 3);
t.verifyLessThanOrEqual(output.migrations, 10);
end

function testDegenerateBounds(t)
f = @() somamin(@(x)sum(x.^2), 3, 2, 2, smallOpts());
[x, fval, exitflag] = t.verifyWarning(f, 'soma:degenerateBounds');
t.verifyEqual(x, [2 2 2]);
t.verifyEqual(fval, 12);
t.verifyEqual(exitflag, 1);
end

function testBudgetExhaustedAtInit(t)
f = @() somamin(@(x)sum(x.^2), 3, -5, 5, smallOpts('MaxFunctionEvaluations', 5));
[~, ~, exitflag] = t.verifyWarning(f, 'soma:budgetExhaustedAtInit');
t.verifyEqual(exitflag, 0);
end

function testPopulationTooSmall(t)
opts = somaoptions('PopulationSize', 1, 'Display', 'off');
t.verifyError(@() somamin(@(x)sum(x.^2), 2, -1, 1, opts), 'soma:populationTooSmall');
end

function testProblemStruct(t)
problem.objective = @(x)sum(x.^2);
problem.nvars = 2;
problem.lb = -3;
problem.ub = 3;
problem.options = smallOpts();
[x, fval] = somamin(problem);
t.verifySize(x, [1 2]);
t.verifyTrue(isfinite(fval));
end

function testInitialPopulationPartialAndClipped(t)
init = [10 10; 0.5 0.5];               % first row is out of bounds
opts = smallOpts('InitialPopulation', init);
f = @() somamin(@(x)sum(x.^2), 2, -1, 1, opts);
t.verifyWarning(f, 'soma:initialPopulationClipped');
end

function testInvalidInitialPopulation(t)
opts = smallOpts('InitialPopulation', ones(3, 5));   % wrong column count
t.verifyError(@() somamin(@(x)sum(x.^2), 2, -1, 1, opts), 'soma:invalidInitialPopulation');
end

function testIgnoredVariantOptionWarns(t)
opts = smallOpts('NJump', 20);          % NJump does not apply to AllToOne
f = @() somamin(@(x)sum(x.^2), 2, -1, 1, opts);
t.verifyWarning(f, 'soma:ignoredVariantOption');
end

function testOutputFcnStops(t)
stopper = @(ov, state) ov.iteration >= 2;
opts = smallOpts('OutputFcn', stopper, 'MaxFunctionEvaluations', 1e6);
[~, ~, exitflag, output] = somamin(@(x)sum(x.^2), 3, -5, 5, opts);
t.verifyEqual(exitflag, -1);
t.verifyLessThanOrEqual(output.migrations, 2);
end

function testRecordHistoryMonotone(t)
opts = smallOpts('RecordHistory', true);
[~, ~, ~, output] = somamin(@(x)sum(x.^2), 3, -5, 5, opts);
h = output.bestfvalhistory;
t.verifyGreaterThan(numel(h), 1);
t.verifyLessThanOrEqual(max(diff(h)), 0 + eps);   % non-increasing
end
