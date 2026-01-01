function processCenterOfMass1_V1(activity, all_time_stamps, all_time_series, xdfNames)
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

    assignin('base', 'beforechange_COM', dataStruct);
    assignin('base', 'time_stamps', all_time_stamps);
    assignin('base', 'time_series', all_time_series);

        % Initialize an empty struct array with the desired field names
    tempStruct = struct('trialID', [], 'Subject', [], 'Fatigue', [], 'Activity', [], 'Stimulation', [], 'Trial', [], 'COM_X', [], 'COM_Y', [], 'COM_Z', [], 'timeStampsData', []);
    
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
        
        % Replace timeSeriesData with COM_X, COM_Y, and COM_Z
        timeSeriesData = dataStructTemp.timeSeriesData;
        tempStruct(i).COM_X = timeSeriesData(1, :);
        tempStruct(i).COM_Y = timeSeriesData(2, :);
        tempStruct(i).COM_Z = timeSeriesData(3, :);
        
        % Assign timeStampsData
        tempStruct(i).timeStampsData = dataStructTemp.timeStampsData;
    end
    
    % Replace the original dataStruct with the reordered tempStruct
    dataStruct = tempStruct;

    assignin('base', 'afterchange_COM', dataStruct);

    if numActivities>1
        activity = 'AllAct';
    else
        activity = activity;
    end

    filename_csv = [activity '_COM.csv']; 
    filename_mat = [activity '_COM.mat']; 
    writeToExcel(dataStruct, fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\CSV', filename_csv));
    disp('csv saved')
    save(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\MAT', filename_mat), 'dataStruct');
    disp('mat saved')
end


function writeToExcel(dataStruct, filename)
    % Remove fields trialID and timeStampsData
    dataStruct = rmfield(dataStruct, {'trialID', 'timeStampsData'});
    
    % Replace COM_X, COM_Y, and COM_Z fields with their RMS values
    for i = 1:length(dataStruct)
        % Compute RMS for each COM component
        rms_COM_X = rms(dataStruct(i).COM_X);
        rms_COM_Y = rms(dataStruct(i).COM_Y);
        rms_COM_Z = rms(dataStruct(i).COM_Z);
        
        % Replace the COM fields with the RMS values
        dataStruct(i).COM_X = rms_COM_X;
        dataStruct(i).COM_Y = rms_COM_Y;
        dataStruct(i).COM_Z = rms_COM_Z;
    end
    
    % Convert the struct to a table for easier export
    dataTable = struct2table(dataStruct);
    
    % Write the table to a CSV file
    writetable(dataTable, filename);
end
