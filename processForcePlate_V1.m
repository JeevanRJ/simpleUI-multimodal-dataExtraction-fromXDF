function processForcePlate_V1(subjectStart, subjectEnd, activity, Channel, Matrix)

    xdfNames_FF = generatexdfNames_FF(subjectStart, subjectEnd, activity);
    assignin('base', 'xdfNames_FF', xdfNames_FF);
    assignin('base', 'Channel', Channel);

    % Define the channel-to-column mapping
    channelMap = containers.Map({'Fx', 'Fy', 'Fz', 'Mx', 'My', 'Mz'}, 1:6);

    % Initialize an empty struct array with the desired field names
    dataStruct = struct('trialID', [], 'Subject', [], 'Fatigue', [], 'Activity', [], 'Stimulation', [], 'Trial', [], 'timeSeriesData', [], 'timeStampsData', []);

    % Number of rows to keep
    numRowsToKeep = 30000;

    % Loop through each entry in xdfNames_FF
    dataIndex = 1;  % Index to keep track of the dataStruct position
    for i = 1:size(xdfNames_FF, 1)
        for j = 1:size(xdfNames_FF, 2)
            % Get the cell containing the names
            nameCell = xdfNames_FF{i, j};
            
            % Loop through each name in the current name column
            for k = 1:length(nameCell)
                % Extract the trialID from the list
                trialID = nameCell{k};
                
                % Ensure trialID is a string
                trialID = string(trialID); % Convert to string if it's a char
                
                % Parse the trialID into Subject, Fatigue, Activity, Stimulation, Trial
                parts = strsplit(trialID, '-');
                if numel(parts) ~= 5
                    error('Invalid trialID format: %s', trialID);
                end
                
                % Extract and assign the separated parts
                dataStruct(dataIndex).trialID = trialID;
                dataStruct(dataIndex).Subject = parts{1};
                dataStruct(dataIndex).Fatigue = parts{2};
                dataStruct(dataIndex).Activity = parts{3};
                dataStruct(dataIndex).Stimulation = parts{4};
                dataStruct(dataIndex).Trial = parts{5};
                
                % Import the corresponding text file
                filename = strcat(trialID, '.txt');
                if exist(fullfile('...\Input Data\ForcePlate_RawData', filename), 'file')
                    % Read the text file into a table
                    fileData = readtable(fullfile('...\Input Data\ForcePlate_RawData', filename), 'Delimiter', ',', 'ReadVariableNames', false);
      
                    % Check if the file has 6 columns
                    if width(fileData) ~= 6
                        error('The file %s does not have 6 columns', filename);
                    end
                    
                    % Crop the data to 30,000 rows if necessary
                    if height(fileData) > numRowsToKeep
                        fileData = fileData(1:numRowsToKeep, :);
                    end


                    dataArray = table2array(fileData);
                    
                    % Find the index of the first row where all columns are zero
                    zeroRowIdx = find(all(dataArray == 0, 2), 1);
                    
                    % Crop the table to keep only the rows above the first all-zeros row
                    if ~isempty(zeroRowIdx)
                        fileData = fileData(1:zeroRowIdx-1, :);
                    else
                        % If no all-zero row is found, keep the whole table
                        fileData = fileData;
                    end

                    
                    assignin('base', 'fileData', fileData);

                    % If Channel is 'All', calculate the specified Matrix
                    if strcmp(Channel, 'All')
                        % Call a function to calculate the Matrix (e.g., Sway Area)
                        switch Matrix
                            case 'Sway Area'
                                matrixData = calculateSwayArea(fileData);
                            case 'Sway Velocity'
                                matrixData = calculateSwayVelocity(fileData);
                            case 'Path Length'
                                matrixData = calculatePathLength(fileData);
                            otherwise
                                error('Invalid Matrix: %s', Matrix);
                        end
                        % Store the matrix result in timeSeriesData
                        dataStruct(dataIndex).timeSeriesData = matrixData;
                    else
                        % If Channel is not 'All', proceed with current functionality
                        if isKey(channelMap, Channel)
                            colIndex = channelMap(Channel);
                        else
                            error('Invalid Channel: %s', Channel);
                        end
                        % Extract the relevant data column based on the channel
                        dataStruct(dataIndex).timeSeriesData = fileData{:, colIndex};
                    end
                    
                    % Create timeStampsData assuming a sampling rate of 1000 Hz
                    numSamples = height(fileData);
                    dataStruct(dataIndex).timeStampsData = (0:numSamples-1) / 1000; % Time vector in seconds
                else
                    error('File %s does not exist', filename);
                end
                
                % Increment dataIndex for the next entry
                dataIndex = dataIndex + 1;
            end
        end
    end

    % Sort dataStruct by activity order
    dataStruct = sortByActivity(dataStruct, xdfNames_FF);

    % Loop through each element in the struct array
    for i = 1:numel(dataStruct)
        % Transpose the timeSeriesData field
        dataStruct(i).timeSeriesData = dataStruct(i).timeSeriesData';
    end

    assignin('base', 'afterchange_FF', dataStruct);

    % Write the processed data to CSV
    if strcmp(Channel, 'All')
        filename_csv = ['AllAct_ForcePlate_' Matrix '.csv'];  % Use Matrix name in filename if 'All'
        filename_mat = ['AllAct_ForcePlate_' Matrix '.mat'];
    else
        filename_csv = ['ForcePlate_' Channel '.csv'];  % Use Channel name in filename otherwise
        filename_mat =  ['ForcePlate_' Channel '.mat'];
    end

    dataStruct = forceBasicTypes(dataStruct);
    writeToExcel(dataStruct, fullfile('...\Output Data\CSV', filename_csv));
    disp('csv saved')
    save(fullfile('...\Output Data\MAT', filename_mat), 'dataStruct');
    disp('mat saved')
