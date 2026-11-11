function padj = holm(p)
%HOLM Holm-Bonferroni adjusted p-values (NaN entries are ignored).
padj = nan(size(p));
idx = find(~isnan(p));
m = numel(idx);
if m == 0; return; end
[ps, order] = sort(p(idx));
adj = zeros(1, m);
running = 0;
for k = 1:m
    running = max(running, min(1, (m - k + 1) * ps(k)));
    adj(k) = running;
end
padj(idx(order)) = adj;
end
