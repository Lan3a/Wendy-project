% =========================================================================
% Description: feature extraction and analysis script for Wendy's project
% 
% Author: Alan & Wendy
% 
% Changelog:
%   - 22-3-2026 | Added PSD extraction
% 
% =========================================================================
clc; clear; close all;

cfg.preprocessVer = 'v2_0';
cfg.analysisVer = 'v2_0';

paths = addPaths(cfg);
msgbox(["Check analysis version is correct !!"; '>>>>  ',cfg.analysisVer ]);

%% PSD feature extraction
% Find files to process
% -------------------------------------------------------------------------
inFolder  = fullfile(paths.preprocessed, 'Epoch rej done');
outFolder = fullfile(paths.analysis, 'PSD');
inExt     = 'set';
outExt    = 'mat';
dataFiles = findFilesToProcess({inFolder, inExt}, {outFolder, outExt});
% ------------------------------------

for i = 1:numel(dataFiles)
    while true
        % Unpack
        % -------------------------------------------------------------------------
        fileName = dataFiles(i).name;
        baseName = dataFiles(i).baseName;
        filePath = dataFiles(i).filePath;
        % ------------------------------------
        
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_loadset('filename',fileName,'filepath',inFolder);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

        % Using pwelch (typical approach)
        Fs = EEG.srate;
        nChans = EEG.nbchan;
        nEpochs = EEG.trials;
        % Epoch length in samples
        epochLen = EEG.pnts;
        % FFT length / number of frequency bins
        nfft = epochLen*2;
        nFreqs = floor(nfft/2) + 1;
        % Initialize PSD matrix: [channels × frequencies × epochs]
        PSD = zeros(nChans, nFreqs, nEpochs);
        for ch = 1:nChans
            for ep = 1:nEpochs
                [pxx, f] = pwelch(EEG.data(ch,:,ep), [], [], nfft, Fs);
                PSD(ch, :, ep) = pxx;
            end
        end
        
        % Save
        save(fullfile(outFolder, [baseName, '.mat']), 'PSD');
        
        break
    end
end
close all; beep; disp('Done!')








%% Compute Frontal Alpha Asymmetry (FAA) for 8 groups
% Each .mat file: PSD [channels x frequencies x epochs], variable f (frequency vector)
% File naming: {sid}_{pre/post}_{eo/ec}.mat  e.g. 10_pre_eo.mat

% === USER: Enter folder containing .mat files ===
dataFolder = 'C:\Users\user\Desktop\Work\PolyU RA\Wendy\analysis\v2_0\PSD';   % <-- CHANGE THIS

% Parameters
alphaBand = [8 13];
leftChan  = 'F3';
rightChan = 'F4';

load('chanlocs_ref.mat');
load('psd_freqs.mat');
chanlocs = {chanlocs_ref.labels};
idxLeft  = find(strcmpi(chanlocs, leftChan));
idxRight = find(strcmpi(chanlocs, rightChan));
if isempty(idxLeft) || isempty(idxRight)
    error('F3 or F4 not found in chanlocs_ref');
end


% Subject IDs by group (sorted)
group1_sids = sort([4, 10, 5, 3, 17, 9, 8, 20]);   % 8 subjects
group2_sids = sort([12, 1, 2, 16, 6, 15, 19, 21, 22]);  % 9 subjects

% Define 8 conditions: {groupIdx, time, state, subjectList}
% time: 'pre' | 'post'
% state: 'eo' | 'ec'
conditions = {
    {1, 'pre',  'eo', group1_sids};
    {1, 'pre',  'ec', group1_sids};
    {1, 'post', 'eo', group1_sids};
    {1, 'post', 'ec', group1_sids};
    {2, 'pre',  'eo', group2_sids};
    {2, 'pre',  'ec', group2_sids};
    {2, 'post', 'eo', group2_sids};
    {2, 'post', 'ec', group2_sids};
};

%% Scan folder for available .mat files (format: sid_pre/post_eo/ec.mat)
files = dir(fullfile(dataFolder, '*_*_*.mat'));
nCols = 8;

% Collect FAA per condition: cell array of [sid, FAA] per column
% Col 1-4: G1 pre_eo, pre_ec, post_eo, post_ec | Col 5-8: G2 same
FAA_byCol = cell(1, nCols);

