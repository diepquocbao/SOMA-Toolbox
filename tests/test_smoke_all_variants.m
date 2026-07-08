function tests = test_smoke_all_variants
%TEST_SMOKE_ALL_VARIANTS Every implemented variant runs on standard functions.
tests = functiontests(localfunctions);
end

function variants = implementedVariants()
variants = ["AllToOne", "AllToAll", "AllToAllAdaptive", "AllToRand", ...
    "T3A", "Pareto", "iSOMA"];
end

function s = sphere(x),     s = sum(x.^2, 2); end
function s = rosenbrock(x), s = sum(100*(x(:,2:end) - x(:,1:end-1).^2).^2 + (1 - x(:,1:end-1)).^2, 2); end
function s = rastrigin(x),  s = sum(x.^2 - 10*cos(2*pi*x) + 10, 2); end

function testAllVariantsAllFunctions(t)
funs = {@sphere, @rosenbrock, @rastrigin};
dims = [2 10];
budget = 5000;
for v = implementedVariants()
    for fi = 1:numel(funs)
        for D = dims
            opts = somaoptions('Variant', v, 'Seed', 42, 'Display', 'off', ...
                'UseVectorized', true, 'MaxFunctionEvaluations', budget);
            [x, fval, exitflag, output] = somamin(funs{fi}, D, -5, 5, opts);
            label = sprintf('%s / fun%d / D=%d', v, fi, D);
            t.verifySize(x, [1 D], label);
            t.verifyTrue(all(x >= -5 & x <= 5), label);
            t.verifyTrue(isfinite(fval), label);
            t.verifyGreaterThanOrEqual(exitflag, -1, label);
            t.verifyLessThanOrEqual(output.funccount, budget, label);
        end
    end
end
end

function testOptimizesSphere(t)
% Sanity: with a reasonable budget the optimizer must actually optimize.
% The AllToAll family spends NP*(NP-1)*nJump evaluations per migration, so it
% gets a larger budget to complete enough migrations.
for v = implementedVariants()
    if ismember(v, ["AllToAll", "AllToAllAdaptive"])
        budget = 2e5;
    else
        budget = 3e4;
    end
    opts = somaoptions('Variant', v, 'Seed', 7, 'Display', 'off', ...
        'UseVectorized', true, 'MaxFunctionEvaluations', budget);
    [~, fval] = somamin(@(X) sum(X.^2, 2), 10, -100, 100, opts);
    t.verifyLessThan(fval, 1e-2, sprintf('%s failed to reduce sphere below 1e-2', v));
end
end

function testBoundaryModes(t)
for mode = ["reinitialize", "clip", "reflect"]
    opts = somaoptions('Seed', 3, 'Display', 'off', 'BoundaryHandling', mode, ...
        'MaxFunctionEvaluations', 3000, 'UseVectorized', true);
    [x, fval] = somamin(@(X) sum(X.^2, 2), 4, -2, 2, opts);
    t.verifyTrue(all(x >= -2 & x <= 2), char(mode));
    t.verifyTrue(isfinite(fval), char(mode));
end
end
