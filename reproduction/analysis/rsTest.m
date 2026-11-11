function [p, A, z] = rsTest(x, y)
%RSTEST Two-sided Wilcoxon rank-sum test (normal approximation) in base MATLAB.
%   [P, A, Z] = RSTEST(X, Y) compares two independent samples. P is the
%   two-sided p-value from the normal approximation with tie correction and
%   continuity correction; A is the Vargha-Delaney effect size, the
%   probability that a value drawn from X exceeds one drawn from Y (ties
%   count one half; 0.5 means no difference).
x = x(:); y = y(:);
n1 = numel(x); n2 = numel(y); N = n1 + n2;
v = [x; y];
[s, order] = sort(v);
ranks = zeros(N, 1);
tieTerm = 0;
i = 1;
while i <= N
    j = i;
    while j < N && s(j + 1) == s(i)
        j = j + 1;
    end
    ranks(order(i:j)) = (i + j) / 2;
    t = j - i + 1;
    tieTerm = tieTerm + (t^3 - t);
    i = j + 1;
end
U = sum(ranks(1:n1)) - n1 * (n1 + 1) / 2;
A = U / (n1 * n2);
mu = n1 * n2 / 2;
sigma2 = n1 * n2 / 12 * ((N + 1) - tieTerm / (N * (N - 1)));
if sigma2 <= 0
    z = 0; p = 1;
    return
end
d = U - mu;
z = (d - 0.5 * sign(d)) / sqrt(sigma2);
p = erfc(abs(z) / sqrt(2));
end
