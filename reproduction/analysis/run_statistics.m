function run_statistics(pkgDir)
%RUN_STATISTICS Recompute every statistic reported in the article from the
%per-run results of this folder. Writes CSV files to results/statistics.
%   Tables IV(a) and IV(b): repro_comparison.csv, repro_summary.csv,
%   crosscheck_comparison.csv, crosscheck_summary.csv
%   Section 5.3: pareto_schedules.csv
%   Table III: speedup_summary.csv
%   Table V and Section 6: engineering_summary.csv
if nargin < 1; pkgDir = fileparts(fileparts(mfilename('fullpath'))); end
addpath(fileparts(mfilename('fullpath')));
res = fullfile(pkgDir, 'results'); out = fullfile(res, 'statistics');
if ~exist(out, 'dir'); mkdir(out); end
funcs = [1 3:30]; n = 51;
pub = readtable(fullfile(pkgDir, 'published', 'published_summary_CEC2017_D30.csv'));

%% Table IV(a): toolbox against published results
map = {'AllToOne', 'ATO'; 'AllToAllAdaptive', 'ATA'; 'Pareto', 'Pareto'; 'T3A', 'T3A'; 'iSOMA', 'iSOMA'};
rows = {};
for i = 1:size(map, 1)
    X = runs(fullfile(res, 'cec2017', [map{i, 1} '.csv']));
    Yf = fullfile(pkgDir, 'published', 'per_run', [map{i, 1} '.csv']);
    if exist(Yf, 'file'); Y = runs(Yf); else; Y = []; end
    for k = 1:numel(funcs)
        j = find(pub.func == funcs(k), 1);
        y = []; if ~isempty(Y); y = Y(k, :); end
        c = compareSamples(X(k, :), pub.([map{i, 2} '_mean'])(j), pub.([map{i, 2} '_std'])(j), y, n);
        rows(end + 1, :) = {map{i, 1}, funcs(k), c.refMean, c.refStd, c.tbMean, c.tbStd, c.relErrPct, ...
            c.z, c.pZ, double(c.within1sd), c.pTost, double(c.equiv), c.pRS, c.A}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'variant', 'func', 'pubMean', 'pubStd', 'tbMean', 'tbStd', ...
    'relErrPct', 'zStat', 'pZ', 'within1sd', 'pTost', 'equivalent', 'pRankSum', 'A'});
