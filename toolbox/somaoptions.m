function opts = somaoptions(varargin)
%SOMAOPTIONS Create or modify an options structure for SOMA.
%   OPTS = SOMAOPTIONS returns an options structure with default settings
%   for the default variant ("AllToOne").
%
%   OPTS = SOMAOPTIONS('Name',Value,...) sets the named options. Names are
%   matched case-insensitively.
%
%   OPTS = SOMAOPTIONS(OLDOPTS,'Name',Value,...) modifies a copy of OLDOPTS.
%
%   Common options (all variants):
%     Variant                - "AllToOne" (default) | "AllToAll" |
%                              "AllToAllAdaptive" | "AllToRand" | "T3A" |
%                              "Pareto" | "iSOMA"
%     PopulationSize         - [] (default: published value of the variant)
%     MaxFunctionEvaluations - [] (default: 1e4*nvars, the CEC convention)
%     MaxMigrations          - Inf (default)
%     MaxStallMigrations     - Inf (default)
%     FunctionTolerance      - 1e-8 (default), used with MaxStallMigrations
%     ObjectiveLimit         - -Inf (default)
%     InitialPopulation      - [] (default) | matrix with nvars columns
%     UseVectorized          - false (default) | true
%     BoundaryHandling       - "reinitialize" (default) | "clip" | "reflect"
%     Display                - "final" (default) | "off" | "iter"
%     OutputFcn              - [] (default) | function handle or cell array
%     PlotFcn                - [] (default) | function handle (e.g. @somaplotbestf)
%     RecordHistory          - false (default) | true
%     Seed                   - [] (default) | nonnegative integer
%
%   Variant-specific parameters (stored in OPTS.VariantOptions and applied
%   only when the matching variant runs; defaults are the published values):
%     PathLength, Step, PRT  - classical variants (AllToOne, AllToAll,
%                              AllToAllAdaptive, AllToRand)
%     NJump, m, n, k         - T3A and iSOMA (Pareto uses NJump only)
%     PRTVectorMode          - Pareto and iSOMA: "adaptive" (default, the soft
%                              perturbation vector proposed in the papers) or
%                              "binary" (the classical 0/1 vector)
%
%   Example:
%     opts = somaoptions('Variant','T3A','Display','iter','Seed',1);
%     [x,fval] = somamin(@(x)sum(x.^2), 10, -100, 100, opts);
%
%   See also SOMAMIN, SOMAPLOTBESTF.

%   Copyright 2026 Quoc Bao Diep. MIT license.

commonDefaults = struct( ...
    'Variant',                "AllToOne", ...
    'PopulationSize',         [], ...
    'MaxFunctionEvaluations', [], ...
    'MaxMigrations',          Inf, ...
    'MaxStallMigrations',     Inf, ...
    'FunctionTolerance',      1e-8, ...
    'ObjectiveLimit',         -Inf, ...
    'InitialPopulation',      [], ...
    'UseVectorized',          false, ...
    'BoundaryHandling',       "reinitialize", ...
    'Display',                "final", ...
    'OutputFcn',              [], ...
    'PlotFcn',                [], ...
    'RecordHistory',          false, ...
    'Seed',                   [], ...
    'VariantOptions',         struct());

variantParamNames = ["PathLength","Step","PRT","NJump","m","n","k","PRTVectorMode"];

args = varargin;
if ~isempty(args) && isstruct(args{1})
    opts = mergeIntoDefaults(commonDefaults, args{1});
    args(1) = [];
else
    opts = commonDefaults;
end

if mod(numel(args), 2) ~= 0
    error('soma:unknownOption', ...
        'Options must be supplied as ''Name'',Value pairs.');
end

commonNames = string(fieldnames(commonDefaults));
for i = 1:2:numel(args)
    name = args{i};
    if ~(ischar(name) || (isstring(name) && isscalar(name)))
        error('soma:unknownOption', 'Option names must be character vectors or string scalars.');
    end
    name = string(name);
    value = args{i+1};

    idxCommon  = find(strcmpi(name, commonNames), 1);
    idxVariant = find(strcmpi(name, variantParamNames), 1);
    if ~isempty(idxCommon)
        opts.(char(commonNames(idxCommon))) = value;
    elseif ~isempty(idxVariant)
        opts.VariantOptions.(char(variantParamNames(idxVariant))) = value;
    else
        error('soma:unknownOption', ...
            'Unknown option "%s". Valid options: %s; variant parameters: %s.', ...
            name, strjoin(commonNames, ', '), strjoin(variantParamNames, ', '));
    end
end

% Canonicalize and validate the variant name right away (fail fast on typos).
info = somaVariantInfo(opts.Variant);   % errors with soma:invalidVariant if bad
opts.Variant = info.name;
end

function opts = mergeIntoDefaults(defaults, given)
% Copy recognized fields of a given struct onto the defaults; reject unknowns.
opts = defaults;
names = fieldnames(given);
for i = 1:numel(names)
    if isfield(defaults, names{i})
        opts.(names{i}) = given.(names{i});
    else
        error('soma:unknownOption', 'Unknown option field "%s" in options struct.', names{i});
    end
end
end
