% Function to process EMG data
function processHeartRate_V1(subjectStart, subjectEnd, activity, Channel,Matrix)

    xdfNames_HR = generatexdfNames_HR(subjectStart, subjectEnd, activity);
    assignin('base', 'xdfNames_HR', xdfNames_HR);
    assignin('base', 'Channel', Channel);

% Initialize dataStruct index
dataIndex = 1;

% Loop through the rows and columns of xdfNames_HR
for i = 1:size(xdfNames_HR, 1)
    for j = 1:size(xdfNames_HR, 2)
        % Get the cell containing the trialIDs for the current subject and activity
        nameCell = xdfNames_HR{i, j};
        
        % Loop through each trialID in the current cell
        for k = 1:length(nameCell)
            % Extract the trialID from the list
            trialID = nameCell{k};
            
            % Ensure trialID is a string
            trialID = string(trialID); % Convert to string if it's a char
            
            % Parse the trialID into Subject, Fatigue, Activity, Stimulation, Trial
            parts = strsplit(trialID, '-');
            if numel(parts) ~= 5
                warning(['Invalid trialID format: ' char(trialID)]);
                continue; % Skip to the next trial if format is invalid
            end
            
            % Extract the subject to load the corresponding .mat file
            subjectID = parts{1};
            matFileName = strcat(subjectID, '_HR_allAct.mat');
            
            % Check if the .mat file exists
            if ~exist(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Input Data\Actiheart_Extracted_MATs', matFileName), 'file')
                warning(['File ' matFileName ' does not exist. Skipping this subject.']);
                continue;
            end
            
            % Load the .mat file containing the heart rate data
            matData = load(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Input Data\Actiheart_Extracted_MATs', matFileName));
            structName = strcat(subjectID, '_HR_allAct');
            
            % Check if the expected struct exists in the .mat data
            if ~isfield(matData, structName)
                warning(['Struct ' structName ' not found in ' matFileName '. Skipping this subject.']);
                continue;
            end
            
            % Get the heart rate struct
            heartRateStruct = matData.(structName);
            
            % Modify the trialID to match the field name format (replace '-' with '_')
            fieldID = strrep(trialID, '-', '_');
            
            % Check if the field exists in the heartRateStruct
            if ~isfield(heartRateStruct, fieldID)
                warning(['Field for trialID ' char(trialID) ' not found in ' matFileName '. Skipping this trial.']);
                continue;
            end
            
            % Extract the data for the current trialID
            trialData = heartRateStruct.(fieldID);
            
            % Store the information in dataStruct
            dataStruct(dataIndex).trialID = trialID;
            dataStruct(dataIndex).Subject = parts{1};
            dataStruct(dataIndex).Fatigue = parts{2};
            dataStruct(dataIndex).Activity = parts{3};
            dataStruct(dataIndex).Stimulation = parts{4};
            dataStruct(dataIndex).Trial = parts{5};
            dataStruct(dataIndex).timeSeriesData = trialData.extractedECG;
            dataStruct(dataIndex).timeStampsData = trialData.extractedEpochTimes;
            
            % Increment the dataStruct index
            dataIndex = dataIndex + 1;
        end
    end
end

% Assign the result to the workspace
% assignin('base', 'dataStruct_HR', dataStruct);

% following lines are for sorting, can be removed if not need upto line 138

% Ensure xdfNames_HR is a cell array
if ~iscell(xdfNames_HR)
    error('xdfNames_HR must be a cell array.');
end

% Initialize an empty cell array to collect unique activities
allActivities = {};

% Loop through each cell in xdfNames_HR to extract trialIDs
for i = 1:size(xdfNames_HR, 1)
    for j = 1:size(xdfNames_HR, 2)
        cellData = xdfNames_HR{i, j};
        if ~iscell(cellData)
            error('Each element of xdfNames_HR should be a cell array.');
        end
        
        % Extract activities from trialIDs in the current cell
        for k = 1:length(cellData)
            trialID = cellData{k};
            parts = strsplit(trialID, '-');
            if numel(parts) >= 3
                activity = parts{3};  % Extract the activity part
                if ~ismember(activity, allActivities)
                    allActivities{end+1} = activity;  % Append unique activity
                end
            end
        end
    end
end

% Create a map to order activities
activityOrder = containers.Map(allActivities, 1:length(allActivities));

% Extract activities from dataStruct
activityList = {dataStruct.Activity};

% Convert activityList to string to match map key type
activityList = string(activityList);

% Map activities to their order based on xdfNames_HR
activityOrderIdx = arrayfun(@(x) activityOrder(char(x)), activityList, 'UniformOutput', false);

% Convert cell array to numeric array for sorting
activityOrderIdx = cell2mat(activityOrderIdx);

% Sort dataStruct by activity order
[~, sortIdx] = sort(activityOrderIdx);
dataStruct = dataStruct(sortIdx);

% Example function logic based on Matrix value
switch Matrix
    case 'timeSeries'
        disp('saving timeSeries')
    case 'Mean'
        dataStruct = CalMeanHR(dataStruct);
    case 'Heart Rate Variability - SDNN'
        dataStruct = CalVHR_SDNN(dataStruct);
    case 'Heart Rate Variability - RMSSD'
        dataStruct = CalVHR_RMSSD(dataStruct);
    otherwise
        error('Unknown Matrix type.');
end



% Loop through each element in the struct
for i = 1:length(dataStruct)
    % Transpose the timeSeriesData and timeStampsData fields
    dataStruct(i).timeSeriesData = dataStruct(i).timeSeriesData';
    dataStruct(i).timeStampsData = dataStruct(i).timeStampsData';
end
% Assign the sorted structure back to the workspace
assignin('base', 'dataStruct_HR', dataStruct);

    % Write the processed data to CSV
   filename_csv = ['AllAct_HR_' Matrix '.csv'];  % Use Matrix name in filename if 'All'
   filename_mat = ['AllAct_HR_' Matrix '.mat'];
   writeToExcel(dataStruct, fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\CSV', filename_csv));
   disp('csv saved')
   save(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\MAT', filename_mat), 'dataStruct');
   disp('mat saved')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function to generate subject list based on start and end
function xdfNames_HR = generatexdfNames_HR(subjectStart, subjectEnd, activity)

    activity_list = {'TWEO', 'TWEC', 'TWDT', 'OW', 'HOW', 'FPEONF', 'FPECNF', 'FPEOWF','FPECWF','FNC','PP'};
    Act_listLength = length(activity_list);

    % update num_activities based on user selection
    if strcmp(activity, 'All_Activities')
        num_activities = Act_listLength;
    else
        num_activities = 1;
    end

    

    subjects = generateSubjectList(subjectStart, subjectEnd);

    for a = 1:num_activities
      disp ('run = x')
      if num_activities == 1
           activity = activity; % Keep the current activity
      else      
           activity = activity_list{1, a}; % Assign from the list based on index 'a'
      end

        for s = 1:length(subjects)
            subject = subjects{s};
                
            % Generate filenames based on subject and activity
            xdfLables = generateXdfLables(subject, activity);
            xdfNames_HR{a,s} = xdfLables;                                
        end
    end

   xdfNames_HR = xdfNames_HR';
end


% Function to generate subject list based on start and end
function subjects = generateSubjectList(subjectStart, subjectEnd)
    startIdx = str2double(subjectStart(2:end));
    endIdx = str2double(subjectEnd(2:end));
    subjects = arrayfun(@(x) ['S', num2str(x)], startIdx:endIdx, 'UniformOutput', false);
end

% Function to generate XDF filenames based on subject and activity
function xdfLables = generateXdfLables(subject, activity)
    % This is just an example; modify according to your filename format
    xdfLables = {
        [subject, '-pr-', activity, '-NG-T1'], 
        [subject, '-pr-', activity, '-NG-T2'], 
        [subject, '-pr-', activity, '-G-T1'], 
        [subject, '-pr-', activity, '-G-T2'], 
        [subject, '-po-', activity, '-NG-T1'], 
        [subject, '-po-', activity, '-NG-T2'], 
        [subject, '-po-', activity, '-G-T1'], 
        [subject, '-po-', activity, '-G-T2']
    };
end


function writeToExcel(dataStruct, filename)
    % Remove fields trialID and timeStampsData
    dataStruct = rmfield(dataStruct, {'trialID', 'timeStampsData'});
    
    % Convert the struct to a table for easier export
    dataTable = struct2table(dataStruct);
    
    % Write the table to a CSV file
    writetable(dataTable, filename);
end

function dataStruct = CalMeanHR(dataStruct)  
    % Replace each timeSeriesData with its mean value
    for i = 1:length(dataStruct)
        timeSeriesData = dataStruct(i).timeSeriesData;
        % Compute mean value for the time series
        meanValue = mean(timeSeriesData, 'omitnan');
        % Replace the timeSeriesData field with the mean value
        dataStruct(i).timeSeriesData = meanValue;
    end
end

function dataStruct = CalVHR_SDNN(dataStruct)    
    % Replace each timeSeriesData with its HRV SDNN value
    for i = 1:length(dataStruct)
        timeSeriesData = dataStruct(i).timeSeriesData;
        % Compute HRV SDNN (standard deviation of normal-to-normal intervals)
        sdnnValue = std(timeSeriesData, 'omitnan');
        % Replace the timeSeriesData field with the HRV SDNN value
        dataStruct(i).timeSeriesData = sdnnValue;
    end
end

function dataStruct = CalVHR_RMSSD(dataStruct)
    % Replace each timeSeriesData with its HRV RMSSD value
    for i = 1:length(dataStruct)
        timeSeriesData = dataStruct(i).timeSeriesData;
        % Compute RMSSD (root mean square of successive differences)
        diffs = diff(timeSeriesData); % Find the successive differences
        rmssdValue = sqrt(mean(diffs.^2, 'omitnan')); % Compute RMSSD
        % Replace the timeSeriesData field with the HRV RMSSD value
        dataStruct(i).timeSeriesData = rmssdValue;
    end
end