end


    % Create a map to order activities
    activityOrder = containers.Map(allActivities, 1:length(allActivities));

    % Extract activities from dataStruct
    activityList = {dataStruct.Activity};

    % Convert activityList to string to match map key type
    activityList = string(activityList);

    % Map activities to their order based on xdfNames_FF
    activityOrderIdx = arrayfun(@(x) activityOrder(char(x)), activityList, 'UniformOutput', false);

    % Convert cell array to numeric array for sorting
    activityOrderIdx = cell2mat(activityOrderIdx);

    % Sort dataStruct by activity order
    [~, sortIdx] = sort(activityOrderIdx);
    dataStruct = dataStruct(sortIdx);
end




% Function to generate subject list based on start and end
function xdfNames_FF = generatexdfNames_FF(subjectStart, subjectEnd, activity)
    % update num_activities based on user selection
    if strcmp(activity, 'All_Activities')
        num_activities = 6;
        disp ('num = 6')
    else
        num_activities = 1;
    end

    activity_list = {'FPEONF', 'FPECNF', 'FPEODT', 'FPECDT','FPEOWF','FPECWF'};

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
            xdfNames_FF{a,s} = xdfLables;                                
        end
    end

   xdfNames_FF = xdfNames_FF';
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



function cleanStruct = forceBasicTypes(newStruct)
    % Get the number of entries in newStruct
    numEntries = length(newStruct);
    
    % Get the field names in newStruct
    fieldNames = fieldnames(newStruct);
    
    % Initialize the cleanStruct with the same fields
    cleanStruct(numEntries) = struct();
    
    % Loop through each entry and each field to copy and convert the values
    for i = 1:numEntries
        for j = 1:numel(fieldNames)
            % Extract the field data from newStruct
            data = newStruct(i).(fieldNames{j});
            
            % Force conversion to basic MATLAB types
            if iscell(data)
                % Convert cell array to its contents
                if numel(data) == 1
                    data = data{1}; % Unwrap single-element cell arrays
                else
                    data = cellfun(@(x) x, data, 'UniformOutput', false); % Leave multi-element cells as is
                end
            end
            
            % Convert to char if it’s a string
            if isstring(data)
                data = char(data);
            end
            
            % Convert to double if possible (handles most cases)
            if isa(data, 'numeric') || isnumeric(data)
                data = double(data);
            end
            
            % Assign the cleaned data to the cleanStruct
            cleanStruct(i).(fieldNames{j}) = data;
        end
    end
end