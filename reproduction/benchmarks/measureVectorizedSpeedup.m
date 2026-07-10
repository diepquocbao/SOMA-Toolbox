function measureVectorizedSpeedup()
%MEASUREVECTORIZEDSPEEDUP Runtime: UseVectorized true vs false (paper Tab 5).
%   For each variant, run the same seeded optimization of two classic test
%   functions (sphere, rastrigin; D=30, MaxFEs=1e5) with a scalar objective
%   and a vectorized objective, and report wall-clock time and speedup.
%   Writes ToolboxResults/vectorized_speedup.csv.
%
%   NOTE: run on an otherwise idle machine — wall-clock timings.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), 'toolbox'));
outCsv = fullfile(fileparts(here), 'ToolboxResults', 'vectorized_speedup.csv');

variants = ["AllToOne","AllToAll","AllToAllAdaptive","AllToRand","T3A","Pareto","iSOMA"];
problems = struct( ...
    'name', {"sphere", "rastrigin"}, ...
    'fScalar', {@(x) sum(x.^2), @(x) sum(x.^2 - 10*cos(2*pi*x) + 10)}, ...
    'fVec',    {@(X) sum(X.^2, 2), @(X) sum(X.^2 - 10*cos(2*pi*X) + 10, 2)}, ...
    'lb', {-100, -5.12}, 'ub', {100, 5.12});
D = 30; maxFEs = 1e5; seed = 1;

fid = fopen(outCsv, 'w');
fprintf(fid, 'variant,problem,tScalar_s,tVectorized_s,speedup,fvalScalar,fvalVectorized\n');
fclose(fid);

for v = variants
    for p = problems
        base = {'Variant', char(v), 'Seed', seed, 'Display', 'off', ...
                'MaxFunctionEvaluations', maxFEs};
        % warm-up (JIT) then timed run, each mode
        opts = somaoptions(base{:}, 'UseVectorized', false);
        somamin(p.fScalar, D, p.lb, p.ub, opts);
        t0 = tic; [~, fS] = somamin(p.fScalar, D, p.lb, p.ub, opts); tS = toc(t0);

        opts = somaoptions(base{:}, 'UseVectorized', true);
        somamin(p.fVec, D, p.lb, p.ub, opts);
        t0 = tic; [~, fV] = somamin(p.fVec, D, p.lb, p.ub, opts); tV = toc(t0);

        fid = fopen(outCsv, 'a');
        fprintf(fid, '%s,%s,%.3f,%.3f,%.2f,%.6e,%.6e\n', v, p.name, tS, tV, tS/tV, fS, fV);
        fclose(fid);
        fprintf('%-16s %-9s scalar %.2fs vectorized %.2fs speedup %.1fx\n', ...
            v, p.name, tS, tV, tS/tV);
    end
end
fprintf('measureVectorizedSpeedup COMPLETE -> %s\n', outCsv);
end
