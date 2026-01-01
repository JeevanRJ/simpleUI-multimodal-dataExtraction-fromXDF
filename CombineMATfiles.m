% combineEMGData()

combineFFData()

disp('Process completed')

function combineEMGData()
    % Function to combine EMG data from multiple .mat files into a single struct and save as .mat file.
    % This function does not expect any inputs and uses predefined .mat files.
    
    % List of .mat files to load
    matFiles = {'AllAct_EMG_LES.mat', 'AllAct_EMG_LGM.mat', 'AllAct_EMG_LTA.mat', ...
                'AllAct_EMG_LVL.mat', 'AllAct_EMG_RES.mat', 'AllAct_EMG_RGM.mat', ...
                'AllAct_EMG_RTA.mat', 'AllAct_EMG_RVL.mat'};

    % Initialize a new structure array
    combinedStruct = struct();
    
    % Iterate over the .mat files
    for i = 1:length(matFiles)
        % Load the current .mat file
        currentFile = matFiles{i};
        loadedData = load(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\MAT', currentFile));
        dataStruct = loadedData.dataStruct;

        % Extract the muscle name from the filename
        [~, name, ~] = fileparts(currentFile);
        muscleName = name(end-2:end); % Get the last three letters (LES, LGM, etc.)

        % If it's the first file, initialize the combined structure with common fields
        if i == 1
            combinedStruct = dataStruct; % Copy the entire structure for initialization
            combinedStruct = rmfield(combinedStruct, 'timeSeriesData'); % Remove timeSeriesData
            % Initialize the new field for the first muscle
            for j = 1:length(dataStruct)
                combinedStruct(j).(muscleName) = dataStruct(j).timeSeriesData;
            end
        else
            % Add the timeSeriesData for this muscle to the existing structure
            for j = 1:length(dataStruct)
                combinedStruct(j).(muscleName) = dataStruct(j).timeSeriesData;
            end
        end
    end

    % Get the fieldnames
    fields = fieldnames(combinedStruct);
    
    % Move timeStampsData to the last position
    fields = [fields(~strcmp(fields, 'timeStampsData')); 'timeStampsData'];
    
    % Create the new struct with reordered fields
    for i = 1:numel(combinedStruct)
        for j = 1:numel(fields)
            EMGAllStruct(i).(fields{j}) = combinedStruct(i).(fields{j});
        end
    end

    EMGAllStruct = forceBasicTypes(EMGAllStruct);
    
    % Save the new struct if needed
    save('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\MAT\AllAct_EMG_Combined.mat', 'EMGAllStruct');

end



function combineFFData()
    % Function to combine EMG data from multiple .mat files into a single struct and save as .mat file.
    % This function does not expect any inputs and uses predefined .mat files.
    
    % List of .mat files to load
    matFiles = {'ForcePlate_Fx.mat', 'ForcePlate_Fy.mat', 'ForcePlate_Fz.mat', ...
                'ForcePlate_Mx.mat', 'ForcePlate_My.mat', 'ForcePlate_Mz.mat'};

    % Initialize a new structure array
    combinedStruct = struct();
    
    % Iterate over the .mat files
    for i = 1:length(matFiles)
        % Load the current .mat file
        currentFile = matFiles{i};
        loadedData = load(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\MAT', currentFile));
        dataStruct = loadedData.dataStruct;

        % Extract the muscle name from the filename
        [~, name, ~] = fileparts(currentFile);
        muscleName = name(end-1:end); % Get the last three letters (LES, LGM, etc.)

        % If it's the first file, initialize the combined structure with common fields
        if i == 1
            combinedStruct = dataStruct; % Copy the entire structure for initialization
            combinedStruct = rmfield(combinedStruct, 'timeSeriesData'); % Remove timeSeriesData
            % Initialize the new field for the first muscle
            for j = 1:length(dataStruct)
                combinedStruct(j).(muscleName) = dataStruct(j).timeSeriesData;
            end
        else
            % Add the timeSeriesData for this muscle to the existing structure
            for j = 1:length(dataStruct)
                combinedStruct(j).(muscleName) = dataStruct(j).timeSeriesData;
            end
        end
    end

    % Get the fieldnames
    fields = fieldnames(combinedStruct);
    
    % Move timeStampsData to the last position
    fields = [fields(~strcmp(fields, 'timeStampsData')); 'timeStampsData'];
    
    % Create the new struct with reordered fields
    for i = 1:numel(combinedStruct)
        for j = 1:numel(fields)
            FFAllStruct(i).(fields{j}) = combinedStruct(i).(fields{j});
        end
    end
    
    FFAllStruct = forceBasicTypes(FFAllStruct);

    % Save the new struct if needed
    save('R:\Research Projects\NASA_Full\NASA Data Extraction\Output Data\MAT\AllAct_FF_Combined.mat', 'FFAllStruct');

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