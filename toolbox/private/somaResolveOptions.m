function cfg = somaResolveOptions(opts, nvars)
%SOMARESOLVEOPTIONS Validate options and resolve variant-dependent defaults.
%   CFG = SOMARESOLVEOPTIONS(OPTS, NVARS) returns a fully-populated, validated
%   configuration struct. Empty ([]) option values are replaced by the
%   published defaults of the selected variant (see somaVariantInfo).

info = somaVariantInfo(opts.Variant);
cfg.Variant = info.name;
cfg.impl = info.impl;
cfg.reference = info.reference;

% --- PopulationSize -------------------------------------------------------
if isempty(opts.PopulationSize)
    cfg.PopulationSize = info.defaultPopulationSize;
else
    mustBePositiveIntegerScalar(opts.PopulationSize, 'PopulationSize');
    cfg.PopulationSize = double(opts.PopulationSize);
end
if cfg.PopulationSize < info.minPopulationSize
    error('soma:populationTooSmall', ...
        'Variant "%s" requires PopulationSize >= %d (got %d).', ...
        cfg.Variant, info.minPopulationSize, cfg.PopulationSize);
end

% --- Budgets and stopping criteria ----------------------------------------
if isempty(opts.MaxFunctionEvaluations)
    cfg.MaxFunctionEvaluations = 1e4 * nvars;   % CEC convention
else
    mustBePositiveIntegerScalar(opts.MaxFunctionEvaluations, 'MaxFunctionEvaluations');
    cfg.MaxFunctionEvaluations = double(opts.MaxFunctionEvaluations);
end
cfg.MaxMigrations      = mustBePositiveScalarOrInf(opts.MaxMigrations, 'MaxMigrations');
cfg.MaxStallMigrations = mustBePositiveScalarOrInf(opts.MaxStallMigrations, 'MaxStallMigrations');
if ~(isnumeric(opts.FunctionTolerance) && isscalar(opts.FunctionTolerance) ...
        && isreal(opts.FunctionTolerance) && opts.FunctionTolerance >= 0)
    error('soma:invalidOptionValue', 'FunctionTolerance must be a nonnegative real scalar.');
end
cfg.FunctionTolerance = double(opts.FunctionTolerance);
if ~(isnumeric(opts.ObjectiveLimit) && isscalar(opts.ObjectiveLimit) && isreal(opts.ObjectiveLimit))
    error('soma:invalidOptionValue', 'ObjectiveLimit must be a real scalar.');
end
cfg.ObjectiveLimit = double(opts.ObjectiveLimit);

% --- Flags and modes -------------------------------------------------------
cfg.UseVectorized = mustBeLogicalScalar(opts.UseVectorized, 'UseVectorized');
cfg.RecordHistory = mustBeLogicalScalar(opts.RecordHistory, 'RecordHistory');

bh = lower(string(opts.BoundaryHandling));
if ~ismember(bh, ["reinitialize","clip","reflect"])
    error('soma:invalidOptionValue', ...
        'BoundaryHandling must be "reinitialize", "clip", or "reflect".');
end
cfg.BoundaryHandling = bh;

disp_ = lower(string(opts.Display));
if ~ismember(disp_, ["off","final","iter"])
    error('soma:invalidOptionValue', 'Display must be "off", "final", or "iter".');
end
cfg.Display = disp_;

cfg.OutputFcn = normalizeFcnList(opts.OutputFcn, 'OutputFcn');
cfg.PlotFcn   = normalizeFcnList(opts.PlotFcn, 'PlotFcn');

if ~isempty(opts.Seed)
    mustBeNonnegativeIntegerScalar(opts.Seed, 'Seed');
end
cfg.Seed = opts.Seed;

cfg.InitialPopulation = opts.InitialPopulation;   % validated in somaInitPop

% --- Variant parameters -----------------------------------------------------
cfg.params = info.params;
given = fieldnames(opts.VariantOptions);
valid = fieldnames(info.params);
for i = 1:numel(given)
    idx = find(strcmpi(given{i}, valid), 1);
    if isempty(idx)
        warning('soma:ignoredVariantOption', ...
            'Variant parameter "%s" does not apply to variant "%s" and is ignored.', ...
            given{i}, cfg.Variant);
    else
        v = opts.VariantOptions.(given{i});
        default = info.params.(valid{idx});
        if ischar(default) || isstring(default)
            % String-valued parameter (e.g. PRTVectorMode): keep as string.
            if ~(ischar(v) || (isstring(v) && isscalar(v)))
                error('soma:invalidOptionValue', ...
                    'Variant parameter "%s" must be a string.', valid{idx});
            end
            v = lower(string(v));
            if strcmp(valid{idx}, 'PRTVectorMode') && ~ismember(v, ["adaptive","binary"])
                error('soma:invalidOptionValue', ...
                    'PRTVectorMode must be "adaptive" or "binary".');
            end
            cfg.params.(valid{idx}) = v;
        else
            if ~(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && v > 0)
                error('soma:invalidOptionValue', ...
                    'Variant parameter "%s" must be a positive real scalar.', valid{idx});
            end
            cfg.params.(valid{idx}) = double(v);
        end
    end
end
end

% ---------------------------------------------------------------------------
function mustBePositiveIntegerScalar(v, name)
if ~(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && v >= 1 && mod(v,1) == 0)
    error('soma:invalidOptionValue', '%s must be a positive integer scalar.', name);
end
end

function out = mustBePositiveScalarOrInf(v, name)
if ~(isnumeric(v) && isscalar(v) && isreal(v) && v > 0)
    error('soma:invalidOptionValue', '%s must be a positive scalar (Inf allowed).', name);
end
out = double(v);
end

function out = mustBeLogicalScalar(v, name)
if ~(isscalar(v) && (islogical(v) || (isnumeric(v) && ismember(v,[0 1]))))
    error('soma:invalidOptionValue', '%s must be true or false.', name);
end
out = logical(v);
end

function mustBeNonnegativeIntegerScalar(v, name)
if ~(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && v >= 0 && mod(v,1) == 0)
    error('soma:invalidOptionValue', '%s must be a nonnegative integer scalar.', name);
end
end

function list = normalizeFcnList(v, name)
if isempty(v)
    list = {};
elseif isa(v, 'function_handle')
    list = {v};
elseif iscell(v) && all(cellfun(@(f) isa(f,'function_handle'), v))
    list = v;
else
    error('soma:invalidOptionValue', ...
        '%s must be a function handle or a cell array of function handles.', name);
end
end