for k = 1:length(files)
    [~, baseName, ~] = fileparts(files(k).name);
    tok = regexp(baseName, '^(\d+)_(pre|post)_(eo|ec)$', 'tokens');
    if isempty(tok)
        continue;
    end
    sid   = str2double(tok{1}{1});
    time  = tok{1}{2};
    state = tok{1}{3};

    % Assign group from sid (skip if not in either group)
    if ismember(sid, group1_sids)
        group = 1;
    elseif ismember(sid, group2_sids)
        group = 2;
    else
        continue;
    end

    % Column index: (group-1)*4 + time*2 + state
    % pre=0, post=1; eo=0, ec=1
    timeIdx = double(strcmpi(time, 'post'));
    stateIdx = double(strcmpi(state, 'ec'));
    col = (group - 1)*4 + timeIdx*2 + stateIdx + 1;

    fname = fullfile(dataFolder, files(k).name);
    dat = load(fname);
    if ~isfield(dat, 'PSD')
        warning('PSD not found in %s', files(k).name);
        continue;
    end
    PSD = dat.PSD;
    f = psd_freqs;
    % if isfield(dat, 'psd_freqs')
    %     f = dat.psd_freqs;
    % elseif isfield(dat, 'f')
    %     f = dat.f;
    % elseif isfield(dat, 'freq')
    %     f = dat.freq;
    % else
    %     warning('Frequency vector not found in %s', files(k).name);
    %     continue;
    % end

    % Alpha band mask
    alphaMask = f >= alphaBand(1) & f <= alphaBand(2);
    alphaLeft  = squeeze(mean(PSD(idxLeft,  alphaMask, :), 2));
    alphaRight = squeeze(mean(PSD(idxRight, alphaMask, :), 2));
    epsVal = 1e-10;
    alphaLeft  = alphaLeft  + epsVal;
    alphaRight = alphaRight + epsVal;
    FAA_val = mean(log(alphaRight) - log(alphaLeft));

    FAA_byCol{col} = [FAA_byCol{col}; sid, FAA_val];
end

% Build output matrix: sort each column by sid, pad to same row count
nRows = max(cellfun(@(c) size(c,1), FAA_byCol));
FAA_matrix = NaN(nRows, nCols);
for col = 1:nCols
    C = FAA_byCol{col};
    if isempty(C)
        continue;
    end
    [~, ord] = sort(C(:,1));
    C = C(ord, 2);
    FAA_matrix(1:length(C), col) = C;
end

% Summary
% Column labels for reference
colLabels = {'G1_pre_eo', 'G1_pre_ec', 'G1_post_eo', 'G1_post_ec', ...
             'G2_pre_eo', 'G2_pre_ec', 'G2_post_eo', 'G2_post_ec'};

fprintf('FAA matrix [%d x %d]:\n', nRows, nCols);
disp(array2table(FAA_matrix, 'VariableNames', colLabels));


%% Scan folder for available .mat files (format: sid_pre/post_eo/ec.mat)
files = dir(fullfile(dataFolder, '*_*_*.mat'));
nCols = 8;

% Collect FAA per condition: cell array of [sid, FAA] per column
% Col 1-4: G1 pre_eo, pre_ec, post_eo, post_ec | Col 5-8: G2 same
FAA_byCol = cell(1, nCols);

for k = 1:length(files)
    [~, baseName, ~] = fileparts(files(k).name);
    tok = regexp(baseName, '^(\d+)_(pre|post)_(eo|ec)$', 'tokens');
    if isempty(tok)
        continue;
    end
    sid   = str2double(tok{1}{1});
    time  = tok{1}{2};
    state = tok{1}{3};

    % Assign group from sid (skip if not in either group)
    if ismember(sid, group1_sids)
        group = 1;
    elseif ismember(sid, group2_sids)
        group = 2;
    else
        continue;
    end

    % Column index: (group-1)*4 + time*2 + state
    % pre=0, post=1; eo=0, ec=1
    timeIdx = double(strcmpi(time, 'post'));
    stateIdx = double(strcmpi(state, 'ec'));
    col = (group - 1)*4 + timeIdx*2 + stateIdx + 1;

    fname = fullfile(dataFolder, files(k).name);
    dat = load(fname);
    if ~isfield(dat, 'PSD')
        warning('PSD not found in %s', files(k).name);
        continue;
    end
    PSD = dat.PSD;
    f = psd_freqs;
    % if isfield(dat, 'psd_freqs')
    %     f = dat.psd_freqs;
    % elseif isfield(dat, 'f')
    %     f = dat.f;
    % elseif isfield(dat, 'freq')
    %     f = dat.freq;
    % else
    %     warning('Frequency vector not found in %s', files(k).name);
    %     continue;
    % end

    % Alpha band mask
    alphaMask = f >= alphaBand(1) & f <= alphaBand(2);
    alphaLeft  = squeeze(mean(PSD(idxLeft,  alphaMask, :), 2));
    alphaRight = squeeze(mean(PSD(idxRight, alphaMask, :), 2));
    epsVal = 1e-10;
    alphaLeft  = alphaLeft  + epsVal;
    alphaRight = alphaRight + epsVal;
    FAA_val = mean(log(alphaRight) - log(alphaLeft));

    FAA_byCol{col} = [FAA_byCol{col}; sid, FAA_val];
