function makeToolboxIcon
%MAKETOOLBOXICON Generate soma_toolbox_icon.png (Add-On Manager image).
%   Draws the SOMA idea in one picture: a population of individuals migrating
%   across an optimization landscape toward the leader at the global optimum.
%   512x512 PNG, regenerated deterministically by this script.

here = fileparts(mfilename('fullpath'));
out = fullfile(here, 'soma_toolbox_icon.png');

% --- Landscape: smooth multimodal surface, global optimum upper-right
n = 900;
[X, Y] = meshgrid(linspace(-1, 1, n));
g = @(x0, y0, s) exp(-((X-x0).^2 + (Y-y0).^2) / (2*s^2));
Z =   1.00*g( 0.38,  0.30, 0.42) ...
    + 0.38*g(-0.55, -0.42, 0.26) ...
    + 0.30*g(-0.42,  0.58, 0.18) ...
    + 0.24*g( 0.55, -0.62, 0.16);

f = figure('Visible', 'off', 'Units', 'pixels', 'Position', [100 100 512 512]);
ax = axes(f, 'Position', [0 0 1 1]);
hold(ax, 'on');

contourf(ax, X, Y, Z, 16, 'LineStyle', 'none');
contour(ax, X, Y, Z, 16, 'LineColor', [0.35 0.50 0.68], 'LineWidth', 0.4);

% Colormap: deep navy -> teal -> gold (gold ends up at the optimum)
stops = [ 8  16  42;      % deep navy
         16  60 104;      % blue
         31 138 140;      % teal
        242 193  78] / 255;% gold
cmap = interp1(linspace(0, 1, size(stops,1)), stops, linspace(0, 1, 256));
colormap(ax, cmap);

% --- Leader at the global optimum: glow + star
lx = 0.38; ly = 0.30;
plot(ax, lx, ly, 'o', 'MarkerSize', 42, 'MarkerEdgeColor', 'none', ...
    'MarkerFaceColor', [1.0 0.85 0.4], 'Color', [1 1 1]);
plot(ax, lx, ly, 'o', 'MarkerSize', 30, 'MarkerEdgeColor', 'none', ...
    'MarkerFaceColor', [1.0 0.93 0.65]);
plot(ax, lx, ly, 'p', 'MarkerSize', 26, 'MarkerFaceColor', [0.05 0.10 0.25], ...
    'MarkerEdgeColor', 'none');

% --- Migrating individuals: curved trails converging on the leader
starts = [-0.72 -0.55; -0.62 0.62; 0.10 -0.72; -0.80 0.05; 0.72 -0.35; 0.05 0.80];
bend   = [ 0.25; -0.22; 0.18; 0.20; -0.15; 0.12];      % lateral bow per trail
tEnd   = [ 0.55;  0.85; 0.62;  0.75; 0.48; 0.80];      % migration progress per trail
mSize  = [ 10;    12;   10;    11;   9;    11 ];
for k = 1:size(starts, 1)
    p0 = starts(k, :);
    p2 = [lx ly];
    mid = (p0 + p2)/2;
    dirv = (p2 - p0) / norm(p2 - p0);
    perp = [-dirv(2) dirv(1)];
    p1 = mid + bend(k)*perp;                            % quadratic Bezier control
    t = linspace(0, tEnd(k), 60).';                     % stop short of the leader
    B = (1-t).^2*p0 + 2*(1-t).*t*p1 + t.^2*p2;
    % trail fades in toward the individual
    for seg = 1:5
        i1 = 1 + (seg-1)*12; i2 = min(1 + seg*12, 60);
        plot(ax, B(i1:i2,1), B(i1:i2,2), '-', 'LineWidth', 1.6, ...
            'Color', [1 1 1 0.10 + 0.14*seg]);
    end
    % the individual (white dot with dark rim), at the head of the trail
    plot(ax, B(end,1), B(end,2), 'o', 'MarkerSize', mSize(k), ...
        'MarkerFaceColor', [1 1 1], 'MarkerEdgeColor', [0.05 0.10 0.25], ...
        'LineWidth', 1.2);
end

axis(ax, 'off');
axis(ax, 'equal');
xlim(ax, [-1 1]); ylim(ax, [-1 1]);

exportgraphics(f, out, 'Resolution', 96);
close(f);

% exportgraphics trims tightly; center-crop to a square (base MATLAB only)
img = imread(out);
[h, w, ~] = size(img);
s = min(h, w);
r0 = floor((h - s)/2); c0 = floor((w - s)/2);
imwrite(img(r0+1:r0+s, c0+1:c0+s, :), out);

info = imfinfo(out);
fprintf('Icon written: %s (%dx%d px)\n', out, info.Width, info.Height);
end
