function generateConvergenceFig(funcs, nRunsFig, cecRoot)
%GENERATECONVERGENCEFIG Median convergence curves per variant on CEC2017 D=30.
%   GENERATECONVERGENCEFIG(FUNCS, NRUNSFIG, CECROOT) runs each of the 5 baseline
%   SOMA variants NRUNSFIG times (seeds 1..NRUNSFIG) on each function in FUNCS at
%   D=30, MaxFEs=1e4*D, recording the best-so-far value per migration. It then
%   plots the MEDIAN-over-runs trajectory (best error above the known optimum)
%   against function evaluations on a semilog axis — one panel per function,
%   one curve per variant — and writes:
%       ../ToolboxResults/convergence_CEC2017_D30.png     (figure for the paper)
%       ../ToolboxResults/convergence_CEC2017_D30.mat     (raw median curves)
%   x-axis is FEs (migration index scaled by funccount/#migrations) so variants
%   with different per-migration cost (e.g. AllToAll vs AllToOne) compare fairly.
%   Base MATLAB only; runs headless under matlab -batch.

if nargin < 1 || isempty(funcs);    funcs = [1 7 16]; end     % unimodal / multimodal / hybrid
if nargin < 2 || isempty(nRunsFig); nRunsFig = 15;      end
if nargin < 3 || isempty(cecRoot)
    error('soma:reproduction', ...
        'Provide cecRoot, the folder holding the CEC benchmark suite (see reproduction/README.md).');
end

here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), 'toolbox'));
outDir = fullfile(fileparts(here),'ToolboxResults');
if ~exist(outDir,'dir'); mkdir(outDir); end

variants = ["AllToOne","AllToAll","Pareto","T3A","iSOMA"];
D = 30; maxFEs = 1e4*D;
year = 2017;
yearDir = fullfile(cecRoot, sprintf('CEC%d', year));
addpath(cecRoot); addpath(yearDir);
oldcd = cd(yearDir); restore = onCleanup(@() cd(oldcd));   %#ok<NASGU>
M = cec_meta(year);

nGrid = 200;                          % common FE grid for interpolation
feGrid = linspace(maxFEs/nGrid, maxFEs, nGrid);
curves = struct();

for fi = 1:numel(funcs)
    fn = funcs(fi); fstar = M.fstar(fn);
    obj = @(POP) (cec_eval(POP.', fn, year) - fstar).';
    for vi = 1:numel(variants)
        v = variants(vi);
        acc = nan(nRunsFig, nGrid);
        for r = 1:nRunsFig
            opts = somaoptions('Variant', char(v), 'Seed', r, 'Display','off', ...
                'UseVectorized', true, 'MaxFunctionEvaluations', maxFEs, ...
                'RecordHistory', true);
            [~,~,~,out] = somamin(obj, D, M.lb, M.ub, opts);
            h = out.bestfvalhistory(:).';
            h = max(h, 0);                       % error >= 0
            nm = numel(h);
            feAt = (1:nm) * (out.funccount / nm);   % FEs at each migration
            acc(r,:) = interp1([0 feAt], [h(1) h], feGrid, 'previous', h(end));
        end
        curves.(sprintf('f%d',fn)).(char(v)) = median(acc, 1, 'omitnan');
    end
    fprintf('func F%d done\n', fn);
end
save(fullfile(outDir,'convergence_CEC2017_D30.mat'), 'curves','feGrid','funcs','variants');

% ---- plot ----
fig = figure('Visible','off','Position',[100 100 420*numel(funcs) 360]);
tl = tiledlayout(fig, 1, numel(funcs), 'Padding','compact','TileSpacing','compact');
lg = [];
for fi = 1:numel(funcs)
    fn = funcs(fi); ax = nexttile(tl); hold(ax,'on');
    for vi = 1:numel(variants)
        v = char(variants(vi));
        y = curves.(sprintf('f%d',fn)).(v);
        y(y<=0) = min(y(y>0))/10 + eps;          % floor for log axis
        plot(ax, feGrid, y, 'LineWidth', 1.4);
    end
    set(ax,'YScale','log'); grid(ax,'on');
    xlabel(ax,'Function evaluations'); title(ax, sprintf('F%d', fn));
    if fi==1; ylabel(ax,'Median error (best-so-far)'); end
end
lg = legend(ax, cellstr(variants), 'Location','northeast'); %#ok<NASGU>
title(tl, 'SOMA family convergence — CEC2017, D=30 (median of runs)');
pngPath = fullfile(outDir,'convergence_CEC2017_D30.png');
exportgraphics(fig, pngPath, 'Resolution', 200);
close(fig);
fprintf('wrote %s\n', pngPath);
end
