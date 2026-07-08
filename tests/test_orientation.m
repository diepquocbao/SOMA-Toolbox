function tests = test_orientation
%TEST_ORIENTATION Row-individual convention and vectorization equivalence.
tests = functiontests(localfunctions);
end

function testVectorizedEqualsScalar(t)
% Same seed => identical random stream => identical results, because
% objective evaluation must not consume random numbers in either mode.
base = {'Seed', 77, 'Display', 'off', 'MaxFunctionEvaluations', 4000};
optsScalar = somaoptions(base{:}, 'UseVectorized', false);
optsVector = somaoptions(base{:}, 'UseVectorized', true);
fScalar = @(x) sum(x.^2);        % row in, scalar out
fVector = @(X) sum(X.^2, 2);     % matrix in, column out
[x1, f1, ~, o1] = somamin(fScalar, 6, -10, 10, optsScalar);
[x2, f2, ~, o2] = somamin(fVector, 6, -10, 10, optsVector);
t.verifyEqual(x1, x2, 'AbsTol', 0);
t.verifyEqual(f1, f2, 'AbsTol', 0);
t.verifyEqual(o1.funccount, o2.funccount);
end

function testObjectiveReceivesRows(t)
% Every scalar-mode call must receive a 1-by-nvars row vector.
nvars = 4;
seenSizes = {};
    function s = probe(x)
        seenSizes{end+1} = size(x); %#ok<AGROW>
        s = sum(x.^2);
    end
opts = somaoptions('Seed', 5, 'Display', 'off', 'MaxFunctionEvaluations', 500);
somamin(@probe, nvars, -1, 1, opts);
allRows = all(cellfun(@(sz) isequal(sz, [1 nvars]), seenSizes));
t.verifyTrue(allRows, 'Objective must always receive 1-by-nvars rows.');
end

function testVectorizedReceivesMatrix(t)
nvars = 3;
maxRows = 0;
    function s = probeV(X)
        maxRows = max(maxRows, size(X,1));
        t.verifyEqual(size(X,2), nvars);
        s = sum(X.^2, 2);
    end
opts = somaoptions('Seed', 5, 'Display', 'off', 'MaxFunctionEvaluations', 800, 'UseVectorized', true);
somamin(@probeV, nvars, -1, 1, opts);
t.verifyGreaterThan(maxRows, 1, 'Vectorized mode must batch multiple rows per call.');
end
