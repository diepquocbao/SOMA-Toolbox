function R = runVariantOnCEC(variant, year, funcs, D, nRuns, maxFEs, cecRoot, extraOpts)
%RUNVARIANTONCEC Run a SOMA variant on IEEE CEC functions (reproduction harness).
%   R = RUNVARIANTONCEC(VARIANT, YEAR, FUNCS, D, NRUNS, MAXFES, CECROOT, EXTRAOPTS)
%   runs somamin(VARIANT) on each function in FUNCS at dimension D for NRUNS
%   independent seeds (seed = run index) with a budget of MAXFES evaluations,
%   returning a struct array R with fields func, meanErr, stdErr, errs.
%
%   Errors below 1e-8 are set to 0, following the CEC competition protocol.
%
%   CECROOT is the folder that contains a CEC<YEAR>/ subfolder with the
%   compiled MEX and its input_data/. The IEEE CEC suites are NOT
%   redistributed with the SOMA Toolbox; obtain them from the competition
%   organizers and point CECROOT at them (see ../README.md). The thin
%   dispatchers cec_eval.m / cec_meta.m live in this folder.
%
%   EXTRAOPTS is an optional cell array of extra name-value options forwarded
%   to somaoptions (e.g. {'PRTVectorMode','binary'}).

if nargin < 8 || isempty(extraOpts); extraOpts = {}; end

yearDir = fullfile(cecRoot, sprintf('CEC%d', year));
addpath(cecRoot);
addpath(yearDir);
oldcd = cd(yearDir);                    % MEX reads input_data/ relatively
restore = onCleanup(@() cd(oldcd));

M = cec_meta(year);
R = struct('func', {}, 'meanErr', {}, 'stdErr', {}, 'errs', {});
for fi = 1:numel(funcs)
    fn = funcs(fi);
    fstar = M.fstar(fn);
    obj = @(POP) (cec_eval(POP.', fn, year) - fstar).';
    errs = zeros(1, nRuns);
    for r = 1:nRuns
        opts = somaoptions('Variant', variant, 'Seed', r, 'Display', 'off', ...
            'UseVectorized', true, 'MaxFunctionEvaluations', maxFEs, extraOpts{:});
        [~, e] = somamin(obj, D, M.lb, M.ub, opts);
        errs(r) = e;
    end
    errs(errs < 1e-8) = 0;              % CEC protocol: treat < 1e-8 as 0
    R(fi).func = fn;
    R(fi).meanErr = mean(errs);
    R(fi).stdErr = std(errs);
    R(fi).errs = errs;
end
end
