
%% Subject info
sub_time = [1512 1188 1972 1432 1516 1980]; 
sub = ["000001" "000002" "203995" "204502" "207643" "207904"];
prefix = "/Users/lcraaaa/Documents/Files/term_2021/Thesis/Data_backup/EEG/";



%% Loop 
for i = 1:length(sub)
    % continous EEG file
    subject = sub(i);
    sub_file_path = strcat(subject+"/"+subject+".bdf");
    file_path = convertStringsToChars(strcat(prefix, sub_file_path)); 
    
    % ERP file
    ERP_file_name = convertStringsToChars(strcat(subject, '_SRT_ERP'));
    ERP_file_name_ext = convertStringsToChars(strcat(subject, '_SRT_ERP.erp'));

    %% Analysis

    % Subset
    EEG = pop_biosig(file_path);
    EEG = eeg_checkset( EEG );
    EEG = pop_select( EEG, 'notime',[0 sub_time(i)]);

    % Channel locations
    EEG = eeg_checkset( EEG );
    EEG = pop_chanedit(EEG, 'lookup','/Users/lcraaaa/Documents/MATLAB/tools/eeglab2021.1/plugins/dipfit/standard_BEM/elec/standard_1005.elc');
    EEG = eeg_checkset( EEG );
    
    % Band filter 
    EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',30,'plotfreqz',0);
    EEG = eeg_checkset( EEG );

    % Exclude electrode
    EEG = pop_select( EEG, 'nochannel',{'SO1','LO1','IO1','LO2','EXG7','EXG8'});
    EEG = eeg_checkset( EEG );

    % Re-reference
    EEG = pop_reref( EEG, [65 66] );
    EEG = eeg_checkset( EEG );
    
    % exclude electrode that are outliers
    EEG = pop_select( EEG, 'nochannel',{'FT8', 'T8', 'F7', 'FT7', 'P6', 'P10', 'PO4', 'P9'});

    
    % Continouse EEG artifect rejection 
    EEG = pop_continuousartdet( EEG , 'ampth',200, 'chanArray',1:56, 'colorseg', [ 1 0.9765 0.5294], 'firstdet', 'on', 'forder',100, 'numChanThreshold',1, 'stepms',250, 'threshType', 'peak-to-peak', 'winms',500 );% Script: 10-Apr-2022 17:37:34

    % Eventlist
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } );
    EEG = eeg_checkset( EEG );

    % Binlister and Extract epoch
    EEG  = pop_binlister( EEG , 'BDF', '/Users/lcraaaa/Documents/Files/term_2021/Thesis/data_analysis/SRT/bin_3_lister.txt', 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' );
    EEG = eeg_checkset( EEG );
    EEG = pop_epochbin( EEG , [-500.0  4498.0],  'pre');
    EEG = eeg_checkset( EEG );

    % save file 
    prefix_save = '/Users/lcraaaa/Documents/Files/term_2021/Thesis/data_analysis/SRT/C3/';
    EEG_file_path = strcat(prefix_save, subject, "_SRT_C3.set");
    EEG_file_path = convertStringsToChars(EEG_file_path); 
    EEG = pop_newset(ALLEEG, EEG, 1,'savenew',EEG_file_path,'gui','off'); 

end

