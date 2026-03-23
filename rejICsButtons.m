function rejICsButtons(EEG)
% Simple EEG component selector with numbered buttons and a plot button

% Parameters
nButtons      = size(EEG.icaweights, 1);
nCols         = 3;
nRows         = ceil(nButtons / nCols);
buttonWidth   = 60;
buttonHeight  = 30;
gap           = 10;
topMargin     = 20;

% Figure size
figWidth  = nCols * buttonWidth + (nCols + 1) * gap;
figHeight = (nRows + 2) * buttonHeight + (nRows + 3) * gap + topMargin;

hFig = figure( ...
    'Name', 'EEG Component Selector', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'NumberTitle', 'off', ...
    'Position', [300 300 figWidth figHeight], ...
    'Resize', 'off');

% Store selection state, button handles, and Mark mode in appdata
selection = false(1, nButtons);
setappdata(hFig, 'selection', selection);

buttonHandles = gobjects(1, nButtons);
setappdata(hFig, 'buttonHandles', buttonHandles);

% Mark mode flag (OFF by default)
markMode = false;
setappdata(hFig, 'markMode', markMode);

% Colors
defaultColor      = get(hFig, 'Color');   % figure background (used for number buttons)
activeColor       = [1 0.4 0.4];          % red-ish for marked
controlGray       = [0.8 0.8 0.8];        % gray for control buttons
markOnColor       = [0.6 1.0 0.6];        % green when Mark is ON

% --- Top control buttons ---
topBtnWidth = (figWidth - 3 * gap) / 2;

% Mark toggle button (left) - OFF by default
markBtn = uicontrol( ...
    'Parent',  hFig, ...
    'Style',   'togglebutton', ...
    'String',  'Mark', ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', controlGray, ... % default OFF
    'Position', [gap, figHeight - buttonHeight - gap, topBtnWidth, buttonHeight], ...
    'Value', 0, ...
    'Callback', @(src, evt)markCallback(hFig, src, markOnColor, controlGray));

setappdata(hFig, 'markButton', markBtn);

% Plot button at the very top (right)
uicontrol( ...
    'Parent',  hFig, ...
    'Style',   'pushbutton', ...
    'String',  'plot', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', controlGray, ...
    'Position', [2 * gap + topBtnWidth, figHeight - buttonHeight - gap, topBtnWidth, buttonHeight], ...
    'Callback', @(src, evt)plotCallback(hFig));

% Bottom control buttons: "plot ICs" (left) and "REJECT" (right)
secondRowY = gap;

uicontrol( ...
    'Parent',  hFig, ...
    'Style',   'pushbutton', ...
    'String',  'plot ICs', ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', controlGray, ...
    'Position', [gap, secondRowY, topBtnWidth, buttonHeight], ...
    'Callback', @(src, evt)plotICsButtonCallback());

uicontrol( ...
    'Parent',  hFig, ...
    'Style',   'pushbutton', ...
    'String',  'REJECT', ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', controlGray, ...
    'Position', [2 * gap + topBtnWidth, secondRowY, topBtnWidth, buttonHeight], ...
    'Callback', @(src, evt)rejectButtonCallback());

% Create number buttons (1..nButtons) in 3 columns, as many rows as needed
for k = 1:nButtons
    row = floor((k - 1) / nCols);   % 0-based row index
    col = mod((k - 1), nCols);      % 0-based col index

    xpos = gap + col * (buttonWidth + gap);
    ypos = figHeight - (2 * buttonHeight + 2 * gap) ... % space for plot button + gap
        - row * (buttonHeight + gap);

    btn = uicontrol( ...
        'Parent',  hFig, ...
        'Style',   'pushbutton', ...
        'String',  num2str(k), ...
        'Tag',     'numberButton', ...
        'FontSize', 11, ...
        'BackgroundColor', defaultColor, ...
        'Position', [xpos, ypos, buttonWidth, buttonHeight], ...
        'Callback', @(src, evt)numberButtonCallback(hFig, src, k, defaultColor, activeColor));

    buttonHandles(k) = btn;
end

% Update stored handles
setappdata(hFig, 'buttonHandles', buttonHandles);
end

function numberButtonCallback(hFig, hButton, idx, defaultColor, activeColor)
% Number button: Mark ON = toggle mark (red); Mark OFF = single-plot that component
markMode = getappdata(hFig, 'markMode');

if ~markMode
    % Mark is OFF: single-plot mode - immediately plot this component only
    plotCallback(hFig, idx);
    return;
end

% Mark is ON: toggle selection state and button color
selection = getappdata(hFig, 'selection');

if selection(idx)
    % Was marked -> unmark
    selection(idx) = false;
    set(hButton, 'BackgroundColor', defaultColor);
