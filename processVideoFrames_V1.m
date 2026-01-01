
function SD_processVideoFrames_V1(activity, all_time_stamps, all_time_series, xdfNames)
    % Initialize an empty array of structs
    dataStruct = struct('activityID', {}, 'subjectID', {}, 'trialID', {}, 'timeSeriesData', {}, 'timeStampsData', {});
    
    % Get the total number of activities and subjects
    numActivities = size(xdfNames, 2);
    numSubjects = size(xdfNames, 1);
    
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
                dataStruct(structIdx).activityID = activityIdx; 
                dataStruct(structIdx).subjectID = subjectIdx;   
                dataStruct(structIdx).trialID = trialID;
                dataStruct(structIdx).timeSeriesData = timeSeriesData;
                dataStruct(structIdx).timeStampsData = timeStampsData;
                
                % Increment the struct index
                structIdx = structIdx + 1;
            end
        end
    end

    assignin('base', 'beforechange_VideoFrames', dataStruct);
    assignin('base', 'time_stamps', all_time_stamps);
    assignin('base', 'time_series', all_time_series);

    % Initialize an empty struct array with the desired field names
    tempStruct = struct('trialID', [], 'Subject', [], 'Fatigue', [], 'Activity', [], 'Stimulation', [], 'Trial', [], 'FrameNumber', [], 'Time_Seconds', [], 'timeStampsData', []);
    
    % Loop through each row in dataStruct
    for i = 1:length(dataStruct)
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
        
        % Safely assign timeSeriesData parts
        timeSeriesData = dataStructTemp.timeSeriesData;
        if isempty(timeSeriesData)
            tempStruct(i).FrameNumber = [];
            tempStruct(i).Time_Seconds = [];
        else
            tempStruct(i).FrameNumber = timeSeriesData(1, :);
            tempStruct(i).Time_Seconds = timeSeriesData(2, :);
        end

        % Assign timeStampsData
        tempStruct(i).timeStampsData = dataStructTemp.timeStampsData;
    end

    % Replace the original dataStruct with the reordered tempStruct
    dataStruct = tempStruct;

    % Initialize the new struct
    mod_dataStruct = struct();
    
    % Loop through each entry in dataStruct to populate mod_dataStruct
    for i = 1:length(dataStruct)
        % Copy relevant fields
        mod_dataStruct(i).trialID = dataStruct(i).trialID;
        mod_dataStruct(i).Subject = dataStruct(i).Subject;
        mod_dataStruct(i).Fatigue = dataStruct(i).Fatigue;
        mod_dataStruct(i).Activity = dataStruct(i).Activity;
        mod_dataStruct(i).Stimulation = dataStruct(i).Stimulation;
        mod_dataStruct(i).Trial = dataStruct(i).Trial;

        % Safely handle missing or empty FrameNumber
        frameNumbers = dataStruct(i).FrameNumber;
        if isempty(frameNumbers)
            mod_dataStruct(i).Start_frame = NaN;
            mod_dataStruct(i).End_frame = NaN;
        else
            mod_dataStruct(i).Start_frame = frameNumbers(1);
            mod_dataStruct(i).End_frame = frameNumbers(end);
        end
    end

    assignin('base', 'afterchange_VideoFrames', mod_dataStruct);

    if numActivities > 1
        activityName = 'AllAct';
    else
        activityName = activity;
    end

    filename_csv = [activityName '_VideoFrames.csv']; 
    filename_mat = [activityName '_VideoFrames.mat']; 

    writeToExcel(mod_dataStruct, fullfile('...\Output Data\CSV', filename_csv));
    disp('csv saved')
    save(fullfile('...\Output Data\MAT', filename_mat), 'mod_dataStruct');
    disp('mat saved')
end

function writeToExcel(mod_dataStruct, filename)
    % Check if the filename has a .csv extension
    [~, ~, ext] = fileparts(filename);
    if ~strcmpi(ext, '.csv')
        error('Filename must have a .csv extension.');
    end

    % Convert struct to table
    dataTable = struct2table(mod_dataStruct);

    % Write to CSV file
    writetable(dataTable, filename);

    disp(['Data written to ', filename]);
end




