function run_speedup(outDir, nRep)
%RUN_SPEEDUP Vectorized against scalar objective evaluation (Table III).
%   For each variant and test function (sphere, Rastrigin; n = 30, 1e5
%   evaluations, seed 1) the same run is executed once without timing and
%   then timed NREP times (default 21) in each mode, alternating the modes.
%   Writes speedup_timings.csv to OUTDIR. Run on an otherwise idle machine.
if nargin < 2; nRep = 21; end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), 'toolbox'));
if ~exist(outDir, 'dir'); mkdir(outDir); end
variants = ["AllToOne", "AllToAll", "AllToAllAdaptive", "AllToRand", "T3A", "Pareto", "iSOMA"];
prob(1).name = "sphere";    prob(1).fS = @(x) sum(x.^2);
prob(1).fV = @(X) sum(X.^2, 2); prob(1).lb = -100; prob(1).ub = 100;
prob(2).name = "rastrigin"; prob(2).fS = @(x) sum(x.^2 - 10*cos(2*pi*x) + 10);
prob(2).fV = @(X) sum(X.^2 - 10*cos(2*pi*X) + 10, 2); prob(2).lb = -5.12; prob(2).ub = 5.12;
fid = fopen(fullfile(outDir, 'speedup_timings.csv'), 'w');
fprintf(fid, 'variant,problem,repetition,tScalar_s,tVectorized_s\n');
for v = variants
    for p = prob
        base = {'Variant', char(v), 'Seed', 1, 'Display', 'off', 'MaxFunctionEvaluations', 1e5};
        oS = somaoptions(base{:}, 'UseVectorized', false);
        oV = somaoptions(base{:}, 'UseVectorized', true);
        somamin(p.fS, 30, p.lb, p.ub, oS);
        somamin(p.fV, 30, p.lb, p.ub, oV);
        for r = 1:nRep
            t0 = tic; somamin(p.fS, 30, p.lb, p.ub, oS); tS = toc(t0);
            t0 = tic; somamin(p.fV, 30, p.lb, p.ub, oV); tV = toc(t0);
            fprintf(fid, '%s,%s,%d,%.6f,%.6f\n', v, p.name, r, tS, tV);
        end
    end
end
fclose(fid);
end
