function T = compareToPublished(tbCsv, pubCsv, outCsv)
%COMPARETOPUBLISHED Build the published-vs-toolbox reproduction table.
%   T = COMPARETOPUBLISHED(TBCSV, PUBCSV, OUTCSV) merges the toolbox reproduction
%   results (one row per variant/func: variant,func,meanErr,stdErr,nRuns) with the
%   published Table 6 values (func + <algo>_mean/_std columns) and, for each
%   (variant, func), reports:
%       pubMean, pubStd, tbMean, tbStd, relErrPct, withinStd, zStat, pValue, reproduced
%   The reproduction "match" is judged with a two-sample z-test on the means
%   (Welch form, large-sample normal approximation valid at n=51 by the CLT):
%       z = (tbMean - pubMean) / sqrt(tbStd^2/n + pubStd^2/n)
%       p = erfc(|z|/sqrt(2))                     % two-sided normal tail (base MATLAB)
%   p > 0.05 => means statistically indistinguishable => "reproduced". No published
%   per-run samples exist, so a Wilcoxon rank-sum is not possible; this summary-stat
%   test and the CI-style withinStd flag are the honest alternatives. Uses base
%   MATLAB only (no Statistics Toolbox), matching the toolbox's own dependency rule.
%
%   Defaults (no args): the sibling PublishedResults/ and ToolboxResults/ folders.

here = fileparts(mfilename('fullpath'));
p4   = fileparts(here);          % the reproduction/ folder
if nargin < 1 || isempty(tbCsv);  tbCsv  = fullfile(p4,'ToolboxResults','toolbox_CEC2017_D30_51runs.csv'); end
if nargin < 2 || isempty(pubCsv); pubCsv = fullfile(p4,'PublishedResults','published_CEC2017_D30_all.csv'); end
if nargin < 3 || isempty(outCsv); outCsv = fullfile(p4,'ToolboxResults','comparison_CEC2017_D30.csv'); end

TB  = readtable(tbCsv,  'TextType','string');
PUB = readtable(pubCsv, 'TextType','string');

% toolbox variant name -> published Table 6 column prefix
map = struct('AllToOne','ATO','AllToAll','ATA','Pareto','Pareto','T3A','T3A','iSOMA','iSOMA');

n = 51;
rows = struct('variant',{},'func',{},'pubMean',{},'pubStd',{},'tbMean',{},'tbStd',{}, ...
              'relErrPct',{},'withinStd',{},'zStat',{},'pValue',{},'reproduced',{});
for i = 1:height(TB)
    v = char(TB.variant(i)); f = TB.func(i);
    if ~isfield(map, v); continue; end
    pre = map.(v);
    j = find(PUB.func == f, 1);
    if isempty(j); continue; end
    pubMean = PUB.(sprintf('%s_mean',pre))(j);
    pubStd  = PUB.(sprintf('%s_std', pre))(j);
    tbMean  = TB.meanErr(i);
    tbStd   = TB.stdErr(i);

    denom = max(abs(pubMean), 1e-8);
    relErr = 100 * abs(tbMean - pubMean) / denom;
    withinStd = abs(tbMean - pubMean) <= max(pubStd, 1e-12);   % within one published std
    se = sqrt(tbStd^2/n + pubStd^2/n);
    if se == 0
        z = 0; p = 1;                       % both variances ~0 (e.g. F1 solved): treat as match
    else
        z = (tbMean - pubMean) / se;
        p = erfc(abs(z)/sqrt(2));           % two-sided normal tail
    end
    k = numel(rows) + 1;
    rows(k) = struct('variant',string(v),'func',f,'pubMean',pubMean,'pubStd',pubStd, ...
        'tbMean',tbMean,'tbStd',tbStd,'relErrPct',relErr,'withinStd',withinStd, ...
        'zStat',z,'pValue',p,'reproduced',(p>0.05)||withinStd);
end
T = struct2table(rows);
writetable(T, outCsv);

% ---- per-variant summary ----
fprintf('\n== Reproduction summary (CEC2017 D=30, 51 runs) ==\n');
fprintf('%-10s  %4s  %8s  %8s  %8s\n','variant','n','repro','median','withinStd');
fprintf('%-10s  %4s  %8s  %8s  %8s\n','',       '',   '(p>.05','relErr%','');
for v = ["AllToOne","AllToAll","Pareto","T3A","iSOMA"]
    idx = T.variant == v;
    if ~any(idx); continue; end
    nrep = sum(T.reproduced(idx));
    fprintf('%-10s  %4d  %5d/%-2d  %8.1f  %5d/%-2d\n', v, sum(idx), nrep, sum(idx), ...
        median(T.relErrPct(idx)), sum(T.withinStd(idx)), sum(idx));
end
fprintf('\nwrote %s (%d rows)\n', outCsv, height(T));
end
