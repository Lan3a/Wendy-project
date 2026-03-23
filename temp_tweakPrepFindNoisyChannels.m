

paths = addPaths();

% Find files to process
% -------------------------------------------------------------------------
inFolder  = 'C:\Users\user\Desktop\Work\PolyU RA\Wendy\preprocessed\old\b4_chan_interp';
outFolder = 'C:\Users\user\Desktop\Work\PolyU RA\Wendy\preprocessed\old\temp_new_b4_chan_interp';
inExt     = 'set';
outExt    = 'set';
dataFiles = findFilesToProcess({inFolder, inExt}, {outFolder, outExt});
% -------------------------------------------------------------------------

for i = 1:numel(dataFiles)
    while true
        % unpack
        fileName = dataFiles(i).name;
        baseName = dataFiles(i).baseName;
        filePath = dataFiles(i).filePath;

        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_loadset('filename',fileName,'filepath',inFolder);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

        eeglab redraw;
        pop_eegplot( EEG, 1, 1, 1);

        % Action selection GUI
        % -------------------------------------------------------------------------
        choice = askAction();
        switch choice
            case 'Save this and Continue'
                disp('saving...');
                break;
            case 'Save this and Exit'
                disp('saving...');
                error('>>>> Exited');
            case 'Skip this', close all; break;
            case 'Reset this', close all; continue;
            case 'Cancel', close all; error('>>>> Cancelled');
            otherwise, close all; error('>>>> Cancelled');
        end
        % -------------------------------------------------------------------------

    end
end


%%
for i = 1:length(eeg_files)
    while true
        % >> LOADING FILE
        eeg_file = char(eeg_files(i)); %REV
        eeg_file_path = fullfile(from_folder, eeg_file);
        eeg_file_name = erase(eeg_file, from_file_ext);

        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_loadset('filename',eeg_file,'filepath',from_folder);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        eeglab redraw;

        % -------------------------------------------------------------------------
        % >> PREPROCESSING
        eeglab redraw;
        pop_eegplot( EEG, 1, 1, 1);


        % -------------------------------------------------------------------------
        % >> SAVING
        choice = contDlg('Action', {'Save and Continue Next','Skip this','Save this and Exit','Reset','Cancel'});
        switch choice
            case 'Save and Continue Next'
                save_file_name = [eeg_file_name, '.set'];
                EEG = pop_saveset( EEG, 'filename',save_file_name,'filepath',to_folder);
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
                close all;
                break
            case 'Skip this'
                disp('Skipping')
                close all;
                break
            case 'Save this and Exit'
                save_file_name = [eeg_file_name, '.set'];
                EEG = pop_saveset( EEG, 'filename',save_file_name,'filepath',to_folder);
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
                close all;
                error('Data saved! Cancelled the rest.')
            case 'Reset'
                close all;
                continue
            case 'Cancel'
                close all;
                error('Cancelled');
            otherwise
                close all;
                error('Cancelled');
        end
    end

end
disp('>> Done'); beep;


























%% Auto Preprocess 1
from_folder = fullfile(FOLDER_DATA, 'raw');
from_file_ext = '.edf';
to_folder = fullfile(FOLDER_PREPROCESS_BATCH, 'b4_chan_interp');
to_file_ext = '.set';
if ~isfolder(to_folder), mkdir(to_folder), end

eeg_files = findFilesToProcess(from_folder, from_file_ext, '_raw', to_folder, to_file_ext, '');

for i = 1:length(eeg_files)
    % >> LOADING FILE
    eeg_file = char(eeg_files(i)); %REV
    eeg_file_path = fullfile(from_folder, eeg_file);
    eeg_file_name = erase(eeg_file, [string(from_file_ext), "_raw"]); %REV-must be string

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    file_path = fullfile(from_folder, eeg_file);
    EEG = pop_biosig(char(file_path));
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');

    % -------------------------------------------------------------------------
    % >> PREPROCESSING
    % adjust channel names and positions
    EEG = pop_select( EEG, 'rmchannel',{'CM','A1-Pz','X3-Pz','X2-Pz','X1-Pz','A2-Pz','Trigger'});
    EEG=pop_chanedit(EEG, {'lookup','standard_1005.elc'},'changefield',{1,'labels','P3'},'changefield',{2,'labels','C3'},'changefield',{3,'labels','F3'},'changefield',{4,'labels','Fz'},'changefield',{5,'labels','F4'},'changefield',{6,'labels','C4'},'changefield',{7,'labels','P4'},'changefield',{8,'labels','Cz'},'changefield',{9,'labels','Fp1'},'changefield',{10,'labels','Fp2'},'changefield',{11,'labels','T3'},'changefield',{12,'labels','T5'},'changefield',{13,'labels','O1'},'changefield',{14,'labels','O2'},'changefield',{15,'labels','F7'},'changefield',{16,'labels','F8'},'changefield',{17,'labels','T6'},'changefield',{18,'labels','T4'},'changefield',{18,'labels','T4'},'lookup','standard_1005.elc');
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    % remove the first second
    EEG = pop_select( EEG, 'rmtime',[0 1] );
    
    % resample (NO NEED)
    
    % filter
    EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',50);
    EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
    
    % -------------------------------------------------------------------------
    % >> SAVING
    eeglab redraw

    save_file_name = [eeg_file_name, to_file_ext];
    EEG = pop_saveset( EEG, 'filename',save_file_name,'filepath',to_folder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

end
disp('>> Done'); beep;