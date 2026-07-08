function evalPop = somaMakeObjective(fun, cfg, nvars)
%SOMAMAKEOBJECTIVE Wrap the user objective into a batch evaluator.
%   EVALPOP = SOMAMAKEOBJECTIVE(FUN, CFG, NVARS) returns a handle that maps an
%   N-by-NVARS matrix (rows are candidate points) to an N-by-1 column of
%   objective values, regardless of cfg.UseVectorized. All user errors are
%   wrapped with context; NaN objective values are rejected.

evalPop = @(X) evalBlock(fun, X, cfg.UseVectorized, nvars);
end

function s = evalBlock(fun, X, useVectorized, nvars)
n = size(X, 1);
try
    if useVectorized
        s = fun(X);
    else
        s = zeros(n, 1);
        for i = 1:n
            s(i) = fun(X(i, :));
        end
    end
catch userErr
    wrapper = MException('soma:objectiveError', ...
        'The objective function failed on a %d-by-%d input. See cause for details.', n, nvars);
    wrapper = addCause(wrapper, userErr);
    throw(wrapper);
end

if useVectorized
    if isnumeric(s) && isvector(s) && numel(s) == n
        s = double(s(:));
    else
        error('soma:objectiveSize', ...
            'With UseVectorized=true the objective must return %d values for a %d-by-%d input (got size %s).', ...
            n, n, nvars, mat2str(size(s)));
    end
else
    if ~all(arrayfun(@(v) isnumeric(v) && isreal(v), s))
        error('soma:objectiveSize', 'The objective function must return a real numeric scalar.');
    end
end

if any(isnan(s))
    error('soma:objectiveNaN', ...
        'The objective function returned NaN. Return a large finite penalty instead of NaN.');
end
end
