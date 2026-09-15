%% state-preprocessing
raw_path = '/Users/......';
cd(raw_path)  
files = dir('*.edf');
file_names = {files.name};
for i = 1:80  
    raw_name = file_names{i};
    EEG = pop_biosig([raw_path,raw_name], 'dataformat', 'auto', 'memmapfile', '');
    setname = [num2str(i),'.set'];
    EEG = pop_saveset( EEG, 'filename',setname,'filepath','/Users/.....');
end

for i = 1:80
    EEG = pop_biosig('/Users/....');
    EEG = pop_saveset( EEG, 'filename','1.set','filepath','/Users/....');
end 


%% 
%% channel locations 
for i = 1:80
    setname = [num2str(i),'.set'];
    EEG = pop_loadset('filename',setname,'filepath','/Users/....');
    EEG=pop_chanedit(EEG, 'lookup','/Users/corawoo/Desktop/EEGs/pre_test/128Mon.elp');
    EEG = pop_saveset( EEG, 'filename',setname,'filepath','/Users/....');
end

%% Removal of redundant electrodes, filtering, downsampling, segmentation
for i = 1:80
    setname = [num2str(i),'.set'];
    EEG = pop_loadset('filename',setname,'filepath','/Users/....');
    %EEG.history
    EEG = pop_select( EEG, 'rmchannel',{'....'});
    EEG = pop_eegfiltnew(EEG, [], 0.1, 33000, true, [], 1);
    EEG = pop_eegfiltnew(EEG, [], 40, 330, 0, [], 0);
    EEG = pop_eegfiltnew(EEG, 48, 52, 1650, 1, [], 1);
    EEG = pop_resample( EEG, 500);
    EEG = pop_saveset( EEG, 'filename',setname,'filepath','/Users/....');
end

for i = 1:80
    setname = [num2str(i),'.set'];
    EEG = pop_loadset('filename',setname,'filepath','/Users/...');
    EEG = pop_importevent( EEG, 'event','/Users/corawoo/Desktop/EEGs/pre_test/event.txt','fields',{'latency','type'},'skipline',1,'timeunit',1);
    pop_eegplot( EEG, 1, 1, 1);
    EEG = pop_epoch( EEG, {  '1'  }, [-0.2  0.8], 'newname', 'EDF file resampled epochs', 'epochinfo', 'yes');
    EEG = pop_rmbase( EEG, [-200     0]);
    EEG = pop_saveset( EEG, 'filename',setname,'filepath','/Users/....');
end

%% Manually perform bad segment deletion and bad electrode interpolation

for i = 1:80
    setname = [num2str(i),'.set'];
    EEG = pop_loadset('filename',setname,'filepath','/Users/.....');
    EEG = pop_interp(EEG, [.....], 'spherical');
    EEG = pop_saveset( EEG, 'filename',setname,'filepath','/Users/....');
end
%% references RunICA

for i = 1:80
    setname = [num2str(i),'.set'];
    EEG = pop_loadset('filename',setname,'filepath','/Users/....');
    EEG = pop_runica(EEG, 'extended',1,'pca', 128 ,'interupt','on');
    EEG = pop_saveset( EEG, 'filename',setname,'filepath','/Users/corawoo/Desktop/EEGs/pre_test/20250812/step/step9_runICA');
end

%% Artifact removal

%% Removal of artifacts from extreme values
for i = 1:80
    setname = [num2str(i),'.set'];
    EEG = pop_loadset('filename',setname,'filepath','\');
    %EEG.history
    EEG = pop_eegthresh(EEG,1,[1:62] ,-80,80,-1,1.998,0,1);
for i = 1:80
    setname = [num2str(i),'.set'];
    EEG = pop_loadset('filename',setname,'filepath','/Users/...');
    EEG = pop_reref( EEG, [23 24] );
    EEG = pop_saveset( EEG, 'filename',setname,'filepath','/Users/...');
end
%% Manual browsing is employed for data inspection.
for i = 1:80
    setname = [num2str(i),'.set'];
    EEG = pop_loadset('filename',setname,'filepath','/Users/...');
    EEG = pop_reref( EEG, [23 24] );
    EEG = pop_saveset( EEG, 'filename',setname,'filepath','/Users/....');
end