end

% Build output matrix: sort each column by sid, pad to same row count
nRows = max(cellfun(@(c) size(c,1), FAA_byCol));
FAA_matrix = NaN(nRows, nCols);
for col = 1:nCols
    C = FAA_byCol{col};
    if isempty(C)
        continue;
    end
    [~, ord] = sort(C(:,1));
    C = C(ord, 2);
    FAA_matrix(1:length(C), col) = C;
end

% Summary
% Column labels for reference
colLabels = {'G1_pre_eo', 'G1_pre_ec', 'G1_post_eo', 'G1_post_ec', ...
             'G2_pre_eo', 'G2_pre_ec', 'G2_post_eo', 'G2_post_ec'};

fprintf('FAA matrix [%d x %d]:\n', nRows, nCols);
disp(array2table(FAA_matrix, 'VariableNames', colLabels));



%% Compute FAA from relative PSD (rPSD)
% Uses rPSD instead of PSD: rPSD = PSD / sum(PSD) across frequencies per channel

% Scan folder for available .mat files (format: sid_pre/post_eo/ec.mat)
files = dir(fullfile(dataFolder, '*_*_*.mat'));
nCols = 8;

% Collect FAA per condition: cell array of [sid, FAA] per column
% Col 1-4: G1 pre_eo, pre_ec, post_eo, post_ec | Col 5-8: G2 same
FAA_byCol = cell(1, nCols);

for k = 1:length(files)
    [~, baseName, ~] = fileparts(files(k).name);
    tok = regexp(baseName, '^(\d+)_(pre|post)_(eo|ec)$', 'tokens');
    if isempty(tok)
        continue;
    end
    sid   = str2double(tok{1}{1});
    time  = tok{1}{2};
    state = tok{1}{3};

    % Assign group from sid (skip if not in either group)
    if ismember(sid, group1_sids)
        group = 1;
    elseif ismember(sid, group2_sids)
        group = 2;
    else
        continue;
    end

    % Column index: (group-1)*4 + time*2 + state
    % pre=0, post=1; eo=0, ec=1
    timeIdx = double(strcmpi(time, 'post'));
    stateIdx = double(strcmpi(state, 'ec'));
    col = (group - 1)*4 + timeIdx*2 + stateIdx + 1;

    fname = fullfile(dataFolder, files(k).name);
    dat = load(fname);
    if ~isfield(dat, 'PSD')
        warning('PSD not found in %s', files(k).name);
        continue;
    end
    PSD = dat.PSD;
    f = psd_freqs;

    % Compute relative PSD: rPSD = PSD / sum(PSD) across frequencies
    % PSD is [channels x frequencies x trials]
    totalPower = sum(PSD, 2);  % sum over frequency dimension
    totalPower(totalPower == 0) = 1;  % avoid division by zero
    rPSD = PSD ./ totalPower;

    % Alpha band mask
    alphaMask = f >= alphaBand(1) & f <= alphaBand(2);
    alphaLeft  = squeeze(mean(rPSD(idxLeft,  alphaMask, :), 2));
    alphaRight = squeeze(mean(rPSD(idxRight, alphaMask, :), 2));
    epsVal = 1e-10;
    alphaLeft  = alphaLeft  + epsVal;
    alphaRight = alphaRight + epsVal;
    FAA_val = mean(log(alphaRight) - log(alphaLeft));

    FAA_byCol{col} = [FAA_byCol{col}; sid, FAA_val];
end

% Build output matrix: sort each column by sid, pad to same row count
nRows = max(cellfun(@(c) size(c,1), FAA_byCol));
FAA_matrix = NaN(nRows, nCols);
for col = 1:nCols
    C = FAA_byCol{col};
    if isempty(C)
        continue;
    end
    [~, ord] = sort(C(:,1));
    C = C(ord, 2);
    FAA_matrix(1:length(C), col) = C;
