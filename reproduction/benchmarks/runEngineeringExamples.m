function runEngineeringExamples()
% Generate real data + figures for the paper's engineering-applications section.
% Two classic problems, several variants, multiple seeds each. Vectorized
% objectives (base MATLAB only). Writes CSVs + step-response and convergence
% figures to ../ToolboxResults/.

here   = fileparts(mfilename('fullpath'));
outdir = fullfile(fileparts(here), 'ToolboxResults');
addpath(fullfile(fileparts(fileparts(here)), 'toolbox'));
if ~exist(outdir, 'dir'); mkdir(outdir); end

variants = {'AllToOne','AllToAll','T3A','Pareto','iSOMA'};
plant.wn = 1.0; plant.zeta = 0.1;

%% ---------------- PID tuning ----------------
pidObj  = @(X) pidITAEvec(X, plant);
nv = 3; lb = [0 0 0]; ub = [20 20 20];
seeds = 1:11; budget = 6e3;

fprintf('=== PID tuning ===\n');
pidStats = zeros(numel(variants), 4);      % best mean std median
pidBest.cost = Inf; pidBest.x = []; pidBest.variant = '';
pidConv = struct();
for vi = 1:numel(variants)
    vname = variants{vi};
    costs = zeros(numel(seeds),1);
    for si = 1:numel(seeds)
        opts = somaoptions('Variant', vname, 'Seed', seeds(si), ...
            'MaxFunctionEvaluations', budget, 'UseVectorized', true, 'Display','off');
        [x, f] = somamin(pidObj, nv, lb, ub, opts);
        costs(si) = f;
        if f < pidBest.cost, pidBest.cost=f; pidBest.x=x; pidBest.variant=vname; end
    end
    pidStats(vi,:) = [min(costs) mean(costs) std(costs) median(costs)];
    % convergence trace on seed 1
    opts = somaoptions('Variant', vname, 'Seed', 1, ...
        'MaxFunctionEvaluations', budget, 'UseVectorized', true, ...
        'Display','off', 'RecordHistory', true);
    [~,~,~,out] = somamin(pidObj, nv, lb, ub, opts);
    pidConv.(vname).hist = out.bestfvalhistory;
    pidConv.(vname).fe   = feAxis(out);
    fprintf('  %-9s best=%.4f mean=%.4f std=%.4f\n', vname, pidStats(vi,1), pidStats(vi,2), pidStats(vi,3));
end

% write PID stats CSV
fid = fopen(fullfile(outdir,'engineering_pid.csv'),'w');
fprintf(fid,'variant,bestITAE,meanITAE,stdITAE,medianITAE\n');
for vi=1:numel(variants)
    fprintf(fid,'%s,%.6g,%.6g,%.6g,%.6g\n', variants{vi}, pidStats(vi,1),pidStats(vi,2),pidStats(vi,3),pidStats(vi,4));
end
fclose(fid);

% best design metrics
[t,yb] = simClosedLoop(pidBest.x, plant);
mb = stepMetrics(t,yb);
% untuned baseline (proportional-only, modest gain)
[~,y0] = simClosedLoop([2 0 0], plant);
m0 = stepMetrics(t,y0);
fid = fopen(fullfile(outdir,'engineering_pid_best.txt'),'w');
fprintf(fid,'variant=%s\nKp=%.4f Ki=%.4f Kd=%.4f\nITAE=%.4f\n', pidBest.variant, pidBest.x(1),pidBest.x(2),pidBest.x(3), pidBest.cost);
fprintf(fid,'tuned:   overshoot=%.2f%% settling2pct=%.2fs ssErr=%.4g\n', mb.overshoot, mb.settling, mb.ssErr);
fprintf(fid,'baseline Kp2: overshoot=%.2f%% settling2pct=%.2fs ssErr=%.4g ITAE=%.4f\n', m0.overshoot, m0.settling, m0.ssErr, trapz(t, t(:).*abs(1-y0(:))));
fclose(fid);

