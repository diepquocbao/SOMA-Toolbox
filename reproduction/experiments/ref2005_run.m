function [err, FEs] = ref2005_run(strategy, costFunctionHandle, dim, lo, hi, popSize, step, pathLength, prt, maxFEs)
%REF2005_RUN Run a 2005 MATLAB reference file of a classical SOMA strategy
%under an evaluation budget.
%   STRATEGY is 'all_to_all', 'all_to_all_adaptive' or 'all_to_one_randomly';
%   the reference file soma_<STRATEGY>.m must be on the MATLAB path and is
%   called unmodified. REF2005_OBJECTIVE counts evaluations and stops the
%   run at the number of evaluations the toolbox spends under the same
%   budget (initial population plus whole journeys). ERR is the lowest
%   objective value evaluated.
global REF2005 %#ok<GVMIS>
nSteps = numel(0:step:pathLength);
budget = popSize + floor((maxFEs - popSize) / nSteps) * nSteps;
REF2005 = struct('fun', costFunctionHandle, 'n', 0, 'budget', budget, 'best', Inf);
bounds = repmat([lo hi], dim, 1);
migrations = ceil(maxFEs / (popSize * nSteps)) + 2;
minDiv = -1;
fn = ['soma_' strategy];
try
    evalc('feval(fn, ''ref2005_objective'', bounds, step, pathLength, prt, minDiv, migrations, popSize, [])');
catch stop
    if ~contains(stop.message, 'ref2005 budget reached')
        rethrow(stop);
    end
end
err = REF2005.best;
FEs = REF2005.n;
end
