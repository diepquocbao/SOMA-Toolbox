function pop = somaInitPop(cfg, nvars, lb, ub)
%SOMAINITPOP Build the initial population (rows are individuals).
%   Honors cfg.InitialPopulation (full or partial); remaining rows are drawn
%   uniformly in [lb, ub]. Out-of-bound user rows are clipped with a warning.

NP = cfg.PopulationSize;
pop = lb + rand(NP, nvars) .* (ub - lb);

init = cfg.InitialPopulation;
if isempty(init)
    return
end
if ~(isnumeric(init) && isreal(init) && ismatrix(init)) || size(init, 2) ~= nvars
    error('soma:invalidInitialPopulation', ...
        'InitialPopulation must be a real matrix with %d columns.', nvars);
end
if any(~isfinite(init(:)))
    error('soma:invalidInitialPopulation', 'InitialPopulation must be finite.');
end
r = min(size(init, 1), NP);
rows = double(init(1:r, :));
clipped = min(max(rows, lb), ub);
if any(clipped(:) ~= rows(:))
    warning('soma:initialPopulationClipped', ...
        'Some InitialPopulation entries were outside [lb, ub] and have been clipped.');
end
pop(1:r, :) = clipped;
end
