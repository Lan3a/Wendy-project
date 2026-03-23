
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','4_post_ec.set','filepath','C:\\Users\\user\\Desktop\\Work\\PolyU RA\\Wendy_Acupressure\\PREPROCESS\\batch\\v1.0\\b4_ICA_rej\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
eeglab redraw
% pop_selectcomps(EEG, [1:17] );
% pop_eegplot( EEG, 1, 1, 1);
% [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
% EEG = pop_subcomp( EEG, [], 0);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 

%%
plotWithRejICs(EEG)

%%
closeWindows('eegplot')

%%
function plotWithRejICs(EEG)
components = find(EEG.reject.gcompreject == 1);
components = components(:)';
component_keep = setdiff_bc(1:size(EEG.icaweights,1), components);
compproj = EEG.icawinv(:, component_keep)*eeg_getdatact(EEG, 'component', component_keep, 'reshape', '2d');
compproj = reshape(compproj, size(compproj,1), EEG.pnts, EEG.trials);
eegplot( EEG.data(EEG.icachansind,:,:), 'srate', EEG.srate, 'title', 'Black = channel before rejection; red = after rejection -- eegplot()', ...
            	 'limits', [EEG.xmin EEG.xmax]*1000, 'data2', compproj); 
end


function closeWindows(name)
figs = findall(0, 'Type', 'figure');
names = get(figs, 'Name');
if ischar(names)
    names = {names};
end
idx = contains(names, name, 'IgnoreCase', true);  % figures whose Name has the word
close(figs(idx));                                 % close those figures
end