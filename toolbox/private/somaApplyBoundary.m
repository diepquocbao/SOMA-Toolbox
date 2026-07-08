function X = somaApplyBoundary(X, lb, ub, mode)
%SOMAAPPLYBOUNDARY Repair out-of-bound rows of X (rows are individuals).
%   MODE "reinitialize" (default in all published SOMA variants): replace each
%   violating entry with a uniform random value inside its bounds.
%   MODE "clip": project onto the bounds. MODE "reflect": mirror once about the
%   violated bound, then clip (safety for far fliers).

switch mode
    case "reinitialize"
        bad = (X < lb) | (X > ub);
        if any(bad(:))
            R = lb + rand(size(X)) .* (ub - lb);
            X(bad) = R(bad);
        end
    case "clip"
        X = min(max(X, lb), ub);
    case "reflect"
        Xl = lb + (lb - X);   % mirror below lower bound
        below = X < lb;
        X(below) = Xl(below);
        Xu = ub - (X - ub);   % mirror above upper bound
        above = X > ub;
        X(above) = Xu(above);
        X = min(max(X, lb), ub);
    otherwise
        error('soma:invalidOptionValue', 'Unknown BoundaryHandling mode "%s".', mode);
end
end
