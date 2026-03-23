% =========================================================================
% Description: semi-auto preprocess script for Wendy's project
% 
% Author: Alan & Wendy
% 
% Changelog:
%   - 21-3-2026 | added 2 custom GUI for bad channel detection and bad ICs detection
%   - 20-3-2026 | init v2.0
% 
% Preprocess version details:
%   - version 2.0
%   - 
% 
% 
% 
% =========================================================================
clc; clear; close all;

cfg.preprocessVer = 'v2_0';

paths = addPaths(cfg);
msgbox(["Check preprocess version is correct !!"; '>>>>  ',cfg.preprocessVer ]);

%% Fix data + filtering
% Find files to process
% -------------------------------------------------------------------------
inFolder  = paths.raw;
outFolder = fullfile(paths.preprocessed, 'filtered');
inExt     = 'edf';
outExt    = 'set';
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
        EEG = pop_biosig(filePath);
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');

        % adjust channel names and positions
        EEG = pop_select( EEG, 'rmchannel',{'CM','A1-Pz','X3-Pz','X2-Pz','X1-Pz','A2-Pz','Trigger'});
        EEG=pop_chanedit(EEG, {'lookup','standard_1005.elc'},'changefield',{1,'labels','P3'},'changefield',{2,'labels','C3'},'changefield',{3,'labels','F3'},'changefield',{4,'labels','Fz'},'changefield',{5,'labels','F4'},'changefield',{6,'labels','C4'},'changefield',{7,'labels','P4'},'changefield',{8,'labels','Cz'},'changefield',{9,'labels','Fp1'},'changefield',{10,'labels','Fp2'},'changefield',{11,'labels','T7'},'changefield',{12,'labels','P7'},'changefield',{13,'labels','O'},'changefield',{13,'labels','O1'},'changefield',{14,'labels','O2'},'changefield',{15,'labels','F7'},'changefield',{16,'labels','F8'},'changefield',{17,'labels','P8'},'changefield',{18,'labels','T8'},'lookup','standard_1005.elc','changefield',{1,'type','EEG'},'changefield',{2,'type','EEG'},'changefield',{3,'type','EEG'},'changefield',{4,'type','EEG'},'changefield',{5,'type','EEG'},'changefield',{6,'type','EEG'},'changefield',{7,'type','EEG'},'changefield',{8,'type','EEG'},'changefield',{9,'type','EEG'},'changefield',{10,'type','EEG'},'changefield',{11,'type','EEG'},'changefield',{12,'type','EEG'},'changefield',{13,'type','EEG'},'changefield',{14,'type','EEG'},'changefield',{15,'type','EEG'},'changefield',{16,'type','EEG'},'changefield',{17,'type','EEG'},'changefield',{18,'type','EEG'});
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

        % remove the first second
        EEG = pop_select( EEG, 'rmtime',[0 1] );

        % filtering
        EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',50);
        EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1);
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');

        EEG = pop_saveset( EEG, 'filename',fileName,'filepath',outFolder);
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        break
    end
end
close all; beep; disp('Done!')

%% Reject bad channels
% Find files to process
% -------------------------------------------------------------------------
inFolder  = fullfile(paths.preprocessed, 'filtered');
outFolder = fullfile(paths.preprocessed, 'bad channels rejected');
inExt     = 'set';
outExt    = 'set';
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

        pop_eegplot( EEG, 1, 1, 1);
        rejChannelSelectorGUI(EEG);

        % Action selection GUI
        % -------------------------------------------------------------------------
        choice = askAction();
        switch choice
            case 'Save this and Continue'
                EEG = pop_saveset( EEG, 'filename',fileName,'filepath',outFolder);
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
                disp('saving...');
                close all;
                break
            case 'Save this and Exit'
                EEG = pop_saveset( EEG, 'filename',fileName,'filepath',outFolder);
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
                disp('saving...');
                close all;
                error('>>>> Saved this one and Exited');
            case 'Skip this', close all; break;
            case 'Reset this', close all; continue;
            case 'Cancel', close all; error('>>>> Cancelled');
            otherwise, close all; error('>>>> Cancelled');
        end
        % ------------------------------------

    end
end
beep; disp('Done!')



