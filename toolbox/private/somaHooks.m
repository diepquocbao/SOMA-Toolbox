function stop = somaHooks(phase, cfg, optimValues)
%SOMAHOOKS Run Display/OutputFcn/PlotFcn callbacks for one loop event.
%   STOP = SOMAHOOKS(PHASE, CFG, OPTIMVALUES) with PHASE "init", "iter" or
%   "done". Returns true if any callback requested an early stop.
%   OPTIMVALUES fields: iteration, funccount, bestfval, bestx.

stop = false;

if cfg.Display == "iter"
    switch phase
        case "init"
            fprintf('%10s %12s %16s\n', 'Migration', 'f-count', 'Best f(x)');
            fprintf('%10d %12d %16.6g\n', optimValues.iteration, ...
                optimValues.funccount, optimValues.bestfval);
        case "iter"
            fprintf('%10d %12d %16.6g\n', optimValues.iteration, ...
                optimValues.funccount, optimValues.bestfval);
    end
end

for i = 1:numel(cfg.OutputFcn)
    stop = stop | callAndCheck(cfg.OutputFcn{i}, optimValues, phase);
end
for i = 1:numel(cfg.PlotFcn)
    stop = stop | callAndCheck(cfg.PlotFcn{i}, optimValues, phase);
end
end

function stop = callAndCheck(fcn, optimValues, phase)
out = fcn(optimValues, char(phase));
stop = isscalar(out) && logical(out);
end
