function processEulerDatagram1_V1(activity, additionalSegment,all_time_stamps, all_time_series, xdfNames)
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

    assignin('base', 'afterchange_Euler', dataStruct);
    assignin('base', 'time_stamps', all_time_stamps);
    assignin('base', 'time_series', all_time_series);

         % Initialize an empty struct array with the desired field names
    % Initialize an empty struct array with the desired field names
    tempStruct = struct('trialID', [], 'Subject', [], 'Fatigue', [], 'Activity', [], 'Stimulation', [], 'Trial', [], 'Rotation_X', [], 'Rotation_Y', [], 'Rotation_Z', [], 'Roll_Rate_X', [], 'Pitch_Rate_Y', [], 'Yaw_Rate_Z', [], 'timeStampsData', []);
    
    % Number of segments
    numSegments = 23;
    rowsPerSegment = 6; % Euler angles and angular velocities
    
    % Define segment mapping
    segmentMap = containers.Map({'Pelvis', 'L5', 'L3', 'T12', 'T8', 'Neck', 'Head', ...
                                     'Right Shoulder', 'Right Upper Arm', 'Right Forearm', 'Right Hand', ...
                                     'Left Shoulder', 'Left Upper Arm', 'Left Forearm', 'Left Hand', ...
                                     'Right Upper Leg', 'Right Lower Leg', 'Right Foot', 'Right Toe', ...
                                     'Left Upper Leg', 'Left Lower Leg', 'Left Foot', 'Left Toe'}, ...
                                    1:23);
    
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
        
        % Extract timeSeriesData
        timeSeriesData = dataStructTemp.timeSeriesData;
    
        % Extract the segment from additionalSegment
        segmentIndex = segmentMap(additionalSegment); % Get the segment index from the map
        
        % Calculate the rows for the selected segment
        startRow = (segmentIndex - 1) * rowsPerSegment + 1;
        endRow = startRow + rowsPerSegment - 1;
        
        % Extract Euler angles and rates for the selected segment
        eulerAngles = timeSeriesData(startRow:endRow, :);
        
        % Assign to the new columns
        tempStruct(i).Rotation_X = eulerAngles(1, :);
        tempStruct(i).Rotation_Y = eulerAngles(2, :);
        tempStruct(i).Rotation_Z = eulerAngles(3, :);
        tempStruct(i).Roll_Rate_X = eulerAngles(4, :);
        tempStruct(i).Pitch_Rate_Y = eulerAngles(5, :);
        tempStruct(i).Yaw_Rate_Z = eulerAngles(6, :);
        
        % Assign timeStampsData
        tempStruct(i).timeStampsData = dataStructTemp.timeStampsData;
    end
    
    % Replace the original dataStruct with the reordered tempStruct
    dataStruct = tempStruct;

    assignin('base', 'afterchange_Euler', dataStruct);

    if numActivities>1
        activity = 'AllAct';
    else
        activity = activity;
    end

%    filename_csv = [activity '_Xsens_' additionalSegment '.csv'];
   filename_mat = [activity '_Xsens_EulerXYZ_' additionalSegment '.mat'];
%    writeToExcel(dataStruct, fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\CSV', filename_csv));
   save(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction_CF\Output Data\MAT', filename_mat), 'dataStruct');
    disp('mat saved')
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
