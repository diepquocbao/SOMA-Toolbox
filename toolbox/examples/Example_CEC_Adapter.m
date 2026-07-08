%% Connecting an external benchmark suite (IEEE CEC) to somamin
% Metaheuristic researchers often benchmark on the IEEE CEC single-objective
% suites. Those functions are distributed by the competition organizers and are
% NOT bundled with this toolbox. Once you have them on your path, connecting them
% to somamin takes a single adapter line.
%
% The CEC MEX interface expects a D-by-N matrix (columns are individuals) and
% returns raw objective values; somamin passes an N-by-D matrix (rows are
% individuals) and minimizes. The adapter transposes and subtracts the known
% optimum f* so that somamin minimizes the CEC "error" value:
%
%     obj = @(POP) (cec17_func(POP.', func_num) - fstar).';
%
% This script runs only if a CEC evaluator is visible on your path; otherwise it
% prints setup instructions and returns.

funcNum = 1;
D = 10;

if exist('cec17_func', 'file') ~= 3 && exist('cec_eval', 'file') ~= 2
    fprintf(['CEC functions not found on the path.\n' ...
        'Download the IEEE CEC2017 suite (cec17_func + input_data) from the\n' ...
        'competition organizers, add its folder to the path, set that folder as\n' ...
        'the current directory (the MEX reads input_data/ by relative path), then\n' ...
        're-run this example. See benchmarks/README.md in the project repo.\n']);
    return
end

% Prefer the project dispatcher cec_eval if present, else the raw MEX.
if exist('cec_eval', 'file') == 2
    fstar = 100 * funcNum;                      % CEC2017 f* = 100*i
    obj = @(POP) (cec_eval(POP.', funcNum, 2017) - fstar).';
else
    fstar = 100 * funcNum;
    obj = @(POP) (cec17_func(POP.', funcNum) - fstar).';
end

opts = somaoptions('Variant', 'iSOMA', 'Seed', 1, 'Display', 'iter', ...
    'UseVectorized', true, 'MaxFunctionEvaluations', 1e4 * D);
[x, err] = somamin(obj, D, -100, 100, opts);
fprintf('CEC2017 F%d (D=%d): final error = %.4e\n', funcNum, D, err);
