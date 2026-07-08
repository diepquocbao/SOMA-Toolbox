function packageToolbox(versionStr)
%PACKAGETOOLBOX Build SOMA-Toolbox-<version>.mltbx from the toolbox/ folder.
%   packageToolbox            uses the version in this file.
%   packageToolbox('1.0.0')   overrides the version string.
%
%   Requires MATLAB R2023a+ (matlab.addons.toolbox.ToolboxOptions). Produces
%   the .mltbx installer in the repository root. The packaged toolbox contains
%   only the toolbox/ folder (public functions, private implementations,
%   examples); tests/, benchmarks/, and development docs are excluded.

if nargin < 1
    versionStr = '0.1.0';
end

here = fileparts(mfilename('fullpath'));
toolboxFolder = fullfile(here, 'toolbox');
identifier = 'a1e0c9d2-0000-4000-8000-534f4d41544c';  % stable UUID for SOMA Toolbox
outputFile = fullfile(here, sprintf('SOMA-Toolbox-%s.mltbx', versionStr));

opts = matlab.addons.toolbox.ToolboxOptions(toolboxFolder, identifier);
opts.ToolboxName = 'SOMA Toolbox';
opts.ToolboxVersion = versionStr;
opts.Description = ['A unified MATLAB toolbox for the family of ' ...
    'Self-Organizing Migrating Algorithms (SOMA): AllToOne, AllToAll, ' ...
    'AllToAllAdaptive, AllToRand, T3A, Pareto, and iSOMA.'];
opts.Summary = 'The family of Self-Organizing Migrating Algorithms, one Global Optimization Toolbox-style interface.';
opts.AuthorName = 'Quoc Bao Diep';
opts.MinimumMatlabRelease = 'R2021a';
opts.OutputFile = outputFile;

gsGuide = fullfile(toolboxFolder, 'doc', 'GettingStarted.mlx');
if exist(gsGuide, 'file')
    opts.ToolboxGettingStartedGuide = gsGuide;
else
    warning('soma:packageToolbox', ...
        'doc/GettingStarted.mlx not found — run buildDocs first for the full package.');
end

iconFile = fullfile(here, 'soma_toolbox_icon.png');
if exist(iconFile, 'file')
    opts.ToolboxImageFile = iconFile;
else
    warning('soma:packageToolbox', ...
        'soma_toolbox_icon.png not found — run makeToolboxIcon first for the full package.');
end

matlab.addons.toolbox.packageToolbox(opts);
fprintf('Packaged: %s\n', outputFile);
end
