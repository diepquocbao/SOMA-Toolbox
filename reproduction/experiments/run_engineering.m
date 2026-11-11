function run_engineering(outDir)
%RUN_ENGINEERING Engineering examples of the article for the seven variants.
%   PID tuning: 11 seeds, 6000 evaluations each; the listed iSOMA run (seed
%   2026). Pressure vessel: 15 seeds, 20000 evaluations each, quadratic
%   exterior penalty with coefficient 1e9. Writes pid_runs.csv,
%   pid_listing.csv and vessel_runs.csv to OUTDIR.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(fileparts(here)), 'toolbox'));
if ~exist(outDir, 'dir'); mkdir(outDir); end
variants = {'AllToOne', 'AllToAll', 'AllToAllAdaptive', 'AllToRand', 'T3A', 'Pareto', 'iSOMA'};

plant.wn = 1.0; plant.zeta = 0.1;
lb = [0 0 0]; ub = [20 20 20];
fid = fopen(fullfile(outDir, 'pid_runs.csv'), 'w');
fprintf(fid, 'variant,seed,itae,Kp,Ki,Kd\n');
for v = 1:numel(variants)
    for s = 1:11
        opts = somaoptions('Variant', variants{v}, 'Seed', s, 'MaxFunctionEvaluations', 6000, ...
            'UseVectorized', true, 'Display', 'off');
        [x, f] = somamin(@(X) pidITAEvec(X, plant), 3, lb, ub, opts);
        fprintf(fid, '%s,%d,%.17g,%.17g,%.17g,%.17g\n', variants{v}, s, f, x);
    end
end
fclose(fid);
opts = somaoptions('Variant', 'iSOMA', 'Seed', 2026, 'MaxFunctionEvaluations', 6000, 'Display', 'off');
[x, f, ~, o] = somamin(@(x) pidITAE(x, plant), 3, lb, ub, opts);
[t, y] = simClosedLoop(x, plant);
m = stepMetrics(t, y);
fid = fopen(fullfile(outDir, 'pid_listing.csv'), 'w');
fprintf(fid, 'variant,seed,evaluations,itae,Kp,Ki,Kd,overshoot_pct,settling_s\n');
fprintf(fid, 'iSOMA,2026,%d,%.17g,%.17g,%.17g,%.17g,%.6g,%.6g\n', o.funccount, f, x, m.overshoot, m.settling);
fclose(fid);

lbv = [0.0625 0.0625 10 10]; ubv = [6.1875 6.1875 200 200];
fid = fopen(fullfile(outDir, 'vessel_runs.csv'), 'w');
fprintf(fid, 'variant,seed,penalized,cost,Ts,Th,R,L,g1,g2,g3,g4\n');
for v = 1:numel(variants)
    for s = 1:15
        opts = somaoptions('Variant', variants{v}, 'Seed', s, 'MaxFunctionEvaluations', 20000, ...
            'UseVectorized', true, 'Display', 'off');
        [x, f] = somamin(@(X) vesselPenalized(X, 1e9), 4, lbv, ubv, opts);
        [c, g] = vesselRaw(x);
        fprintf(fid, '%s,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n', variants{v}, s, f, c, x, g);
    end
end
fclose(fid);
end

function J = pidITAE(x, plant)
[t, y] = simClosedLoop(x, plant);
J = trapz(t, t(:) .* abs(1 - y(:)));
if ~isfinite(J); J = 1e6; end
end

function J = pidITAEvec(X, plant)
NP = size(X, 1);
Kp = X(:, 1).'; Ki = X(:, 2).'; Kd = X(:, 3).';
a0 = plant.wn^2; a1 = 2 * plant.zeta * plant.wn;
dt = 0.01; t = (0:dt:40).'; r = 1;
y1 = zeros(1, NP); y2 = zeros(1, NP); y3 = zeros(1, NP);
acc = zeros(1, NP); wprev = zeros(1, NP);
for i = 1:numel(t)
    wcur = t(i) * abs(1 - y1);
    if i > 1; acc = acc + 0.5 * dt * (wprev + wcur); end
    wprev = wcur;
    [k11, k12, k13] = deriv(y1, y2, y3);
    [k21, k22, k23] = deriv(y1 + 0.5*dt*k11, y2 + 0.5*dt*k12, y3 + 0.5*dt*k13);
    [k31, k32, k33] = deriv(y1 + 0.5*dt*k21, y2 + 0.5*dt*k22, y3 + 0.5*dt*k23);
    [k41, k42, k43] = deriv(y1 + dt*k31, y2 + dt*k32, y3 + dt*k33);
    y1 = y1 + (dt/6) * (k11 + 2*k21 + 2*k31 + k41);
    y2 = y2 + (dt/6) * (k12 + 2*k22 + 2*k32 + k42);
    y3 = y3 + (dt/6) * (k13 + 2*k23 + 2*k33 + k43);
    bad = ~isfinite(y1) | ~isfinite(y2) | ~isfinite(y3);
    if any(bad); y1(bad) = 1e3; y2(bad) = 0; y3(bad) = 0; end
end
J = acc(:);
J(~isfinite(J)) = 1e6;
    function [d1, d2, d3] = deriv(s1, s2, s3)
        d1 = s2;
        d2 = -a0 * s1 - a1 * s2 + (Kp .* (r - s1) + Ki .* s3 - Kd .* s2);
        d3 = r - s1;
    end
end

function [t, y] = simClosedLoop(x, plant)
Kp = x(1); Ki = x(2); Kd = x(3);
a0 = plant.wn^2; a1 = 2 * plant.zeta * plant.wn;
dt = 0.01; t = (0:dt:40).'; y = zeros(numel(t), 1); s = [0; 0; 0]; r = 1;
d = @(s) [s(2); -a0*s(1) - a1*s(2) + (Kp*(r - s(1)) + Ki*s(3) - Kd*s(2)); r - s(1)];
for i = 1:numel(t)
    y(i) = s(1);
    k1 = d(s); k2 = d(s + 0.5*dt*k1); k3 = d(s + 0.5*dt*k2); k4 = d(s + dt*k3);
    s = s + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
    if any(~isfinite(s)); y(i:end) = Inf; return; end
end
end

function m = stepMetrics(t, y)
m.overshoot = max(0, (max(y) - 1) * 100);
outside = find(abs(y - 1) > 0.02, 1, 'last');
if isempty(outside); m.settling = 0; else; m.settling = t(min(outside + 1, numel(t))); end
end

function J = vesselPenalized(X, rho)
[cost, g] = vesselRawVec(X);
J = cost + rho * sum(max(0, g).^2, 2);
end

function [cost, g] = vesselRawVec(X)
Ts = X(:, 1); Th = X(:, 2); R = X(:, 3); L = X(:, 4);
cost = 0.6224 .* Ts .* R .* L + 1.7781 .* Th .* R.^2 + 3.1661 .* Ts.^2 .* L + 19.84 .* Ts.^2 .* R;
g = [-Ts + 0.0193 .* R, -Th + 0.00954 .* R, -pi .* R.^2 .* L - (4/3) * pi .* R.^3 + 1296000, L - 240];
end

function [cost, g] = vesselRaw(x)
[cost, g] = vesselRawVec(x(:).');
end