end

% Summary
% Column labels for reference
colLabels = {'G1_pre_eo', 'G1_pre_ec', 'G1_post_eo', 'G1_post_ec', ...
             'G2_pre_eo', 'G2_pre_ec', 'G2_post_eo', 'G2_post_ec'};

fprintf('FAA matrix (from rPSD) [%d x %d]:\n', nRows, nCols);
disp(array2table(FAA_matrix, 'VariableNames', colLabels));









%% both (minus)

%% Compute FAA from both PSD and rPSD
% rPSD = PSD / sum(PSD) across frequencies per channel
% Outputs 8-col matrices and 4-col post-pre difference matrices

% Scan folder for available .mat files (format: sid_pre/post_eo/ec.mat)
files = dir(fullfile(dataFolder, '*_*_*.mat'));
nCols = 8;

% Collect FAA per condition: cell array of [sid, FAA] per column
% Col 1-4: G1 pre_eo, pre_ec, post_eo, post_ec | Col 5-8: G2 same
FAA_byCol_PSD  = cell(1, nCols);
FAA_byCol_rPSD = cell(1, nCols);

for k = 1:length(files)
    [~, baseName, ~] = fileparts(files(k).name);
    tok = regexp(baseName, '^(\d+)_(pre|post)_(eo|ec)$', 'tokens');
    if isempty(tok)
        continue;
    end
    sid   = str2double(tok{1}{1});
    time  = tok{1}{2};
    state = tok{1}{3};

    % Assign group from sid (skip if not in either group)
    if ismember(sid, group1_sids)
        group = 1;
    elseif ismember(sid, group2_sids)
        group = 2;
    else
        continue;
    end

    % Column index: (group-1)*4 + time*2 + state
    % pre=0, post=1; eo=0, ec=1
    timeIdx = double(strcmpi(time, 'post'));
    stateIdx = double(strcmpi(state, 'ec'));
    col = (group - 1)*4 + timeIdx*2 + stateIdx + 1;

    fname = fullfile(dataFolder, files(k).name);
    dat = load(fname);
    if ~isfield(dat, 'PSD')
        warning('PSD not found in %s', files(k).name);
        continue;
    end
    PSD = dat.PSD;
    f = psd_freqs;

    % Compute relative PSD: rPSD = PSD / sum(PSD) across frequencies
    % PSD is [channels x frequencies x trials]
    totalPower = sum(PSD, 2);  % sum over frequency dimension
    totalPower(totalPower == 0) = 1;  % avoid division by zero
    rPSD = PSD ./ totalPower;

    % Alpha band mask
    alphaMask = f >= alphaBand(1) & f <= alphaBand(2);
    epsVal = 1e-10;

    % FAA from PSD
    alphaLeft_P  = squeeze(mean(PSD(idxLeft,  alphaMask, :), 2));
    alphaRight_P = squeeze(mean(PSD(idxRight, alphaMask, :), 2));
    alphaLeft_P  = alphaLeft_P  + epsVal;
    alphaRight_P = alphaRight_P + epsVal;
    FAA_val_PSD = mean(log(alphaRight_P) - log(alphaLeft_P));
    FAA_byCol_PSD{col} = [FAA_byCol_PSD{col}; sid, FAA_val_PSD];

    % FAA from rPSD
    alphaLeft_R  = squeeze(mean(rPSD(idxLeft,  alphaMask, :), 2));
    alphaRight_R = squeeze(mean(rPSD(idxRight, alphaMask, :), 2));
    alphaLeft_R  = alphaLeft_R  + epsVal;
    alphaRight_R = alphaRight_R + epsVal;
    FAA_val_rPSD = mean(log(alphaRight_R) - log(alphaLeft_R));
    FAA_byCol_rPSD{col} = [FAA_byCol_rPSD{col}; sid, FAA_val_rPSD];
end

% Build output matrices: sort each column by sid, pad to same row count
nRows = max([cellfun(@(c) size(c,1), FAA_byCol_PSD), cellfun(@(c) size(c,1), FAA_byCol_rPSD)]);
FAA_matrix_PSD  = NaN(nRows, nCols);
FAA_matrix_rPSD = NaN(nRows, nCols);

for col = 1:nCols
    C = FAA_byCol_PSD{col};
    if ~isempty(C)
        [~, ord] = sort(C(:,1));
        C = C(ord, 2);
        FAA_matrix_PSD(1:length(C), col) = C;
    end
    C = FAA_byCol_rPSD{col};
    if ~isempty(C)
        [~, ord] = sort(C(:,1));
        C = C(ord, 2);
        FAA_matrix_rPSD(1:length(C), col) = C;
    end
