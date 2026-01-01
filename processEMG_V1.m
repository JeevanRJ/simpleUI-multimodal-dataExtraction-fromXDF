% Function to process EMG data
function processEMG_V1(activity, Channel,all_time_stamps, all_time_series, xdfNames)
% Initialize an empty array of structs
    dataStruct = struct('activityID', {}, 'subjectID', {}, 'trialID', {}, 'timeSeriesData', {}, 'timeStampsData', {});
    
    % Get the total number of activities and subjects
    numActivities = size(xdfNames, 2);
    numSubjects = size(xdfNames, 1);

    assignin('base', 'numActivities', numActivities);
    
    % Counter to keep track of struct index
    structIdx = 1;
    
    % Loop through each activity
    for activityIdx = 1:numActivities
        % Loop through each subject
        for subjectIdx = 1:numSubjects
            % Get the trial names for the current subject and activity
            trialNamesCell = xdfNames{subjectIdx, activityIdx};  
            
            % Loop through each trial
            for trialIdx = 1:length(trialNamesCell)
                % Access the trial name (ID)
                trialID = trialNamesCell{trialIdx};
                
                % Access the corresponding data
                % Ensure correct indexing by verifying the structure
                timeSeriesData = all_time_series{activityIdx}{subjectIdx, trialIdx};
                timeStampsData = all_time_stamps{activityIdx}{subjectIdx, trialIdx};
                
                % Store the data in the struct
                dataStruct(structIdx).activityID = activityIdx; % You may want to use a more descriptive name instead of index
                dataStruct(structIdx).subjectID = subjectIdx;   % You may want to use a more descriptive name instead of index
                dataStruct(structIdx).trialID = trialID;
                dataStruct(structIdx).timeSeriesData = timeSeriesData;
                dataStruct(structIdx).timeStampsData = timeStampsData;
                
                % Increment the struct index
                structIdx = structIdx + 1;
            end
        end
    end

    assignin('base', 'beforechange', dataStruct);
    assignin('base', 'time_stamps', all_time_stamps);
    assignin('base', 'time_series', all_time_series);

    % Define the channel-to-row mapping
    channelMap = containers.Map({'LES', 'RES', 'LVL', 'RVL', 'LGM', 'RGM', 'LTA', 'RTA'}, 1:8);
    
    % Initialize an empty struct array with the desired field names
    numEntries = length(dataStruct); % Determine the number of entries in dataStruct
    tempStruct = struct('trialID', [], 'Subject', [], 'Fatigue', [], 'Activity', [], 'Stimulation', [], 'Trial', [], 'timeSeriesData', [], 'timeStampsData', []);
    
    % Loop through each entry in dataStruct
    for i = 1:numEntries
        % Remove the activityID and subjectID columns
        dataStructTemp = rmfield(dataStruct(i), {'activityID', 'subjectID'});
        
        % Separate the trialID into Subject, Fatigue, Activity, Stimulation, Trial
        trialID = dataStructTemp.trialID;
        parts = strsplit(trialID, '-');
        
        % Extract and assign the separated parts
        tempStruct(i).trialID = trialID;
        tempStruct(i).Subject = parts{1};
        tempStruct(i).Fatigue = parts{2};
        tempStruct(i).Activity = parts{3};
        tempStruct(i).Stimulation = parts{4};
        tempStruct(i).Trial = parts{5};
        
        % Extract timeSeriesData
        timeSeriesData = dataStructTemp.timeSeriesData;
        
        % Determine the row based on the channel
        if isKey(channelMap, Channel)
            rowIndex = channelMap(Channel);
        else
            error('Invalid Channel: %s', Channel);
        end
        
        % Replace timeSeriesData with the selected row
        tempStruct(i).timeSeriesData = timeSeriesData(rowIndex, :);
        
        % Assign timeStampsData
        tempStruct(i).timeStampsData = dataStructTemp.timeStampsData;
    end
    
    % Replace the original dataStruct with the reordered tempStruct
    dataStruct = tempStruct;

    if numActivities>1
        activity = 'AllAct';
    else
        activity = activity;
    end

    dataStruct = cleanEMGData(dataStruct);
     
    assignin('base', 'afterchange_EMG', dataStruct);

    filename_csv = [activity '_EMG_' Channel '.csv']; 
    filename_mat = [activity '_EMG_' Channel '.mat'];
    writeToExcel(dataStruct, fullfile('...\Output Data\CSV', filename_csv));
    disp('csv saved')
    save(fullfile('...\Output Data\MAT', filename_mat), 'dataStruct');
    disp('mat saved')
end


function cleanedDataStruct = cleanEMGData(dataStruct)
    % Define sampling frequency and filter parameters
    fs = 1842; % Sampling frequency
    low_cutoff = 20; % Low cutoff frequency for band-pass filter in Hz
    high_cutoff = 450; % High cutoff frequency for band-pass filter in Hz
    envelope_cutoff = 10; % Cutoff frequency for envelope detection in Hz
    
    % Initialize output struct
    cleanedDataStruct = dataStruct;
    
    % Loop through each element of dataStruct
    for i = 1:numel(dataStruct)
        % Access the EMG signal
        emg_signal = dataStruct(i).timeSeriesData;
        
        % Convert signal to double
        emg_signal = double(emg_signal);
        
        % Initialize cleaned data container
        cleaned_emg = nan(size(emg_signal));
        
        % Process each EMG signal in the row
        for j = 1:size(emg_signal, 1)
            % Extract individual EMG signal
            signal = emg_signal(j, :);
            
            % Step 1: Remove mean (DC offset)
            signal = signal - mean(signal);
            
            % Step 2: Band-pass filter
            [b, a] = butter(4, [low_cutoff high_cutoff] / (fs / 2), 'bandpass');
            filtered_emg = filtfilt(b, a, signal);
            
            % Step 3: Rectify the signal
            rectified_emg = abs(filtered_emg);
            
            % Step 4: Envelope detection
            [b_env, a_env] = butter(4, envelope_cutoff / (fs / 2), 'low');
            emg_envelope = filtfilt(b_env, a_env, rectified_emg);
            
            % Store cleaned EMG signal
            cleaned_emg(j, :) = emg_envelope;
        end
        
        % Update the timeSeriesData field with cleaned data
        cleanedDataStruct(i).timeSeriesData = cleaned_emg;
    end
end



function writeToExcel(dataStruct, filename)
    % Remove fields trialID and timeStampsData
    dataStruct = rmfield(dataStruct, {'trialID', 'timeStampsData'});
    
    % Replace each timeSeriesData with its RMS value
    for i = 1:length(dataStruct)
        timeSeriesData = dataStruct(i).timeSeriesData;
        % Compute RMS value for the time series
        rmsValue = rms(timeSeriesData);
        % Replace the timeSeriesData field with the RMS value
        dataStruct(i).timeSeriesData = rmsValue;
    end
    
    % Convert the struct to a table for easier export
    dataTable = struct2table(dataStruct);
    
    % Write the table to a CSV file
    writetable(dataTable, filename);
end
