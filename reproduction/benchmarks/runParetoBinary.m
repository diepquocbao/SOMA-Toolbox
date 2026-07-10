function runParetoBinary(cecRoot)
%RUNPARETOBINARY Arbitration probe: Pareto with PRTVectorMode='binary'.
%   The reference Pareto implementation ships with the soft PRTVector line
%   commented out (i.e. it ran BINARY), while the toolbox default is
%   'adaptive' (the published equation). The full 51-run reproduction left
%   4/29 functions unreproduced with 'adaptive' (F6, F9, F24, F27). This
%   script re-runs Pareto with 'binary' on those 4 failures plus 5
%   representative passing functions (F1, F5, F7, F10, F16) x 51 runs, so
%   the default can be decided with data (see the deviation log).
%   CECROOT is the folder holding the CEC benchmark suite (see ../README.md).
%   Resumable: rows already in the output CSV are skipped.

if nargin < 1 || isempty(cecRoot)
    error('soma:reproduction', ...
        'Provide cecRoot, the folder holding the CEC benchmark suite (see reproduction/README.md).');
end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), 'toolbox'));
addpath(here);
outCsv = fullfile(fileparts(here), 'ToolboxResults', 'pareto_binary_CEC2017_D30.csv');

funcs = [1 5 6 7 9 10 16 24 27];
D = 30; nRuns = 51; maxFEs = 1e4*D;

if exist(outCsv, 'file')
    T = readtable(outCsv, 'TextType', 'string');
    done = T.func(:).';
else
    fid = fopen(outCsv, 'w');
    fprintf(fid, 'variant,func,meanErr,stdErr,nRuns\n');
    fclose(fid);
    done = [];
end

for fn = funcs
    if ismember(fn, done)
        fprintf('skip F%d (already done)\n', fn);
        continue
    end
    t0 = tic;
    R = runVariantOnCEC('Pareto', 2017, fn, D, nRuns, maxFEs, cecRoot, ...
        {'PRTVectorMode', 'binary'});
    fid = fopen(outCsv, 'a');
    fprintf(fid, 'Pareto-binary,%d,%.6e,%.6e,%d\n', fn, R(1).meanErr, R(1).stdErr, nRuns);
    fclose(fid);
    fprintf('done Pareto-binary F%-2d mean=%.4e std=%.4e (%.1fs)\n', ...
        fn, R(1).meanErr, R(1).stdErr, toc(t0));
end
fprintf('runParetoBinary COMPLETE\n');
end
