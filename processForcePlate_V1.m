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
                if exist(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Input Data\ForcePlate_RawData', filename), 'file')
                    % Read the text file into a table
                    fileData = readtable(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Input Data\ForcePlate_RawData', filename), 'Delimiter', ',', 'ReadVariableNames', false);
      
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
    writeToExcel(dataStruct, fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\CSV', filename_csv));
    disp('csv saved')
    save(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\MAT', filename_mat), 'dataStruct');
    disp('mat saved')
end


% % Function to calculate Sway Area
% function swayArea = calculateSwayArea(fileData)
%    % Extract force and moment data
%     Fz = fileData{:, 3};  % Vertical force
%     Mx = fileData{:, 4};  % Moment around x direction
%     My = fileData{:, 5};  % Moment around y direction
% 
%     % Add a small constant to Fz to avoid division by zero
%     Fz = Fz + 1e-6;
% 
%     % Calculate the CoP coordinates
%     CoP_x = ((My + Fz * 0) ./ Fz)*100;
%     CoP_y = ((Mx + Fz * 0) ./ Fz)*100;
% 
%     % Check for NaN values
%     if any(isnan(CoP_x)) || any(isnan(CoP_y))
%         error('NaN values detected in CoP coordinates.');
%     end
% 
%     % Calculate the sway area using the CoP coordinates
%     swayArea = trapz(CoP_x, CoP_y);
% 
%     % If swayArea is NaN, check for issues in CoP coordinates or integration
%     if isnan(swayArea)
%         error('NaN value detected in swayArea calculation.');
%     end
% end

% Function to calculate Sway Area using an ellipse
function swayArea = calculateSwayArea(fileData)
    % Extract force and moment data
    Fz = fileData{:, 3};
    Mx = fileData{:, 4};
    My = fileData{:, 5};

    Fz = Fz + 1e-6;

    % Calculate CoP coordinates
    CoP_x = ((My + Fz * 0) ./ Fz) * 100;
    CoP_y = ((Mx + Fz * 0) ./ Fz) * 100;

    % Check for NaN values
    if any(isnan(CoP_x)) || any(isnan(CoP_y))
        error('NaN values detected in CoP coordinates.');
    end

    % Calculate covariance matrix and eigenvalues
    covarianceMatrix = cov(CoP_x, CoP_y);
    eigenValues = eig(covarianceMatrix);

    % Calculate sway area as 95% confidence ellipse area
    swayArea = pi * sqrt(eigenValues(1)) * sqrt(eigenValues(2));

    % Check for NaN in swayArea
    if isnan(swayArea)
        error('NaN value detected in swayArea calculation.');
    end
end



% Function to calculate Sway Velocity
function swayVelocity = calculateSwayVelocity(fileData)
 % Extract force and moment data
   % Extract force and moment data
    Fz = fileData{:, 3};  % Vertical force
    Mx = fileData{:, 4};  % Moment around x direction
    My = fileData{:, 5};  % Moment around y direction

    Fz = Fz + 1e-6;

    % Calculate CoP coordinates considering offsets (d_x and d_y)
    d_x = 0;  % Replace with actual offset if applicable
    d_y = 0;  % Replace with actual offset if applicable
    CoP_x = ((My + Fz * d_x) ./ Fz) * 100;  % Convert to cm
    CoP_y = ((Mx + Fz * d_y) ./ Fz) * 100;  % Convert to cm

    % Calculate velocity from displacement
    dt = 1 / 1000;  % Sampling rate is 1000 Hz, so dt is 1 ms

    % Calculate the difference between consecutive CoP points
    velocityX = diff(CoP_x) / dt;
    velocityY = diff(CoP_y) / dt;

    % Calculate the magnitude of the velocity vector
    swayVelocity = sqrt(velocityX.^2 + velocityY.^2);

    % Check for NaN values
    if any(isnan(swayVelocity))
        error('NaN values detected in swayVelocity calculation.');
    end
end

% Function to calculate Path Length
function pathLength = calculatePathLength(fileData)

% Extract CoP coordinates
    Fz = fileData{:, 3};  % Vertical force
    Mx = fileData{:, 4};  % Moment around x direction
    My = fileData{:, 5};  % Moment around y direction

    Fz = Fz + 1e-6;
    
    % Calculate CoP coordinates
    CoP_x = ((My + Fz * 0) ./ Fz) * 100; % Convert to centimeters
    CoP_y = ((Mx + Fz * 0) ./ Fz) * 100; % Convert to centimeters
    
    % Calculate displacement between consecutive points
    displacement = sqrt(diff(CoP_x).^2 + diff(CoP_y).^2);
    
    % Sum of displacements gives the path length
    pathLength = sum(displacement);  % Path length in centimeters
end

% Function to sort dataStruct by activity order
function dataStruct = sortByActivity(dataStruct, xdfNames_FF)
    % Ensure xdfNames_FF is a cell array
    if ~iscell(xdfNames_FF)
        error('xdfNames_FF must be a cell array.');
    end

    % Initialize an empty cell array to collect unique activities
    allActivities = {};

    % Loop through each cell in xdfNames_FF to extract trialIDs
    for i = 1:size(xdfNames_FF, 1)
        for j = 1:size(xdfNames_FF, 2)
            cellData = xdfNames_FF{i, j};
            if ~iscell(cellData)
                error('Each element of xdfNames_FF should be a cell array.');
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

    % Map activities to their order based on xdfNames_FF
    activityOrderIdx = arrayfun(@(x) activityOrder(char(x)), activityList, 'UniformOutput', false);

    % Convert cell array to numeric array for sorting
    activityOrderIdx = cell2mat(activityOrderIdx);

    % Sort dataStruct by activity order
    [~, sortIdx] = sort(activityOrderIdx);
    dataStruct = dataStruct(sortIdx);
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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