else
    % Was not marked -> mark
    selection(idx) = true;
    set(hButton, 'BackgroundColor', activeColor);
end

setappdata(hFig, 'selection', selection);
end

function markCallback(hFig, hButton, onColor, offColor)
% Toggle Mark mode. Turning OFF does NOT clear marks or reset button colors.
markMode = logical(get(hButton, 'Value'));
setappdata(hFig, 'markMode', markMode);

if markMode
    % Turn button green (Mark ON)
    set(hButton, 'BackgroundColor', onColor);
else
    % Turn button back to gray (Mark OFF) - marks stay as they are
    set(hButton, 'BackgroundColor', offColor);
end
end

function plotCallback(hFig, varargin)
% Apply selection to EEG.reject.gcompreject and plot.
% With varargin{1} = idx: single-plot mode (plot that component only).
% Without varargin: use marked indices from selection.
selection = getappdata(hFig, 'selection');

% Access EEG from base workspace
EEG = evalin('base', 'EEG');

if ~isfield(EEG, 'reject') || ~isfield(EEG.reject, 'gcompreject')
    errordlg('EEG.reject.gcompreject does not exist.', 'Error', 'modal');
    return;
end

gcompreject = EEG.reject.gcompreject;

if ~isvector(gcompreject)
    errordlg('EEG.reject.gcompreject must be a 1D vector.', 'Error', 'modal');
    return;
end

% Ensure column vector
gcompreject = gcompreject(:);
n = numel(gcompreject);

% Set all to 0
gcompreject(:) = 0;

% Decide which indices to plot
if ~isempty(varargin)
    idx = varargin{1};
    selectedIdx = idx(idx >= 1 & idx <= n);
else
    maxIdx = min(n, numel(selection));
    selectedIdx = find(selection(1:maxIdx));
end

gcompreject(selectedIdx) = 1;

% Write back into EEG and base workspace
EEG.reject.gcompreject = gcompreject;
assignin('base', 'EEG', EEG);

closeWindows('eegplot');
plotAfterRejICs(EEG);

fprintf('Updated EEG.reject.gcompreject for components: %s\n', mat2str(selectedIdx));
end


function plotAfterRejICs(EEG)
components = find(EEG.reject.gcompreject == 1);
components = components(:)';
component_keep = setdiff_bc(1:size(EEG.icaweights,1), components);
compproj = EEG.icawinv(:, component_keep)*eeg_getdatact(EEG, 'component', component_keep, 'reshape', '2d');
compproj = reshape(compproj, size(compproj,1), EEG.pnts, EEG.trials);
eegplot( EEG.data(EEG.icachansind,:,:), 'srate', EEG.srate, 'title', 'Black = channel before rejection; red = after rejection -- eegplot()', ...
    'limits', [EEG.xmin EEG.xmax]*1000, 'data2', compproj);
end

% -------------------------------------------------------------------------

function plotICs(EEG)
closeWindows('pop_selectcomps');
n_ICs = size(EEG.icawinv,2);
pop_selectcomps(EEG, [1:n_ICs] );
end

function plotICsButtonCallback()
% Fetch EEG from base workspace and call plotICs
EEG = evalin('base', 'EEG');
plotICs(EEG);
end

% -------------------------------------------------------------------------

function confirmRejICs()
closeWindows('eegplot'); closeWindows('pop_selectcomps');

% Get marked indices from GUI and set gcompreject before rejection
hFig = gcf;
selection = getappdata(hFig, 'selection');

EEG     = evalin('base', 'EEG');
ALLEEG  = evalin('base', 'ALLEEG');
CURRENTSET = evalin('base', 'CURRENTSET');

% Ensure gcompreject exists and is proper size
if ~isfield(EEG, 'reject')
    EEG.reject = struct();
end
if ~isfield(EEG.reject, 'gcompreject')
    EEG.reject.gcompreject = false(size(EEG.icawinv, 2), 1);
end

gcompreject = EEG.reject.gcompreject(:);
n = numel(gcompreject);
maxIdx = min(n, numel(selection));
selectedIdx = find(selection(1:maxIdx));

% Set marked components to 1 in gcompreject
gcompreject(:) = 0;
gcompreject(selectedIdx) = 1;
EEG.reject.gcompreject = gcompreject;

% Perform rejection
EEG = pop_subcomp(EEG, [], 0);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui', 'off');

assignin('base', 'EEG', EEG);
assignin('base', 'ALLEEG', ALLEEG);
assignin('base', 'CURRENTSET', CURRENTSET);

% Close this GUI figure and reopen with fresh state (all buttons unmarked)
close(hFig);
rejICsButtons(EEG);
end

function rejectButtonCallback()
% Wrapper for the REJECT button
confirmRejICs();
end
