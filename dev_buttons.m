function dev_buttons()
    % EDITABLE BUTTON LAUNCHER
    % This script creates a GUI with buttons that execute MATLAB scripts.
    % A refresh button reloads scripts from the dev_button_scripts folder.

    % Load button configurations from script files in dev_button_scripts folder
    buttons = loadButtonsFromScripts();
    
    % --- GUI Layout Parameters ---
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    
    % Grid layout: 2 columns for code buttons
    buttons_per_row = 2;
    num_buttons = numel(buttons);
    
    % Calculate grid positions
    num_rows_of_buttons = ceil(num_buttons / buttons_per_row);
    
    % Calculate figure size
    min_fig_width = 300;
    min_fig_height = 150;
    
    % Width: 2 columns of buttons + gaps
    fig_width = 2 * button_width + 3 * button_gap; 
    
    % Height: Refresh button row + button rows + gaps
    fig_height = (1 + num_rows_of_buttons) * (button_height + button_gap) + button_gap;
    
    fig_width = max(fig_width, min_fig_width);
    fig_height = max(fig_height, min_fig_height);
    
    % Check if figure already exists
    hFig = findall(0, 'Type', 'figure', 'Tag', 'EditableButtonLauncher');
    if ~isempty(hFig)
        figure(hFig); % Bring existing GUI to front
        % Update the existing figure with current data
        setappdata(hFig, 'buttons', buttons);
        updateInterface(hFig);
        return;
    end
    
    % Create figure
    hFig = figure('Name', 'Script Button Launcher', 'Tag', 'EditableButtonLauncher', ...
        'MenuBar', 'none', 'ToolBar', 'none', 'Position', [300 300 fig_width fig_height], ...
        'Resize', 'on', 'ResizeFcn', @(src,evt)resizeFigureCallback(src, evt));
    
    % Store variables in figure's application data
    setappdata(hFig, 'buttons', buttons);
    
    % Create UI components
    createUIComponents(hFig);
    
    % Create buttons
    createCodeButtons(hFig);
end

function createUIComponents(hFig)
    % Create all UI components and store their handles
    
    % Get figure dimensions
    fig_pos = get(hFig, 'Position');
    fig_width = fig_pos(3);
    fig_height = fig_pos(4);
    
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    
    % Position refresh button at top
    refreshBtn = uicontrol('Style', 'pushbutton', 'String', 'Refresh Scripts', ...
        'Position', [button_gap, fig_height - button_height - button_gap, button_width, button_height], ...
        'FontSize', 10, 'FontWeight', 'bold', 'Tag', 'controlButton', ...
        'Callback', @(src,evt)refreshButtons(hFig));
    
    % Store button handles
    setappdata(hFig, 'refreshButton', refreshBtn);
end

function createCodeButtons(hFig)
    % Create only the code buttons (not control buttons)
    
    % Get stored data
    buttons = getappdata(hFig, 'buttons');
    
    % Clear existing code buttons only (preserve control buttons)
    childHandles = get(hFig, 'Children');
    codeButtonHandles = childHandles(arrayfun(@(h) isequal(get(h, 'Tag'), 'codeButton'), childHandles));
    delete(codeButtonHandles);
    
    % GUI layout parameters
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    buttons_per_row = 2;
    
    num_buttons = numel(buttons);
    fig_pos = get(hFig, 'Position');
    fig_width = fig_pos(3);
    fig_height = fig_pos(4);
    
    % Create buttons in 2-column grid
    % Starting below the control buttons row
    for i = 1:num_buttons
        % Calculate grid position
        row = floor((i-1) / buttons_per_row);
        col = mod(i-1, buttons_per_row);
        
        % Position buttons starting from second row
        xpos = button_gap + col * (button_width + button_gap);
        ypos = fig_height - (2 * button_height + 2 * button_gap) - row * (button_height + button_gap);
        
        % Execute the script file when button is pressed
        scriptPath = buttons{i}.script;
        callback = @(src,evt)runScript(scriptPath);
        
        uicontrol('Style', 'pushbutton', 'String', buttons{i}.name, ...
            'Position', [xpos ypos button_width button_height], ...
            'FontSize', 12, 'Tag', 'codeButton', ...
            'Callback', callback);
    end
end

function updateInterface(hFig)
    % Update the entire interface without recreating the figure
    % Update code buttons
    createCodeButtons(hFig);
    
    % Resize figure to fit content
    resizeFigureToFitButtons(hFig);
end

function refreshButtons(hFig)
    % Refresh button list from scripts
    buttons = loadButtonsFromScripts();
    
    % Update stored buttons
    setappdata(hFig, 'buttons', buttons);
    
    % Update interface
    updateInterface(hFig);
end

function resizeFigureToFitButtons(hFig)
    % Resize the figure to fit all buttons properly
    buttons = getappdata(hFig, 'buttons');
    num_buttons = numel(buttons);
    
    % GUI layout parameters
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    buttons_per_row = 2;
    
    % Calculate grid positions
    num_rows_of_buttons = ceil(num_buttons / buttons_per_row);
    
    % Calculate figure size
    min_fig_width = 300;
    min_fig_height = 150;
    
    % Width: 2 columns of buttons + gaps
    fig_width = 2 * button_width + 3 * button_gap; 
    
    % Height: Refresh button row + button rows + gaps
    fig_height = (1 + num_rows_of_buttons) * (button_height + button_gap) + button_gap;
    
    fig_width = max(fig_width, min_fig_width);
    fig_height = max(fig_height, min_fig_height);
    
    % Get current position and update size
    current_pos = get(hFig, 'Position');
    new_pos = [current_pos(1), current_pos(2), fig_width, fig_height];
    set(hFig, 'Position', new_pos);
end

function resizeFigureCallback(src, evt)
    % Handle figure resize events
    % Reposition control buttons when figure is resized
    hFig = src;
    
    % Get new figure dimensions
    fig_pos = get(hFig, 'Position');
    fig_width = fig_pos(3);
    fig_height = fig_pos(4);
    
    % Get control button handles
    refreshBtn = getappdata(hFig, 'refreshButton');
    
    % Reposition refresh button
    button_height = 40;
    button_gap = 10;
    button_width = 120;
    
    % Refresh Button
    set(refreshBtn, 'Position', [button_gap, fig_height - button_height - button_gap, button_width, button_height]);
    
    % Recreate code buttons to adjust their positions
    createCodeButtons(hFig);
end

function buttons = loadButtonsFromScripts()
    % Load button configurations from MATLAB script files in dev_button_scripts folder
    buttons = {};
    
    % Define the script folder path (relative to the current script location)
    scriptFolder = fullfile(fileparts(mfilename('fullpath')), 'dev_button_scripts');
    
    % Check if the folder exists
    if ~exist(scriptFolder, 'dir')
        % Try alternative path
        scriptFolder = 'support_functions/dev_button_scripts';
        if ~exist(scriptFolder, 'dir')
            return;
        end
    end
    
    % Get all .m files in the dev_button_scripts folder
    scriptFiles = dir(fullfile(scriptFolder, '*.m'));
    
    % Create button structs for each script
    for i = 1:length(scriptFiles)
        % Extract name from filename (without extension)
        [~, name, ~] = fileparts(scriptFiles(i).name);
        
        % Create button struct with name and script path
        buttons{end+1} = struct('name', name, 'script', fullfile(scriptFolder, scriptFiles(i).name));
    end
end

function runScript(scriptPath)
    % Execute a MATLAB script file
    if exist(scriptPath, 'file')
        % Run the script
        run(scriptPath);
    else
        errordlg(['Script file not found: ' scriptPath], 'File Not Found', 'modal');
    end
end