T.pRankSumHolm = holm(T.pRankSum.').';
writetable(T, fullfile(out, 'repro_comparison.csv'));
writetable(summarize(T), fullfile(out, 'repro_summary.csv'));

%% Table IV(b): toolbox against the 2005 reference code
pairs = {'AllToAll', 'ref_all_to_all'; 'AllToAllAdaptive', 'ref_all_to_all_adaptive'; 'AllToRand', 'ref_all_to_one_randomly'};
rows = {};
for i = 1:size(pairs, 1)
    X = runs(fullfile(res, 'cec2017', [pairs{i, 1} '.csv']));
    Y = runs(fullfile(res, 'cec2017', [pairs{i, 2} '.csv']));
    for k = 1:numel(funcs)
        y = Y(k, :); y(y < 1e-8) = 0;
        c = compareSamples(X(k, :), mean(y), std(y), y, numel(y));
        rows(end + 1, :) = {pairs{i, 1}, funcs(k), c.refMean, c.refStd, c.tbMean, c.tbStd, c.relErrPct, ...
            c.z, c.pZ, double(c.within1sd), c.pTost, double(c.equiv), c.pRS, c.A}; %#ok<AGROW>
    end
end
X = cell2table(rows, 'VariableNames', {'variant', 'func', 'refMean', 'refStd', 'tbMean', 'tbStd', ...
    'relErrPct', 'zStat', 'pZ', 'within1sd', 'pTost', 'equivalent', 'pRankSum', 'A'});
X.pRankSumHolm = holm(X.pRankSum.').';
writetable(X, fullfile(out, 'crosscheck_comparison.csv'));
writetable(summarize(X), fullfile(out, 'crosscheck_summary.csv'));

%% Section 5.3: Pareto with printed (cosine) and coded (linear) schedules
Ypar = runs(fullfile(pkgDir, 'published', 'per_run', 'Pareto.csv'));
rows = {};
for cfg = {'Pareto_cosine', 'Pareto'}
    Xc = runs(fullfile(res, 'cec2017', [cfg{1} '.csv']));
    nSD = 0; nEq = 0;
    for k = 1:numel(funcs)
        j = find(pub.func == funcs(k), 1);
        c = compareSamples(Xc(k, :), pub.Pareto_mean(j), pub.Pareto_std(j), Ypar(k, :), n);
        nSD = nSD + c.within1sd; nEq = nEq + c.equiv;
    end
    rows(end + 1, :) = {cfg{1}, nSD, nEq}; %#ok<AGROW>
end
writetable(cell2table(rows, 'VariableNames', {'configuration', 'within1sd', 'equivalent'}), ...
    fullfile(out, 'pareto_schedules.csv'));

%% Table III: speed-up summary
S = readtable(fullfile(res, 'speedup', 'speedup_timings.csv'), 'TextType', 'string');
keys = unique(S(:, {'variant', 'problem'}), 'stable');
rows = {};
for i = 1:height(keys)
    q = S(S.variant == keys.variant(i) & S.problem == keys.problem(i), :);
    r = sort(q.tScalar_s ./ q.tVectorized_s); m = numel(r);
    qt = @(a) interp1(1:m, r, 1 + a * (m - 1));
    rows(end + 1, :) = {char(keys.variant(i)), char(keys.problem(i)), m, median(q.tScalar_s), ...
        median(q.tVectorized_s), median(r), qt(0.25), qt(0.75)}; %#ok<AGROW>
end
writetable(cell2table(rows, 'VariableNames', {'variant', 'problem', 'nRep', 'medScalar_s', ...
    'medVectorized_s', 'speedupMedian', 'speedupQ1', 'speedupQ3'}), fullfile(out, 'speedup_summary.csv'));

%% Table V: engineering examples
P = readtable(fullfile(res, 'engineering', 'pid_runs.csv'), 'TextType', 'string');
V = readtable(fullfile(res, 'engineering', 'vessel_runs.csv'), 'TextType', 'string');
vs = unique(P.variant, 'stable');
rows = {};
for i = 1:numel(vs)
    p = P(P.variant == vs(i), :); v = V(V.variant == vs(i), :);
    G = [v.g1 v.g2 v.g3 v.g4];
    scale = [v.Ts v.Th 1296000 * ones(height(v), 1) 240 * ones(height(v), 1)];
    rel = max(max(0, G) ./ scale, [], 2);
    feas = all(G <= 0, 2);
    vio = max([rel(~feas); 0]);
    rows(end + 1, :) = {char(vs(i)), mean(p.itae), std(p.itae), mean(v.penalized), std(v.penalized), ...
        sum(feas), height(v), vio, max(abs(v.penalized - v.cost))}; %#ok<AGROW>
end
writetable(cell2table(rows, 'VariableNames', {'variant', 'pidMean', 'pidStd', 'vesselMean', 'vesselStd', ...
    'vesselFeasible', 'vesselRuns', 'vesselMaxRelViolation', 'vesselMaxPenaltyTerm'}), ...
    fullfile(out, 'engineering_summary.csv'));
fprintf('run_statistics: results written to %s\n', out);
end

function E = runs(file)
T = readmatrix(file);
E = T(:, 2:end);
end

function S = summarize(T)
vs = unique(T.variant, 'stable');
rows = {};
for i = 1:numel(vs)
    q = T(strcmp(T.variant, vs{i}), :);
    hasRS = ~all(isnan(q.pRankSum));
    d = abs(q.A - 0.5);
    rows(end + 1, :) = {vs{i}, height(q), sum(q.within1sd), sum(q.pZ > 0.05), sum(q.equivalent), ...
        nanIf(~hasRS, sum(q.pRankSumHolm > 0.05)), nanIf(~hasRS, sum(d < 0.14)), median(q.relErrPct)}; %#ok<AGROW>
end
S = cell2table(rows, 'VariableNames', {'variant', 'cells', 'within1sd', 'zNotRejected', 'equivalent', ...
    'rankSumNotRejectedHolm', 'effectAtMostSmall', 'medianRelErrPct'});
end

function v = nanIf(c, v)
if c; v = NaN; end
end