end

% 8-column labels
colLabels8 = {'G1_pre_eo', 'G1_pre_ec', 'G1_post_eo', 'G1_post_ec', ...
              'G2_pre_eo', 'G2_pre_ec', 'G2_post_eo', 'G2_post_ec'};

% 4 columns: post - pre for each group/state
% Col 1: G1 eo (post-pre), Col 2: G1 ec, Col 3: G2 eo, Col 4: G2 ec
FAA_delta_PSD  = FAA_matrix_PSD(:, [3 4 7 8]) - FAA_matrix_PSD(:, [1 2 5 6]);
FAA_delta_rPSD = FAA_matrix_rPSD(:, [3 4 7 8]) - FAA_matrix_rPSD(:, [1 2 5 6]);

colLabels4 = {'G1_eo_post_pre', 'G1_ec_post_pre', 'G2_eo_post_pre', 'G2_ec_post_pre'};

% Summary
fprintf('FAA matrix (PSD) [%d x %d]:\n', nRows, nCols);
disp(array2table(FAA_matrix_PSD, 'VariableNames', colLabels8));

fprintf('FAA matrix (rPSD) [%d x %d]:\n', nRows, nCols);
disp(array2table(FAA_matrix_rPSD, 'VariableNames', colLabels8));

fprintf('FAA delta post-pre (PSD) [%d x 4]:\n', nRows);
disp(array2table(FAA_delta_PSD, 'VariableNames', colLabels4));

fprintf('FAA delta post-pre (rPSD) [%d x 4]:\n', nRows);
disp(array2table(FAA_delta_rPSD, 'VariableNames', colLabels4));























%% Plot FAA: 4 columns (Pre EO, Post EO, Pre EC, Post EC), G1 & G2 overlayed
% Run compute_FAA_groups.m first to generate FAA_matrix, nRows, nCols

if ~exist('FAA_matrix', 'var')
    error('FAA_matrix not found. Run compute_FAA_groups.m first.');
end
if nRows == 0
    warning('No data to plot.');
    return;
end

% FAA_matrix: cols 1-4 G1, cols 5-8 G2
% G1: pre_eo(1), pre_ec(2), post_eo(3), post_ec(4)
% G2: pre_eo(5), pre_ec(6), post_eo(7), post_ec(8)
% Plot order: Pre EO, Post EO, Pre EC, Post EC
colOrder   = [1, 3, 2, 4];   % G1 indices
colOrderG2 = [5, 7, 6, 8];   % G2 indices

condLabels = {'Pre EO', 'Post EO', 'Pre EC', 'Post EC'};
x = 1:4;
w = 0.35;  % bar half-width for grouping

% Compute mean and SE (ignoring NaN)
fun_mean = @(v) mean(v, 'omitnan');
fun_se   = @(v) std(v, 'omitnan') / sqrt(sum(~isnan(v)));

mG1 = arrayfun(@(c) fun_mean(FAA_matrix(:, colOrder(c))), 1:4);
mG2 = arrayfun(@(c) fun_mean(FAA_matrix(:, colOrderG2(c))), 1:4);
eG1 = arrayfun(@(c) fun_se(FAA_matrix(:, colOrder(c))), 1:4);
eG2 = arrayfun(@(c) fun_se(FAA_matrix(:, colOrderG2(c))), 1:4);

eG1(isnan(eG1)) = 0;
eG2(isnan(eG2)) = 0;

figure('Color', 'w');
hold on;
b1 = bar(x - w/2, mG1, w, 'FaceColor', [0.2 0.4 0.8], 'EdgeColor', 'none');
b2 = bar(x + w/2, mG2, w, 'FaceColor', [0.8 0.4 0.2], 'EdgeColor', 'none');
errorbar(x - w/2, mG1, eG1, 'k', 'LineStyle', 'none', 'LineWidth', 1.5, 'CapSize', 5);
errorbar(x + w/2, mG2, eG2, 'k', 'LineStyle', 'none', 'LineWidth', 1.5, 'CapSize', 5);
hold off;

set(gca, 'XTick', x, 'XTickLabel', condLabels);
ylabel('FAA (ln right - ln left)');
legend([b1, b2], {'Group 1', 'Group 2'}, 'Location', 'best');
title('Frontal Alpha Asymmetry');
grid on;
