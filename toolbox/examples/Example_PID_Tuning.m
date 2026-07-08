%% Engineering example: PID controller tuning with SOMA
% Tune the three gains (Kp, Ki, Kd) of a PID controller for a lightly damped
% second-order plant so that the closed-loop step response is fast and
% well-damped. The cost is the ITAE (integral of time-weighted absolute
% error) of the unit-step response.
%
% This example uses only base MATLAB: the closed loop is integrated with a
% fixed-step RK4 solver defined at the bottom of this file. No Control System
% Toolbox is required.

%% Problem setup
% Plant: G(s) = 1 / (s^2 + 2*zeta*wn*s + wn^2), lightly damped (zeta = 0.1).
plant.wn   = 1.0;
plant.zeta = 0.1;

% Decision variables: x = [Kp, Ki, Kd], each in [0, 20].
nvars = 3;
lb = [0 0 0];
ub = [20 20 20];

objective = @(x) pidITAE(x, plant);

%% Optimize with SOMA
opts = somaoptions('Variant', 'iSOMA', 'Seed', 2026, ...
    'MaxFunctionEvaluations', 6e3, 'Display', 'iter');
[xBest, jBest] = somamin(objective, nvars, lb, ub, opts);

fprintf('\nBest gains:  Kp = %.4f, Ki = %.4f, Kd = %.4f\n', xBest(1), xBest(2), xBest(3));
fprintf('Best ITAE :  %.4f\n', jBest);

%% Inspect the tuned step response
[t, y] = simulateClosedLoop(xBest, plant);
info = stepInfoBasic(t, y);
fprintf('Overshoot = %.1f %%, settling time (2%%) = %.2f s, steady-state error = %.3g\n', ...
    info.overshoot, info.settlingTime, info.steadyStateError);

figure('Name', 'PID tuning result');
plot(t, y, 'LineWidth', 1.5); hold on
yline(1, '--k');
xlabel('Time (s)'); ylabel('Output y(t)');
title(sprintf('Tuned step response (Kp=%.2f, Ki=%.2f, Kd=%.2f)', xBest(1), xBest(2), xBest(3)));
grid on

%% ------------------------------------------------------------------------
% Local functions
% -------------------------------------------------------------------------
function J = pidITAE(x, plant)
% ITAE of the closed-loop unit-step response for PID gains x = [Kp Ki Kd].
[t, y] = simulateClosedLoop(x, plant);
e = 1 - y;                      % reference is a unit step
J = trapz(t, t(:) .* abs(e(:)));
if ~isfinite(J)
    J = 1e6;                    % guard against unstable gains (finite penalty)
end
end

function [t, y] = simulateClosedLoop(x, plant)
% Fixed-step RK4 simulation of the PID-controlled second-order plant.
Kp = x(1); Ki = x(2); Kd = x(3);
wn = plant.wn; zeta = plant.zeta;
a0 = wn^2; a1 = 2*zeta*wn;

T  = 40;                        % simulation horizon (s)
dt = 0.01;                      % fixed step
t  = (0:dt:T).';
n  = numel(t);
y  = zeros(n, 1);

% State: s = [y; y'; integral of error]. Reference r = 1 (unit step).
s = [0; 0; 0];
r = 1;
deriv = @(s) [ ...
    s(2); ...
    -a0*s(1) - a1*s(2) + (Kp*(r - s(1)) + Ki*s(3) - Kd*s(2)); ...
    r - s(1)];

for i = 1:n
    y(i) = s(1);
    k1 = deriv(s);
    k2 = deriv(s + 0.5*dt*k1);
    k3 = deriv(s + 0.5*dt*k2);
    k4 = deriv(s + dt*k3);
    s = s + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
    if any(~isfinite(s))
        y(i:end) = Inf;         % diverged: mark the rest as unstable
        return
    end
end
end

function info = stepInfoBasic(t, y)
% Minimal step-response metrics (overshoot, 2% settling time, ss error).
yf = y(end);
info.steadyStateError = 1 - yf;
info.overshoot = max(0, (max(y) - 1) * 100);
tol = 0.02;
outside = find(abs(y - 1) > tol, 1, 'last');
if isempty(outside)
    info.settlingTime = 0;
else
    info.settlingTime = t(min(outside + 1, numel(t)));
end
end
