function processEyeTracking_V1(subjectStart, subjectEnd, activity, Channel)
    
    xdfNames_ET = generatexdfNames_ET(subjectStart, subjectEnd, activity);

    % Initialize dataStruct index
    dataIndex = 1;

    % Loop through the rows and columns of xdfNames_ET
    for i = 1:size(xdfNames_ET, 1)
        for j = 1:size(xdfNames_ET, 2)
            % Get the cell containing the trialIDs for the current subject and activity
            nameCell = xdfNames_ET{i, j};

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
                
                % Extract the subject to load the corresponding .xlsx file
                subjectID = parts{1};
                xlsxFileName = strcat(subjectID, '_ET_allAct.xlsx');
                
                % Check if the .xlsx file exists
                if ~exist(fullfile('...\Input Data\EyeTracking_Extracted_EXCELs', xlsxFileName), 'file')
                    warning(['File ' xlsxFileName ' does not exist. Skipping this subject.']);
                    continue;
                end
                
                % Read the .xlsx file into a table and print column names
                try
                    dataTable = readtable(fullfile('...\Input Data\EyeTracking_Extracted_EXCELs', xlsxFileName), 'VariableNamingRule', 'preserve');
                    % Print column names
                    disp('Column names:');
                    disp(dataTable.Properties.VariableNames);
                    
                    % Assign the table to the workspace
                    assignin('base', 'dataTable', dataTable);
                catch ME
                    warning('Failed to read file %s. Error: %s', xlsxFileName, ME.message);
                    continue;
                end
                
                % Check for the required columns
                if ~ismember('Recording name', dataTable.Properties.VariableNames) || ...
                   ~ismember('Recording timestamp', dataTable.Properties.VariableNames) || ...
                   ~ismember(Channel, dataTable.Properties.VariableNames)
                    warning(['Required columns missing in ' xlsxFileName '. Skipping this file.']);
                    continue;
                end
                
                % Search for the trialID and its variations in the 'Recording name' column
                recordingNames = strtrim(dataTable.('Recording name')); % Trim spaces
                found = false;
                
                disp(['Processing trialID: ' char(trialID)]);
                
                % Check for the exact trialID first
                idx = strcmp(recordingNames, trialID);
                if any(idx)
                    % Extract the data for the current trialID
                    trialData = dataTable(idx, :);
                    timeSeriesData = trialData.(Channel);
                    timeStampsData = trialData.('Recording timestamp');
                    
                    % Store the information in dataStruct
                    dataStruct(dataIndex).trialID = trialID;
                    dataStruct(dataIndex).Subject = parts{1};
                    dataStruct(dataIndex).Fatigue = parts{2};
                    dataStruct(dataIndex).Activity = parts{3};
                    dataStruct(dataIndex).Stimulation = parts{4};
                    dataStruct(dataIndex).Trial = parts{5};
                    dataStruct(dataIndex).timeSeriesData = timeSeriesData;
                    dataStruct(dataIndex).timeStampsData = timeStampsData;
                    
                    % Increment the dataStruct index
                    dataIndex = dataIndex + 1;
                    
                    found = true;
                else
                    % If exact trialID not found, check for variations with numerical suffixes
                    for version = 1:5
                        searchTrialID = strcat(trialID, num2str(version));
                        disp(['Checking trialID: ' char(searchTrialID)]);
                        
                        % Use strcmp for exact match
                        idx = strcmp(recordingNames, searchTrialID);
                        
                        % Print out the first few matches for debugging
                        if any(idx)
                            disp('Found matching trialIDs:');
%                             disp(recordingNames(idx));
                        end
                        
                        if any(idx)
                            % Extract the data for the current trialID
                            trialData = dataTable(idx, :);
                            timeSeriesData = trialData.(Channel);
                            timeStampsData = trialData.('Recording timestamp');
                            
                            % Store the information in dataStruct
                            dataStruct(dataIndex).trialID = trialID;
                            dataStruct(dataIndex).Subject = parts{1};
                            dataStruct(dataIndex).Fatigue = parts{2};
                            dataStruct(dataIndex).Activity = parts{3};
                            dataStruct(dataIndex).Stimulation = parts{4};
                            dataStruct(dataIndex).Trial = parts{5};
                            dataStruct(dataIndex).timeSeriesData = timeSeriesData;
                            dataStruct(dataIndex).timeStampsData = timeStampsData;
                            
                            % Increment the dataStruct index
                            dataIndex = dataIndex + 1;
                            
                            found = true;
                            break;
                        end
                    end
                end
                
                if ~found
                    warning(['TrialID ' char(trialID) ' or its variations not found in ' xlsxFileName '. Skipping this trial.']);
                end
            end
        end
    end

    % Loop over each element in the struct
    for i = 1:length(dataStruct)
        % Convert timeSeriesData to a row vector if it's not already
        if size(dataStruct(i).timeSeriesData, 1) > 1
            dataStruct(i).timeSeriesData = dataStruct(i).timeSeriesData';
        end
        
        % Transpose the timeStampsData field to match the size of timeSeriesData
        if size(dataStruct(i).timeStampsData, 2) == 1
            dataStruct(i).timeStampsData = dataStruct(i).timeStampsData';
        end
    end

    % Assign the result to the workspace
    assignin('base', 'dataStruct_ET', dataStruct);

%     filename_csv = [activity '_ET_' Channel '.csv']; 
    filename_mat = [activity '_ET_' Channel '.mat']; 
%     writeToExcel(dataStruct, fullfile('...\NASA Data Extraction\Output Data\CSV', filename_csv));
    save(fullfile('...\Output Data\MAT', filename_mat), 'dataStruct');
    disp('mat saved')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function to generate subject list based on start and end
function xdfNames_ET = generatexdfNames_ET(subjectStart, subjectEnd, activity)

    activity_list = {'TWEO','TWDT'};
%     activity_list = {'TWEO','TWDT','FPECWF'};
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
            xdfNames_ET{a,s} = xdfLables;                                
        end
    end

   xdfNames_ET = xdfNames_ET';
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
        [subject, '-po-', activity, '-NG-T1.xdf'], 
%         [subject, '-po-', activity, '-NG-T2.xdf'], 
%         [subject, '-pr-', activity, '-G-T1.xdf'], 
%         [subject, '-pr-', activity, '-G-T2.xdf'], 
%         [subject, '-po-', activity, '-NG-T1.xdf'], 
%         [subject, '-po-', activity, '-NG-T2.xdf'], 
%         [subject, '-po-', activity, '-G-T1.xdf'], 
%         [subject, '-po-', activity, '-G-T2.xdf']
    };
end

function writeToExcel(dataStruct, filename)
    % Remove fields trialID and timeStampsData
    dataStruct = rmfield(dataStruct, {'trialID', 'timeStampsData'});
    
    % Replace each timeSeriesData with its RMS value
    for i = 1:length(dataStruct)
        timeSeriesData = dataStruct(i).timeSeriesData;
        assignin('base', 'timeSeriesDatainexce', timeSeriesData);
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