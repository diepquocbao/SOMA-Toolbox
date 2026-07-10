function runFullReproCEC17(cecRoot)
%RUNFULLREPROCEC17 Full paper reproduction: 5 baseline variants on CEC2017.
%   RUNFULLREPROCEC17(CECROOT) runs 5 variants (AllToOne, AllToAll, Pareto,
%   T3A, iSOMA) x CEC2017 [1 3:30] x D=30 x 51 runs x MaxFEs=1e4*D. Resumable,
%   writes one row per (variant, func) to a DEDICATED 51-run CSV (kept separate
%   from any pilot CSV so the paper table never mixes run counts). Safe to
%   relaunch after a crash or timeout: rows already present are skipped.
%   CECROOT is the folder holding the CEC benchmark suite (see ../README.md).
if nargin < 1 || isempty(cecRoot)
    error('soma:reproduction', ...
        'Provide cecRoot, the folder holding the CEC benchmark suite (see reproduction/README.md).');
end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), 'toolbox'));
addpath(here);
outDir = fullfile(fileparts(here), 'ToolboxResults');
if ~exist(outDir, 'dir'); mkdir(outDir); end
outCsv = fullfile(outDir, 'toolbox_CEC2017_D30_51runs.csv');

variants = ["AllToOne","AllToAll","Pareto","T3A","iSOMA"];
funcs = [1 3:30];               % 29 functions (F2 excluded per CEC convention)
D = 30; nRuns = 51; maxFEs = 1e4 * D;
reproduceFamily(variants, 2017, funcs, D, nRuns, maxFEs, cecRoot, outCsv);
end
