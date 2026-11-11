function run_cec2017(cecRoot, outDir, configs, funcs, nRuns)
%RUN_CEC2017 CEC 2017 experiments of the article (n = 30, 3e5 evaluations).
%   RUN_CEC2017(CECROOT, OUTDIR) runs every configuration on F1 and F3-F30
%   with seeds 1-51 and writes one CSV file per configuration to OUTDIR
%   (rows: functions; columns: runs; values: error f(x) - f*).
%   RUN_CEC2017(CECROOT, OUTDIR, CONFIGS, FUNCS, NRUNS) runs a subset.
%
%   CECROOT is the folder holding the compiled CEC 2017 function
%   (cec17_func) and its input_data folder, obtained from the organizers of
%   the competition. Configurations:
%     'AllToOne' 'AllToAll' 'AllToAllAdaptive' 'AllToRand' 'T3A' 'Pareto'
%     'iSOMA'                 SOMA Toolbox 1.1.0 with default settings
%     'Pareto_cosine'         Pareto with the cosine schedules printed in
%                             its article (pareto_cosine.m)
%     'ref_all_to_all' 'ref_all_to_all_adaptive' 'ref_all_to_one_randomly'
%                             2005 MATLAB reference files of the classical
%                             strategies (see README), run by ref2005_run.m
if nargin < 3 || isempty(configs)
    configs = {'AllToOne', 'AllToAll', 'AllToAllAdaptive', 'AllToRand', 'T3A', 'Pareto', 'iSOMA', ...
        'Pareto_cosine', 'ref_all_to_all', 'ref_all_to_all_adaptive', 'ref_all_to_one_randomly'};
end
if nargin < 4 || isempty(funcs); funcs = [1 3:30]; end
if nargin < 5 || isempty(nRuns); nRuns = 51; end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), 'toolbox')); addpath(here); addpath(cecRoot);
if ~exist(outDir, 'dir'); mkdir(outDir); end
old = cd(cecRoot); restore = onCleanup(@() cd(old));
D = 30; maxFEs = 1e4 * D; lb = -100; ub = 100;
for c = 1:numel(configs)
    name = configs{c};
    E = zeros(numel(funcs), nRuns);
    for k = 1:numel(funcs)
        fn = funcs(k); fstar = 100 * fn;
        objV = @(X) (cec_eval(X.', fn, 2017) - fstar).';
        objS = @(x) cec17_func(x(:), fn) - fstar;
        for r = 1:nRuns
            if startsWith(name, 'ref_')
                rng(r, 'twister');
                E(k, r) = ref2005_run(name(5:end), objS, D, lb, ub, 20, 0.11, 3.0, 0.1, maxFEs);
            elseif strcmp(name, 'Pareto_cosine')
                rng(r, 'twister');
                E(k, r) = pareto_cosine(objV, D, lb, ub, maxFEs);
            else
                opts = somaoptions('Variant', name, 'Seed', r, 'Display', 'off', ...
                    'UseVectorized', true, 'MaxFunctionEvaluations', maxFEs);
                [~, E(k, r)] = somamin(objV, D, lb, ub, opts);
            end
        end
        fprintf('%s F%d done\n', name, fn);
    end
    fid = fopen(fullfile(outDir, [name '.csv']), 'w');
    fprintf(fid, 'func'); fprintf(fid, ',run%d', 1:nRuns); fprintf(fid, '\n');
    for k = 1:numel(funcs)
        fprintf(fid, '%d', funcs(k)); fprintf(fid, ',%.17g', E(k, :)); fprintf(fid, '\n');
    end
    fclose(fid);
end
end
