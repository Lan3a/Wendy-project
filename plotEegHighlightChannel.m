function plotEegHighlightChannel(EEG, highlightChan, varargin)
% plotEegHighlightChannel - Plot EEG time series with one channel highlighted in red
%
% Usage:
%   plotEegHighlightChannel(EEG, highlightChan)
%   plotEegHighlightChannel(EEG, highlightChan, 'epoch', 5)
%   plotEegHighlightChannel(EEG, highlightChan, 'avg', true)
%
% Inputs:
%   EEG        - EEGLAB EEG structure
%   highlightChan - Channel(s) to highlight in red. Either:
%                   - numeric index or vector (e.g. 1, [1 5 10])
%                   - channel label or cell of labels (e.g. 'Fp1', {'Fp1','Pz'})
%
% Optional name-value pairs:
%   'epoch'    - [numeric] For epoched data: epoch index to plot (default: average all)
%   'avg'      - [logical] For epoched data: if true, plot average (default: true)
%   'xlim'     - [min max] X-axis limits in seconds
%   'chans'    - [numeric | cell] Subset of channels to plot (default: all)

% Parse inputs
p = inputParser;
addRequired(p, 'EEG', @isstruct);
addRequired(p, 'highlightChan', @(x) isnumeric(x) || ischar(x) || isstring(x) || iscell(x));
addParameter(p, 'epoch', [], @isnumeric);
addParameter(p, 'avg', true, @islogical);
addParameter(p, 'xlim', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2));
addParameter(p, 'chans', [], @(x) isempty(x) || isnumeric(x) || iscell(x));
parse(p, EEG, highlightChan, varargin{:});

% Resolve highlight channel(s) to indices
chanIdx = resolveHighlightChans(EEG, highlightChan);

% Channel subset (reversed order: last channel at bottom, first at top)
chansToPlot = p.Results.chans;
if isempty(chansToPlot)
    chansToPlot = EEG.nbchan:-1:1;
elseif iscell(chansToPlot)
    labels = {EEG.chanlocs.labels};
    chansToPlot = cellfun(@(c) find(strcmpi(c, labels)), chansToPlot);
    chansToPlot = chansToPlot(end:-1:1);
else
    chansToPlot = chansToPlot(end:-1:1);
end

% Get time vector
if isfield(EEG, 'times') && ~isempty(EEG.times)
    t = EEG.times;
else
    t = (0:EEG.pnts-1) / EEG.srate + EEG.xmin;
end

% Get data
if ndims(EEG.data) == 3  % epoched: [chans x pnts x trials]
    if ~isempty(p.Results.epoch)
        data = EEG.data(:, :, p.Results.epoch);
    elseif p.Results.avg
        data = mean(EEG.data, 3);
    else
        data = EEG.data(:, :, 1);  % first epoch
    end
else  % continuous
    data = EEG.data;
end

% Subset channels
data = data(chansToPlot, :);
chanList = chansToPlot;
highlightInSubset = find(ismember(chanList, chanIdx));

if isempty(highlightInSubset)
    warning('plotEegHighlightChannel:ChanNotInSubset', ...
        'No highlight channel(s) in plotted subset. Plotting all channels without highlight.');
end

% Vertical offset (typical EEG butterfly / stacked plot)
% 50% more zoom = reduce spacing by factor 1/1.5
offset = (0.8 / 1.5) * max(abs(data(:)));
yOffsets = (0:size(data,1)-1) * offset;

% Plot
hold on;
for k = 1:size(data, 1)
    y = data(k, :) + yOffsets(k);
    if ~isempty(highlightInSubset) && ismember(k, highlightInSubset)
        plot(t, y, 'r', 'LineWidth', 1.2);
    else
        plot(t, y, 'Color', [0.4 0.4 0.4], 'LineWidth', 0.8);
    end
end

% Axis
xlabel('Time (s)');
ylabel('Channel');
if ~isempty(p.Results.xlim)
    xlim(p.Results.xlim);
end
% Set ylim to encompass all channels with small margin (fix clipping)
yMin = min(data(:)) + yOffsets(1);
yMax = max(data(:)) + yOffsets(end);
yRange = max(diff([yMin yMax]), eps);
margin = 0.05 * yRange;
ylim([yMin - margin, yMax + margin]);

% Y-ticks = channel labels
if isfield(EEG, 'chanlocs') && ~isempty(EEG.chanlocs)
    yticklabels = {EEG.chanlocs(chanList).labels};
    set(gca, 'YTick', yOffsets, 'YTickLabel', yticklabels);
end

if isempty(chanIdx)
    title('EEG');
else
    hlLabels = strjoin({EEG.chanlocs(chanIdx).labels}, ', ');
    title(sprintf('EEG (%s highlighted in red)', hlLabels));
end
hold off;
grid on;
box on;

end

function chanIdx = resolveHighlightChans(EEG, highlightChan)
% Convert highlightChan (single/multi, index/label) to numeric indices
if iscell(highlightChan)
    labels = {EEG.chanlocs.labels};
    chanIdx = [];
    for c = 1:numel(highlightChan)
        idx = find(strcmpi(char(highlightChan{c}), labels));
        if ~isempty(idx)
            chanIdx(end+1) = idx(1); %#ok<AGROW>
        end
    end
    chanIdx = unique(chanIdx);
elseif isnumeric(highlightChan)
    chanIdx = highlightChan(:)';
    chanIdx = chanIdx(chanIdx >= 1 & chanIdx <= EEG.nbchan);
else
    labels = {EEG.chanlocs.labels};
    chanIdx = find(strcmpi(char(highlightChan), labels));
    if isempty(chanIdx)
        error('plotEegHighlightChannel:ChanNotFound', 'Channel "%s" not found.', char(highlightChan));
    end
    chanIdx = chanIdx(1);
end
end
