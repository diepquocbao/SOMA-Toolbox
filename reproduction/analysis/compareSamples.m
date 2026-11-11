function r = compareSamples(x, refMean, refStd, yRef, nRef)
%COMPARESAMPLES Agreement statistics between a measured sample and a reference.
%   R = COMPARESAMPLES(X, REFMEAN, REFSTD, YREF, NREF) compares the measured
%   per-run errors X with a reference described by its mean and standard
%   deviation (REFMEAN, REFSTD, sample size NREF) and, when available, its
%   per-run sample YREF ([] otherwise). Errors below 1e-8 count as zero.
%   Fields of R:
%     tbMean, tbStd, relErrPct
%     z, pZ          two-sample z-test on the means from summary statistics
%     within1sd      |tbMean - refMean| <= refStd
%     pTost, equiv   two one-sided tests, equivalence margin = one reference
%                    standard deviation, alpha = 0.05
%     pRS, A         rank-sum test and Vargha-Delaney effect size on the
%                    per-run samples (NaN when YREF is empty)
x = x(:).'; x(x < 1e-8) = 0;
n = numel(x);
r.tbMean = mean(x); r.tbStd = std(x);
r.refMean = refMean; r.refStd = refStd;
r.relErrPct = 100 * abs(r.tbMean - refMean) / max(abs(refMean), 1e-8);
d = r.tbMean - refMean;
se = sqrt(r.tbStd^2 / n + refStd^2 / nRef);
if se == 0
    r.z = 0; r.pZ = 1;
else
    r.z = d / se; r.pZ = erfc(abs(r.z) / sqrt(2));
end
r.within1sd = abs(d) <= max(refStd, 1e-12);
delta = refStd;
if se == 0
    r.pTost = double(d ~= 0);                 % identical degenerate samples
elseif delta == 0
    r.pTost = 1;
else
    p1 = 0.5 * erfc(((d + delta) / se) / sqrt(2));     % H0: d <= -delta
    p2 = 0.5 * erfc((-(d - delta) / se) / sqrt(2));    % H0: d >= +delta
    r.pTost = max(p1, p2);
end
r.equiv = r.pTost < 0.05;
if isempty(yRef)
    r.pRS = NaN; r.A = NaN;
else
    y = yRef(:).'; y(y < 1e-8) = 0;
    [r.pRS, r.A] = rsTest(x, y);
end
end
