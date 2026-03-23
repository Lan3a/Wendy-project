function rejChannelSelectorGUI(EEG)
% Channel selector GUI with numbered buttons for channel names
% Style reference: rejICsButtons
% Top: Plot button (plotEegHighlightChannel with selected channels)
% Bottom: Plot Time Series, REJECT
% Channel buttons: click to select (red), used for highlight and reject

if ~isfield(EEG, 'chanlocs') || isempty(EEG.chanlocs)
    errordlg('EEG.chanlocs required.', 'Error', 'modal');
    return;
end

chanLabels = {EEG.chanlocs.labels};
nButtons   = numel(chanLabels);

% Parameters (rejICsButtons style)
nCols         = 3;
nRows         = ceil(nButtons / nCols);
buttonWidth   = 70;   % wider for channel names (e.g. FCz, T7)
buttonHeight  = 30;
gap           = 10;
topMargin     = 20;

% Figure size
figWidth  = nCols * buttonWidth + (nCols + 1) * gap;
figHeight = (nRows + 2) * buttonHeight + (nRows + 3) * gap + topMargin;

hFig = figure( ...
    'Name', 'EEG Channel Selector', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'NumberTitle', 'off', ...
    'Position', [300 300 figWidth figHeight], ...
    'Resize', 'off');

% Store selection state and button handles
selection = false(1, nButtons);
setappdata(hFig, 'selection', selection);

buttonHandles = gobjects(1, nButtons);
setappdata(hFig, 'buttonHandles', buttonHandles);

% Colors
defaultColor = get(hFig, 'Color');
activeColor  = [1 0.4 0.4];  % red-ish for selected
controlGray  = [0.8 0.8 0.8];

% --- Top: single Plot button (full width) ---
topBtnWidth = figWidth - 2 * gap;
uicontrol( ...
    'Parent',  hFig, ...
    'Style',   'pushbutton', ...
    'String',  'Plot', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', controlGray, ...
    'Position', [gap, figHeight - buttonHeight - gap, topBtnWidth, buttonHeight], ...
    'Callback', @(src, evt) plotCallback(hFig));

% --- Bottom: Plot Time Series (left), REJECT (right) ---
bottomBtnWidth = (figWidth - 3 * gap) / 2;
secondRowY = gap;

uicontrol( ...
    'Parent',  hFig, ...
    'Style',   'pushbutton', ...
    'String',  'Plot Time Series', ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', controlGray, ...
    'Position', [gap, secondRowY, bottomBtnWidth, buttonHeight], ...
    'Callback', @(src, evt) plotTimeSeriesCallback());

uicontrol( ...
    'Parent',  hFig, ...
    'Style',   'pushbutton', ...
    'String',  'REJECT', ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', controlGray, ...
    'Position', [2 * gap + bottomBtnWidth, secondRowY, bottomBtnWidth, buttonHeight], ...
    'Callback', @(src, evt) rejectCallback(hFig));

% --- Channel buttons in 3 columns ---
for k = 1:nButtons
    row = floor((k - 1) / nCols);
    col = mod((k - 1), nCols);

    xpos = gap + col * (buttonWidth + gap);
    ypos = figHeight - (2 * buttonHeight + 2 * gap) - row * (buttonHeight + gap);

    btn = uicontrol( ...
        'Parent',  hFig, ...
        'Style',   'pushbutton', ...
        'String',  chanLabels{k}, ...
        'Tag',     'channelButton', ...
        'FontSize', 9, ...
        'BackgroundColor', defaultColor, ...
        'Position', [xpos, ypos, buttonWidth, buttonHeight], ...
        'Callback', @(src, evt) channelButtonCallback(hFig, src, k, defaultColor, activeColor));

    buttonHandles(k) = btn;
end

setappdata(hFig, 'buttonHandles', buttonHandles);
end

% -------------------------------------------------------------------------
function channelButtonCallback(hFig, hButton, idx, defaultColor, activeColor)
% Toggle selection and button color
selection = getappdata(hFig, 'selection');

if selection(idx)
    selection(idx) = false;
    set(hButton, 'BackgroundColor', defaultColor);
else
    selection(idx) = true;
    set(hButton, 'BackgroundColor', activeColor);
end

setappdata(hFig, 'selection', selection);
end

% -------------------------------------------------------------------------
function plotCallback(hFig)
% Plot with selected channels highlighted via plotEegHighlightChannel
EEG = evalin('base', 'EEG');
selection = getappdata(hFig, 'selection');
selectedIdx = find(selection);

% Plot in a new figure (not in the GUI window)
figure();

% Call plotEegHighlightChannel with selected channel(s); empty = no highlight
plotEegHighlightChannel(EEG, selectedIdx);
end

% -------------------------------------------------------------------------
function plotTimeSeriesCallback()
EEG = evalin('base', 'EEG');
pop_eegplot(EEG, 1, 1, 1);
end

% -------------------------------------------------------------------------
function rejectCallback(hFig)
EEG = evalin('base', 'EEG');
selection = getappdata(hFig, 'selection');
selectedIdx = find(selection);

if isempty(selectedIdx)
    % No channels selected: accept current state
    chansToRemove = {};
    EEG.userCustom.toInterpCh = {};
else
    chanLabels = {EEG.chanlocs.labels};
    chansToRemove = chanLabels(selectedIdx);
    EEG = pop_select(EEG, 'rmchannel', chansToRemove);
    EEG.userCustom.toInterpCh = chansToRemove;
end

assignin('base', 'EEG', EEG);

% Update ALLEEG, CURRENTSET if they exist
try
    ALLEEG  = evalin('base', 'ALLEEG');
    CURRENTSET = evalin('base', 'CURRENTSET');
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'gui', 'off');
    assignin('base', 'ALLEEG', ALLEEG);
    assignin('base', 'EEG', EEG);
    assignin('base', 'CURRENTSET', CURRENTSET);
catch %#ok<CTCH>
end

close(hFig);
closeWindows('eegplot');
if ~isempty(chansToRemove)
    fprintf('Rejected channels: %s\n', strjoin(chansToRemove, ', '));
end
end