%% CAR (re-reference) + interpolate rejected bad channels + run ICA
% Find files to process
% -------------------------------------------------------------------------
inFolder  = fullfile(paths.preprocessed, 'bad channels rejected');
outFolder = fullfile(paths.preprocessed, 'ICA ready');
inExt     = 'set';
outExt    = 'set';
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

        % CAR (re-reference)
        EEG = pop_reref( EEG, []);
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'gui','off');

        % interpolate rejected bad channels
        load(fullfile(paths.scripts, "chanlocs_ref.mat"))
        EEG = pop_interp(EEG, chanlocs_ref);

        % run ICA
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        % if isfield(EEG, 'userCustom') && isfield(EEG.userCustom, 'toInterpCh')
        %     nInterp = length(EEG.userCustom.toInterpCh);
        % else
        %     nInterp = 0;
        % end
        % 
        % if nInterp == 0
        %     EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');
        %     [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        % else
        %     ICA_nPCA = size(EEG.data,1) - nInterp;
        %     EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on','pca',ICA_nPCA);
        %     [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        % end
        
        % Save
        EEG = pop_saveset( EEG, 'filename',fileName,'filepath',outFolder);
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        break
    end
end
close all; beep; disp('Done!')



%% ICA rejection
% Find files to process
% -------------------------------------------------------------------------
inFolder  = fullfile(paths.preprocessed, 'ICA ready');
outFolder = fullfile(paths.preprocessed, 'ICA done');
inExt     = 'set';
outExt    = 'set';
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

        % ICA rejection
        rejICsButtons(EEG);

        % Action selection GUI
        % -------------------------------------------------------------------------
        choice = askAction();
        switch choice
            case 'Save this and Continue'
                EEG = pop_saveset( EEG, 'filename',fileName,'filepath',outFolder);
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
                disp('saving...');
                close all;
                break
            case 'Save this and Exit'
                EEG = pop_saveset( EEG, 'filename',fileName,'filepath',outFolder);
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
                disp('saving...');
                close all;
                error('>>>> Saved this one and Exited');
            case 'Skip this', close all; break;
            case 'Reset this', close all; continue;
            case 'Cancel', close all; error('>>>> Cancelled');
            otherwise, close all; error('>>>> Cancelled');
        end
        % ------------------------------------

    end
end
beep; disp('Done!')


%% Epoch rejection
% Find files to process
% -------------------------------------------------------------------------
inFolder  = fullfile(paths.preprocessed, 'ICA done');
outFolder = fullfile(paths.preprocessed, 'Epoch rej done');
inExt     = 'set';
outExt    = 'set';
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

        % Epoch data
        epoch_sec = 2;
        srate = EEG.srate;
        n_pnts = EEG.pnts;
        n_chans = EEG.nbchan;
        samples_per_epoch = round(epoch_sec * srate);   % 2 seconds in samples
        n_epochs = ceil(n_pnts / samples_per_epoch);

        epoched_data = EEG.data;
        more_pnts = (n_epochs * samples_per_epoch) - n_pnts;
        pnts_array = zeros(n_chans, more_pnts);
        epoched_data = [epoched_data, pnts_array];
        epoched_data = reshape(epoched_data, n_chans, samples_per_epoch, n_epochs);

        load(fullfile(paths.scripts, 'chanlocs_ref.mat'));
        EEG = pop_importdata('setname','epoched data', 'data','epoched_data', 'dataformat','array', 'chanlocs', 'chanlocs_ref', 'srate', srate, 'pnts', srate);
        % ^ Simply use pop_importdata() to put the epoched data in, everything
        % else will be adjusted. It's better than forcibly subbing the
        % epoched_data to EEG.data, use their own functions for it to adjust
        % workspace vars manually.
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 

        eeglab redraw

        % manual epoch rejection
        pop_rejmenu(EEG, 1)



        % Action selection GUI
        % -------------------------------------------------------------------------
        choice = askAction();
        switch choice
            case 'Save this and Continue'
                EEG = pop_saveset( EEG, 'filename',fileName,'filepath',outFolder);
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
                disp('saving...');
                close all;
                break
            case 'Save this and Exit'
                EEG = pop_saveset( EEG, 'filename',fileName,'filepath',outFolder);
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
                disp('saving...');
                close all;
                error('>>>> Saved this one and Exited');
            case 'Skip this', close all; break;
            case 'Reset this', close all; continue;
            case 'Cancel', close all; error('>>>> Cancelled');
            otherwise, close all; error('>>>> Cancelled');
        end
        % ------------------------------------

    end
end
beep; disp('Done!')










%% TODO save this

from_folder = fullfile(FOLDER_PREPROCESS_BATCH, 'af_epoch_rej');
from_file_ext = '.set';
to_folder = fullfile(FOLDER_PREPROCESS_BATCH, 'preprocessed');
to_file_ext = '.mat';
if ~isfolder(to_folder), mkdir(to_folder), end

eeg_files = findFilesToProcess(from_folder, from_file_ext, '', to_folder, to_file_ext, '');

for i = 1:length(eeg_files)
    % >> LOADING FILE
    eeg_file = char(eeg_files(i)); 
    eeg_file_path = fullfile(from_folder, eeg_file);
    eeg_file_name = erase(eeg_file, from_file_ext);

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',eeg_file,'filepath',from_folder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    eeglab redraw;

    % -------------------------------------------------------------------------
    % >> SAVING
    % !! can't save 3D matrix in .csv
    % save_file_path = fullfile(to_folder, eeg_file_name + ".csv");
    % writematrix(EEG.data, save_file_path);

    S = EEG;

    save_file_path = fullfile(to_folder, [eeg_file_name, '.mat']);
    save(save_file_path, 'S');

end
disp('>> Done'); beep;