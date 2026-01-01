clc;
clear all;

% List of .xdf file names

% Define 
subjects = {'S1'};
filename = 'HeartRate.txt';  % Replace with the actual file name

% activity_list = {'TWEO'};
activity_list = {'TWEO', 'TWEC', 'TWDT', 'OW', 'HOW', 'FPEONF', 'FPECNF', 'FPEOWF', 'FPECWF', 'FNC', 'PP'};

% Initialize the cell array to store the file names
xdfFiles = {};

% Loop over each subject
for i = 1:length(subjects)
    subject = subjects{i};
    
    % Loop over each activity
    for j = 1:length(activity_list)
        activity = activity_list{j};
        
        % Generate the filenames for the current subject and activity
        currentFiles = generateXdfFilenames(subject, activity);
        
        % Append the generated filenames to the xdfFiles cell array
        xdfFiles = [xdfFiles, currentFiles];
    end
end

% Ensure xdfFiles is a 1xN cell array
xdfFiles = reshape(xdfFiles, 1, []);

% Display the generated filenames
% disp(xdfFiles);

% xdfFiles = {'S2-pr-TWEO-NG-T1.xdf', 'S2-pr-TWEO-NG-T2.xdf', 'S2-pr-HOW-NG-T1.xdf', 'S2-pr-HOW-NG-T2.xdf','S2-pr-FPECWF-NG-T1.xdf', 'S2-pr-FPECWF-NG-T2.xdf'};  % Add the full list of files
targetName = 'TimestampStream'; % The only target name

% Initialize a structure to store the extracted ECG and epoch times for each .xdf file
allData = struct();

% Loop through each .xdf file
for i = 1:length(xdfFiles)
    % Load the .xdf file
    dataCellArray = load_xdf(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Input Data\xdf_RawData', xdfFiles{i}));

    
    % Find the TimestampStream data
    for j = 1:length(dataCellArray)
        currentStruct = dataCellArray{j};
        if isfield(currentStruct, 'info') && isfield(currentStruct.info, 'name') && strcmp(currentStruct.info.name, targetName)
            time_series = currentStruct.time_series;
            
            % Convert the time_series to numeric array if it is a cell array
            if iscell(time_series)
                time_series = cellfun(@str2double, time_series);
            end
            
            % Convert milliseconds to seconds and then to datetime with local timezone
            time_stamps_seconds = time_series / 1000;
            datetime_values = datetime(time_stamps_seconds, 'ConvertFrom', 'posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', 'local');
            
            % Store the datetime values for later use
            eval([matlab.lang.makeValidName(xdfFiles{i}), '_datetime_values = datetime_values;']);
            
            break; % Exit the loop once the match is found
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Open the file for reading
fid = fopen(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Input Data\Actiheart_RawData', filename), 'r');

% Read and ignore header lines until we reach the data
headerLines = 15; % Number of lines to skip before the data starts
for i = 1:headerLines
    fgetl(fid);
end

% Define the format of the data
formatSpec = '%s%s%f%f%f';

% Read the data
ECG_data = textscan(fid, formatSpec, 'Delimiter', '\t');

% Close the file
fclose(fid);

% Extract each column into separate variables
Date = ECG_data{1};
Time = ECG_data{2};
SecondFraction = ECG_data{3};
TotalSeconds = ECG_data{4};
ECG = ECG_data{5};

% Crop all ECG data columns to the smallest number of rows (79104)
minRows = min([length(Date), length(Time), length(SecondFraction), length(TotalSeconds), length(ECG)]);
Date = Date(1:minRows);
Time = Time(1:minRows);
SecondFraction = SecondFraction(1:minRows);
TotalSeconds = TotalSeconds(1:minRows);
ECG = ECG(1:minRows);

% Create datetime values from the Date and Time columns
ECG_datetime = datetime(strcat(Date, {' '}, Time), 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone', 'local');

% Add the fractional seconds
ECG_datetime = ECG_datetime + seconds(SecondFraction);

% Find the ECG values corresponding to the time range of each .xdf file
for i = 1:length(xdfFiles)
    % Get the datetime values for the current .xdf file
    datetime_values = eval([matlab.lang.makeValidName(xdfFiles{i}), '_datetime_values']);
    
    % Find the ECG data within the time range
    start_time = datetime_values(1);
    end_time = datetime_values(end);
    ecg_indices = (ECG_datetime >= start_time) & (ECG_datetime <= end_time);
    
    % Extract the ECG values and epoch times
    extractedECG = ECG(ecg_indices);
    extractedEpochTimes = TotalSeconds(ecg_indices);  % Assuming TotalSeconds are the epoch times
    
    % Store data in the structure
    fileNameField = matlab.lang.makeValidName(xdfFiles{i});
    allData.(fileNameField).extractedECG = extractedECG;
    allData.(fileNameField).extractedEpochTimes = extractedEpochTimes;
end



% Assuming allData is your original struct

% Get the field names of allData
fieldNames = fieldnames(allData);

% Initialize a new struct to store the renamed fields
newData = struct();

% Loop through each field name
for i = 1:length(fieldNames)
    % Get the current field name
    oldFieldName = fieldNames{i};
    
    % Remove the '_xdf' suffix from the field name
    if endsWith(oldFieldName, '_xdf')
        newFieldName = extractBefore(oldFieldName, '_xdf');
    else
        newFieldName = oldFieldName;
    end
    
    % Assign the data to the new field in newData
    newData.(newFieldName) = allData.(oldFieldName);
end

% Now, newData has the updated field names
% Optionally, you can replace allData with newData if you want
allData = newData;



% Extract the prefix from the first file in xdfFiles (e.g., 'S1' from 'S1-pr-TWEO-NG-T1.xdf')
[~, baseFileName, ~] = fileparts(xdfFiles{1});
prefix = strtok(baseFileName, '-');  % This will give you 'S1'

% Construct the .mat filename and structure name using the extracted prefix
matFileName = [prefix, '_HR_allAct.mat'];
structName = [prefix, '_HR_allAct'];

% Save all data to the constructed .mat file with the appropriate structure name
eval([structName ' = allData;']);
save(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Input Data\Actiheart_Extracted_MATs', matFileName), structName);
dis('data saved')

% Define the function to generate filenames
function xdfFiles = generateXdfFilenames(subject, activity)
    xdfFiles = {
        [subject, '-pr-', activity, '-NG-T1.xdf'], 
        [subject, '-pr-', activity, '-NG-T2.xdf'], 
        [subject, '-pr-', activity, '-G-T1.xdf'], 
        [subject, '-pr-', activity, '-G-T2.xdf'], 
        [subject, '-po-', activity, '-NG-T1.xdf'], 
        [subject, '-po-', activity, '-NG-T2.xdf'], 
        [subject, '-po-', activity, '-G-T1.xdf'], 
        [subject, '-po-', activity, '-G-T2.xdf']
    };
end
