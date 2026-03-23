function paths = addPaths(cfg)

% define folder paths
paths.scripts = fileparts(mfilename('fullpath'));
[paths.root, ~] = fileparts(paths.scripts);

% raw
paths.raw = fullfile(paths.root, 'raw');
if ~exist(paths.raw, 'dir')
    mkdir(paths.raw)
end

% preproces
if isfield(cfg, 'preprocessVer')
    paths.preprocessed = fullfile(paths.root, 'preprocess', cfg.preprocessVer);
    if ~exist(paths.preprocessed, 'dir')
        mkdir(paths.preprocessed)
    end
end

% analysis
if isfield(cfg, 'analysisVer')
    paths.analysis = fullfile(paths.root, 'analysis', cfg.analysisVer);
    if ~exist(paths.analysis, 'dir')
        mkdir(paths.analysis)
    end
end

% temp
paths.temp = fullfile(paths.root, 'temp');
disp(paths.root)




if ~exist(paths.temp, 'dir')
    mkdir(paths.temp)
end


% Add paths
addpath(genpath(paths.root)) % WARN might not need to add all




%%
% automagic = 'automagic';
% libName = 'matlab_scripts';
% srcFolder = 'src';
% guiFolder = 'gui';
% preproFolder = 'preprocessing';
% pluginFolder = 'eeglab_plugin';
% 
% 
% 
% if ~strcmp(automagicPath(end), filesep)
%     automagicPath = strcat(automagicPath, filesep);
% end
% automagicPath = regexp(automagicPath, ['.*' automagic '.*?' filesep], 'match');
% automagicPath = automagicPath{1};
% if ~strcmp(automagicPath(end), filesep)
%     automagicPath = strcat(automagicPath, filesep);
% end
% addpath(automagicPath);
% addpath([automagicPath srcFolder filesep])
% addpath([automagicPath guiFolder filesep])
% addpath([automagicPath preproFolder filesep])
% addpath([automagicPath libName filesep])
% addpath([automagicPath pluginFolder filesep])
% 
% 
% pathCheck{1}=automagicPath;
% pathCheck{2}=[automagicPath srcFolder filesep];
% pathCheck{3}=[automagicPath guiFolder filesep];
% pathCheck{4}=[automagicPath preproFolder filesep];
% pathCheck{5}=[automagicPath libName filesep];
% pathCheck{6}=[automagicPath pluginFolder filesep];
% matlabPaths = matlabpath;
% parts = strsplit(matlabPaths, pathsep);
% Index = contains(parts, pathCheck);
% if sum(Index)<5
%     warning('You need to include Automagic in your matlab path');
% end

end