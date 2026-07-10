function reproduceFamily(variants, year, funcs, D, nRuns, maxFEs, cecRoot, outCsv)
%REPRODUCEFAMILY Reproduce published SOMA-family results, saving incrementally.
%   REPRODUCEFAMILY(VARIANTS, YEAR, FUNCS, D, NRUNS, MAXFES, CECROOT, OUTCSV)
%   runs each variant on each function and appends one row per (variant, func)
%   to OUTCSV: variant,func,meanErr,stdErr,nRuns. Rows already present in OUTCSV
%   are skipped, so the job is RESUMABLE — just call it again to continue.
%
%   VARIANTS is a string array; the other arguments match runVariantOnCEC.
%   Designed to be launched in the background for the full paper reproduction.

if exist(outCsv, 'file')
    T = readtable(outCsv, 'TextType', 'string');
    done = arrayfun(@(k) sprintf('%s_%d', T.variant(k), T.func(k)), 1:height(T), ...
        'UniformOutput', false);
    done = string(done);
else
    fid = fopen(outCsv, 'w');
    fprintf(fid, 'variant,func,meanErr,stdErr,nRuns\n');
    fclose(fid);
    done = strings(0);
end

for v = variants
    for fn = funcs
        key = sprintf('%s_%d', v, fn);
        if ismember(key, done)
            fprintf('skip %s (already done)\n', key);
            continue
        end
        t0 = tic;
        R = runVariantOnCEC(char(v), year, fn, D, nRuns, maxFEs, cecRoot);
        fid = fopen(outCsv, 'a');
        fprintf(fid, '%s,%d,%.6e,%.6e,%d\n', v, fn, R(1).meanErr, R(1).stdErr, nRuns);
        fclose(fid);
        fprintf('done %-16s F%-2d mean=%.4e std=%.4e (%.1fs)\n', ...
            v, fn, R(1).meanErr, R(1).stdErr, toc(t0));
    end
end
fprintf('reproduceFamily COMPLETE\n');
end
