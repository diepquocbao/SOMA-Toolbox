function stop = somaplotbestf(optimValues, state)
%SOMAPLOTBESTF Plot the best objective value against migrations.
%   Use as a plot function: opts = somaoptions('PlotFcn', @somaplotbestf).
%
%   See also SOMAMIN, SOMAOPTIONS.

%   Copyright 2026 Quoc Bao Diep. MIT license.

stop = false;
switch state
    case 'init'
        figure(gcf);
        plot(optimValues.iteration, optimValues.bestfval, '.b');
        hold on
        xlabel('Migration');
        ylabel('Best f(x)');
        title(sprintf('Best objective: %.6g', optimValues.bestfval));
        grid on
    case 'iter'
        plot(optimValues.iteration, optimValues.bestfval, '.b');
        title(sprintf('Best objective: %.6g', optimValues.bestfval));
    case 'done'
        hold off
end
end