% Fig 3: step responses baseline vs tuned
f3 = figure('Visible','off','Position',[100 100 560 380]);
plot(t,y0,'--','LineWidth',1.4,'Color',[0.55 0.55 0.55]); hold on
plot(t,yb,'-','LineWidth',1.8,'Color',[0.12 0.36 0.66]);
yline(1,':k');
xlim([0 40]); grid on
xlabel('Time (s)'); ylabel('Output y(t)');
legend({'Baseline (K_p=2, proportional)', sprintf('SOMA-tuned (%s)', pidBest.variant), 'Reference'}, 'Location','southeast');
title('PID step response before and after tuning');
exportgraphics(f3, fullfile(outdir,'fig3_pid_step.png'), 'Resolution', 200);

%% ---------------- Pressure vessel ----------------
fprintf('=== Pressure vessel ===\n');
pvObj = @(X) pvPenalizedVec(X, 1e7);
nv=4; lb=[0.0625 0.0625 10 10]; ub=[6.1875 6.1875 200 200];
seeds = 1:15; budget = 2e4;
pvStats = zeros(numel(variants),4);
pvBest.cost=Inf; pvBest.x=[]; pvBest.variant='';
pvConv = struct();
for vi=1:numel(variants)
    vname = variants{vi};
    costs = zeros(numel(seeds),1);
    for si=1:numel(seeds)
        opts = somaoptions('Variant',vname,'Seed',seeds(si), ...
            'MaxFunctionEvaluations',budget,'UseVectorized',true,'Display','off');
        [x,f] = somamin(pvObj, nv, lb, ub, opts);
        costs(si)=f;
        if f<pvBest.cost, pvBest.cost=f; pvBest.x=x; pvBest.variant=vname; end
    end
    pvStats(vi,:) = [min(costs) mean(costs) std(costs) median(costs)];
    opts = somaoptions('Variant',vname,'Seed',1,'MaxFunctionEvaluations',budget, ...
        'UseVectorized',true,'Display','off','RecordHistory',true);
    [~,~,~,out] = somamin(pvObj, nv, lb, ub, opts);
    pvConv.(vname).hist = out.bestfvalhistory;
    pvConv.(vname).fe   = feAxis(out);
    fprintf('  %-9s best=%.2f mean=%.2f std=%.2f\n', vname, pvStats(vi,1),pvStats(vi,2),pvStats(vi,3));
end
fid=fopen(fullfile(outdir,'engineering_vessel.csv'),'w');
fprintf(fid,'variant,bestCost,meanCost,stdCost,medianCost\n');
for vi=1:numel(variants)
    fprintf(fid,'%s,%.6g,%.6g,%.6g,%.6g\n', variants{vi}, pvStats(vi,1),pvStats(vi,2),pvStats(vi,3),pvStats(vi,4));
end
fclose(fid);

[trueCost,g] = pvRaw(pvBest.x);
fid=fopen(fullfile(outdir,'engineering_vessel_best.txt'),'w');
fprintf(fid,'variant=%s\nTs=%.4f Th=%.4f R=%.4f L=%.4f\npenalizedCost=%.4f trueCost=%.4f\nconstraints g=%s feasible=%d\n', ...
    pvBest.variant, pvBest.x(1),pvBest.x(2),pvBest.x(3),pvBest.x(4), pvBest.cost, trueCost, mat2str(g,5), all(g<=1e-6));
fclose(fid);

% Fig 4: convergence (best-so-far penalized cost vs FEs), median-seed traces
f4 = figure('Visible','off','Position',[100 100 560 380]);
cols = lines(numel(variants));
for vi=1:numel(variants)
    vname = variants{vi};
    semilogy(pvConv.(vname).fe, pvConv.(vname).hist, 'LineWidth',1.5,'Color',cols(vi,:)); hold on
end
grid on; xlabel('Function evaluations'); ylabel('Best-so-far cost (penalized)');
legend(variants, 'Location','northeast');
title('Pressure vessel: convergence by variant (seed 1)');
exportgraphics(f4, fullfile(outdir,'fig4_vessel_convergence.png'), 'Resolution', 200);

fprintf('DONE. Best PID %s ITAE=%.4f | Best vessel %s cost=%.2f (true %.2f)\n', ...
    pidBest.variant, pidBest.cost, pvBest.variant, pvBest.cost, trueCost);
end

% ================= helpers =================
function fe = feAxis(out)
m = numel(out.bestfvalhistory);
if m<=1, fe = out.funccount; return; end
fe = linspace(out.funccount/m, out.funccount, m);
end

