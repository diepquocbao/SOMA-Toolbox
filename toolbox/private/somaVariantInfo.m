function info = somaVariantInfo(variant)
%SOMAVARIANTINFO Registry of SOMA variants: canonical names, defaults, sources.
%   INFO = SOMAVARIANTINFO(VARIANT) returns a struct describing the requested
%   variant (case-insensitive). INFO fields:
%     name        - canonical display name (string)
%     impl        - function handle to the implementation, or [] if the
%                   variant is registered but not yet implemented
%     defaultPopulationSize - published default population size
%     params      - struct of variant-specific parameters with published
%                   default values (see reference)
%     minPopulationSize     - smallest population the variant supports
%     reference   - citation of the original paper (shown in error messages
%                   and help)
%
%   INFO = SOMAVARIANTINFO() with no input returns a string array of all
%   registered variant names.
%
%   Defaults follow the ORIGINAL PAPERS, not later code releases. See
%   DEVIATIONS.md in the repository root for any documented differences.

names = ["AllToOne","AllToAll","AllToAllAdaptive","AllToRand","T3A","Pareto","iSOMA"];
if nargin == 0
    info = names;
    return
end

key = lower(char(string(variant)));
switch key
    case 'alltoone'
        info.name = "AllToOne";
        info.impl = @soma_alltoone;
        info.defaultPopulationSize = 30;
        info.params = struct('PathLength', 3.0, 'Step', 0.11, 'PRT', 0.1);
        info.minPopulationSize = 2;
        info.reference = "Zelinka (2004), New Optimization Techniques in Engineering, Springer, pp. 167-217. Settings: Diep et al. (2019), MENDEL 25(1):111-120, Sec. 4.";
    case 'alltoall'
        info.name = "AllToAll";
        info.impl = @soma_alltoall;
        info.defaultPopulationSize = 20;
        info.params = struct('PathLength', 3.0, 'Step', 0.11, 'PRT', 0.1);
        info.minPopulationSize = 2;
        info.reference = "Zelinka (2004), New Optimization Techniques in Engineering, Springer, pp. 167-217.";
    case 'alltoalladaptive'
        info.name = "AllToAllAdaptive";
        info.impl = @soma_alltoalladaptive;
        info.defaultPopulationSize = 20;
        info.params = struct('PathLength', 3.0, 'Step', 0.11, 'PRT', 0.1);
        info.minPopulationSize = 2;
        info.reference = "Zelinka (2004), New Optimization Techniques in Engineering, Springer, pp. 167-217.";
    case 'alltorand'
        info.name = "AllToRand";
        info.impl = @soma_alltorand;
        info.defaultPopulationSize = 20;
        info.params = struct('PathLength', 3.0, 'Step', 0.11, 'PRT', 0.1);
        info.minPopulationSize = 2;
        info.reference = "Zelinka (2004), New Optimization Techniques in Engineering, Springer, pp. 167-217.";
    case 't3a'
        info.name = "T3A";
        info.impl = @soma_t3a;
        info.defaultPopulationSize = 30;
        info.params = struct('NJump', 45, 'm', 10, 'n', 4, 'k', 10);
        info.minPopulationSize = 10;   % must allow randperm(PopSize, max(m,k))
        info.reference = "Diep (2019), IEEE CEC 2019, pp. 1182-1187, Table I.";
    case 'pareto'
        info.name = "Pareto";
        info.impl = @soma_pareto;
        info.defaultPopulationSize = 100;
        info.params = struct('NJump', 10, 'PRTVectorMode', "adaptive");
        info.minPopulationSize = 5;    % Pareto 4%/20%/16% groups need >= 1 member each
        info.reference = "Diep, Zelinka, Das (2019), MENDEL 25(1):111-120.";
    case 'isoma'
        info.name = "iSOMA";
        info.impl = @soma_isoma;
        info.defaultPopulationSize = 100;
        info.params = struct('NJump', 10, 'm', 10, 'n', 5, 'k', 15, 'Step', 0.3, ...
            'PRTVectorMode', "adaptive");
        info.minPopulationSize = 15;   % must allow randperm(PopSize, max(m,k))
        info.reference = "Diep, Truong, Das, Zelinka (2022), Applied Soft Computing 116:108270.";
    otherwise
        error('soma:invalidVariant', ...
            'Unknown variant "%s". Valid variants are: %s.', ...
            string(variant), strjoin(names, ', '));
end
end
