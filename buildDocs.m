function buildDocs
%BUILDDOCS Generate the toolbox/doc HTML documentation.
%   Publishes the example scripts to HTML, generates function reference
%   pages from the help text (so they never drift from the source), converts
%   GettingStarted.m to a Live Script (GettingStarted.mlx, used as the
%   toolbox Getting Started guide), and builds the Help-browser search
%   database. Run this before packageToolbox whenever code, help text, or
%   examples change.
%
%   The static pages doc/index.html and doc/helptoc.xml are maintained by
%   hand and are NOT touched by this script.

here = fileparts(mfilename('fullpath'));
tbDir = fullfile(here, 'toolbox');
exDir = fullfile(tbDir, 'examples');
docDir = fullfile(tbDir, 'doc');
if ~exist(docDir, 'dir'), mkdir(docDir); end
addpath(tbDir);
addpath(exDir);  % publish() requires the published file to be on the path

% 1) Publish the examples (runs them; captures output and figures).
examples = {'GettingStarted', 'Example_PID_Tuning', ...
            'Example_PressureVessel', 'Example_CEC_Adapter'};
pubOpts = struct('format', 'html', 'outputDir', docDir, 'catchError', false);
for k = 1:numel(examples)
    src = fullfile(exDir, [examples{k} '.m']);
    fprintf('Publishing %s ...\n', examples{k});
    out = publish(src, pubOpts);
    fprintf('  -> %s\n', out);
    close all force
end

% 2) Function reference pages straight from the help text.
funcs = {'somamin', 'somaoptions', 'somaplotbestf'};
for k = 1:numel(funcs)
    h = help(funcs{k});
    page = ['<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">' ...
        sprintf('<title>%s</title>', funcs{k}) ...
        '<style>body{font-family:Arial,Helvetica,sans-serif;margin:2em auto;' ...
        'max-width:52em;padding:0 1em;color:#222}h1{color:#0076a8;' ...
        'border-bottom:2px solid #0076a8;padding-bottom:0.2em}' ...
        'pre{font-family:Consolas,Monaco,monospace;background:#f4f4f4;' ...
        'padding:1em;line-height:1.4;overflow-x:auto}</style></head><body>' ...
        sprintf('<h1>%s</h1><pre>%s</pre>', funcs{k}, htmlescape(h)) ...
        '<p><a href="index.html">Back to SOMA Toolbox overview</a></p>' ...
        '</body></html>'];
    fname = fullfile(docDir, [funcs{k} '.html']);
    fid = fopen(fname, 'w');
    fwrite(fid, unicode2native(page, 'UTF-8'));
    fclose(fid);
    fprintf('Wrote %s\n', fname);
end

% 3) GettingStarted.mlx for the Add-On "Open Getting Started Guide" button.
mlx = fullfile(docDir, 'GettingStarted.mlx');
try
    matlab.internal.liveeditor.openAndSave(fullfile(exDir, 'GettingStarted.m'), mlx);
    fprintf('Wrote %s\n', mlx);
catch e
    warning('soma:buildDocs', ...
        'Could not create GettingStarted.mlx (%s). Packaging will fall back to no guide.', ...
        e.message);
end

% 4) Search database so the pages are findable in the Help browser.
builddocsearchdb(docDir);

% builddocsearchdb also drops custom_toolbox.json, a machine-specific
% registration sidecar with absolute paths. It is not needed in the packaged
% toolbox, so remove it.
sidecar = fullfile(docDir, 'custom_toolbox.json');
if exist(sidecar, 'file'); delete(sidecar); end

fprintf('Documentation build complete: %s\n', docDir);
end

function s = htmlescape(s)
s = strrep(s, '&', '&amp;');
s = strrep(s, '<', '&lt;');
s = strrep(s, '>', '&gt;');
end