function J = pidITAEvec(X, plant)
% Vectorized ITAE of closed-loop unit-step response. X is NP-by-3 (Kp Ki Kd).
NP = size(X,1);
Kp=X(:,1).'; Ki=X(:,2).'; Kd=X(:,3).';       % 1-by-NP
wn=plant.wn; zeta=plant.zeta; a0=wn^2; a1=2*zeta*wn;
T=40; dt=0.01; t=(0:dt:T).'; n=numel(t); r=1;
y1=zeros(1,NP); y2=zeros(1,NP); y3=zeros(1,NP);   % states across population
J = zeros(NP,1);
Yprev = y1; tprev = 0; acc = zeros(1,NP);
for i=1:n
    % ITAE accumulation via trapezoid on t*|1-y|
    wcur = t(i)*abs(1 - y1);
    if i>1, acc = acc + 0.5*dt*(wprev + wcur); end
    wprev = wcur;
    % RK4 step
    [k11,k12,k13]=deriv(y1,y2,y3);
    [k21,k22,k23]=deriv(y1+0.5*dt*k11, y2+0.5*dt*k12, y3+0.5*dt*k13);
    [k31,k32,k33]=deriv(y1+0.5*dt*k21, y2+0.5*dt*k22, y3+0.5*dt*k23);
    [k41,k42,k43]=deriv(y1+dt*k31, y2+dt*k32, y3+dt*k33);
    y1 = y1 + (dt/6)*(k11+2*k21+2*k31+k41);
    y2 = y2 + (dt/6)*(k12+2*k22+2*k32+k42);
    y3 = y3 + (dt/6)*(k13+2*k23+2*k33+k43);
    bad = ~isfinite(y1)|~isfinite(y2)|~isfinite(y3);
    if any(bad), y1(bad)=1e3; y2(bad)=0; y3(bad)=0; end
end
J = acc(:);
J(~isfinite(J)) = 1e6;
    function [d1,d2,d3]=deriv(s1,s2,s3)
        d1 = s2;
        d2 = -a0*s1 - a1*s2 + (Kp.*(r - s1) + Ki.*s3 - Kd.*s2);
        d3 = r - s1;
    end
end

function [t,y]=simClosedLoop(x, plant)
Kp=x(1);Ki=x(2);Kd=x(3); wn=plant.wn; zeta=plant.zeta; a0=wn^2; a1=2*zeta*wn;
T=40; dt=0.01; t=(0:dt:T).'; n=numel(t); y=zeros(n,1); s=[0;0;0]; r=1;
d=@(s)[s(2); -a0*s(1)-a1*s(2)+(Kp*(r-s(1))+Ki*s(3)-Kd*s(2)); r-s(1)];
for i=1:n
    y(i)=s(1);
    k1=d(s);k2=d(s+0.5*dt*k1);k3=d(s+0.5*dt*k2);k4=d(s+dt*k3);
    s=s+(dt/6)*(k1+2*k2+2*k3+k4);
    if any(~isfinite(s)), y(i:end)=Inf; return; end
end
end

function m=stepMetrics(t,y)
yf=y(end); m.ssErr=1-yf; m.overshoot=max(0,(max(y)-1)*100);
outside=find(abs(y-1)>0.02,1,'last');
if isempty(outside), m.settling=0; else, m.settling=t(min(outside+1,numel(t))); end
end

function J=pvPenalizedVec(X, pen)
[cost,g]=pvRawVec(X); viol=max(0,g); J=cost + pen*sum(viol.^2,2);
end
function [cost,g]=pvRawVec(X)
Ts=X(:,1);Th=X(:,2);R=X(:,3);L=X(:,4);
cost=0.6224.*Ts.*R.*L + 1.7781.*Th.*R.^2 + 3.1661.*Ts.^2.*L + 19.84.*Ts.^2.*R;
g=[-Ts+0.0193.*R, -Th+0.00954.*R, -pi.*R.^2.*L-(4/3)*pi.*R.^3+1296000, L-240];
end
function [cost,g]=pvRaw(x)
Ts=x(1);Th=x(2);R=x(3);L=x(4);
cost=0.6224*Ts*R*L+1.7781*Th*R^2+3.1661*Ts^2*L+19.84*Ts^2*R;
g=[-Ts+0.0193*R, -Th+0.00954*R, -pi*R^2*L-(4/3)*pi*R^3+1296000, L-240];
end
