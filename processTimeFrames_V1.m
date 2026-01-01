function processTimeFrames_V1(activity, all_time_stamps, all_time_series, xdfNames)
    % Initialize an empty array of structs
    dataStruct = struct('activityID', {}, 'subjectID', {}, 'trialID', {}, 'timeSeriesData', {}, 'timeStampsData', {});

    % Get the total number of activities and subjects
    numActivities = size(xdfNames, 2);
    numSubjects  = size(xdfNames, 1);

    % Counter to keep track of struct index
    structIdx = 1;

    % Loop through each activity
    for activityIdx = 1:numActivities
        % Loop through each subject
        for subjectIdx = 1:numSubjects
            % Get the trial names for the current subject and activity
            if subjectIdx > size(xdfNames,1) || activityIdx > size(xdfNames,2)
                warning('Index out of bounds in xdfNames at S%d A%d. Skipping.', subjectIdx, activityIdx);
                continue;
            end

            trialNamesCell = xdfNames{subjectIdx, activityIdx};
            if isempty(trialNamesCell)
                % No trials for this subject/activity
                continue;
            end

            % Loop through each trial
            for trialIdx = 1:length(trialNamesCell)
                % Access the trial name (ID)
                trialID = trialNamesCell{trialIdx};

                % Access the corresponding data (guard all indexing)
                try
                    ts_cell = all_time_series{activityIdx};
                    tm_cell = all_time_stamps{activityIdx};

                    % Validate inner cell sizes before indexing
                    if subjectIdx > size(ts_cell,1) || trialIdx > size(ts_cell,2)
                        warning('Missing time series cell at A%d S%d T%d (%s). Skipping.', activityIdx, subjectIdx, trialIdx, trialID);
                        continue;
                    end
                    if subjectIdx > size(tm_cell,1) || trialIdx > size(tm_cell,2)
                        warning('Missing time stamps cell at A%d S%d T%d (%s). Skipping.', activityIdx, subjectIdx, trialIdx, trialID);
                        continue;
                    end

                    timeSeriesData  = ts_cell{subjectIdx, trialIdx};
                    timeStampsData  = tm_cell{subjectIdx, trialIdx};
                catch ME
                    warning('Indexing error at A%d S%d T%d (%s): %s. Skipping.', activityIdx, subjectIdx, trialIdx, trialID, ME.message);
                    continue;
                end

                % Store (even if empty); we will guard later when reading rows
                dataStruct(structIdx).activityID     = activityIdx;
                dataStruct(structIdx).subjectID      = subjectIdx;
                dataStruct(structIdx).trialID        = trialID;
                dataStruct(structIdx).timeSeriesData = timeSeriesData;
                dataStruct(structIdx).timeStampsData = timeStampsData;

                % Increment the struct index
                structIdx = structIdx + 1;
            end
        end
    end

    assignin('base', 'beforechange_TimeFrames', dataStruct);
    assignin('base', 'time_stamps', all_time_stamps);
    assignin('base', 'time_series', all_time_series);

    % Initialize an empty struct array with the desired field names.
    % (Include timeFrames to match usage below.)
    tempStruct = struct('trialID', [], 'Subject', [], 'Fatigue', [], 'Activity', [], ...
                        'Stimulation', [], 'Trial', [], 'FrameNumber', [], ...
                        'Time_Seconds', [], 'timeStampsData', [], 'timeFrames', []);

    % Build tempStruct while SKIPPING invalid/missing trials safely
    tIdx = 0;
    for i = 1:length(dataStruct)
        % Remove the activityID and subjectID columns
        dataStructTemp = rmfield(dataStruct(i), {'activityID', 'subjectID'});

        % Separate the trialID into Subject, Fatigue, Activity, Stimulation, Trial
        trialID = dataStructTemp.trialID;
        if ~ischar(trialID) && ~isstring(trialID)
            warning('Invalid trialID at index %d. Skipping.', i);
            continue;
        end
        parts = strsplit(char(trialID), '-');
        if numel(parts) < 5
            warning('Malformed trialID "%s" (expected 5 parts). Skipping.', trialID);
            continue;
        end

        % Extract time series and validate row access
        timeSeriesData = dataStructTemp.timeSeriesData;
        if isempty(timeSeriesData) || ~ismatrix(timeSeriesData) || size(timeSeriesData,1) < 1
            warning('Empty/invalid timeSeriesData at %s. Skipping.', trialID);
            continue;
        end

        % Row-1 guard (the original error line). Only proceed if safe.
        if size(timeSeriesData,1) >= 1
            this_timeFrames = timeSeriesData(1, :);
        else
            warning('timeSeriesData has no first row at %s. Skipping.', trialID);
            continue;
        end

        % Everything ok: append to tempStruct
        tIdx = tIdx + 1;
        tempStruct(tIdx).trialID       = trialID;
        tempStruct(tIdx).Subject       = parts{1};
        tempStruct(tIdx).Fatigue       = parts{2};
        tempStruct(tIdx).Activity      = parts{3};
        tempStruct(tIdx).Stimulation   = parts{4};
        tempStruct(tIdx).Trial         = parts{5};

        % Keep your original placeholders; Time_Seconds left unused as in your code
        tempStruct(tIdx).FrameNumber   = [];
        tempStruct(tIdx).Time_Seconds  = [];

        % Assign frames and timestamps (timestamps may be empty; that's okay)
        tempStruct(tIdx).timeFrames    = this_timeFrames;
        tempStruct(tIdx).timeStampsData = dataStructTemp.timeStampsData;
    end

    % Replace the original dataStruct with the reordered tempStruct
    dataStruct = tempStruct;

    % Initialize the new struct
    mod_dataStruct = struct();

    % Loop through each entry in dataStruct to populate mod_dataStruct
    for i = 1:length(dataStruct)
        % Copy relevant fields
        mod_dataStruct(i).trialID     = dataStruct(i).trialID;
        mod_dataStruct(i).Subject     = dataStruct(i).Subject;
        mod_dataStruct(i).Fatigue     = dataStruct(i).Fatigue;
        mod_dataStruct(i).Activity    = dataStruct(i).Activity;
        mod_dataStruct(i).Stimulation = dataStruct(i).Stimulation;
        mod_dataStruct(i).Trial       = dataStruct(i).Trial;

        % Get Start_frame and End_frame (guard empty)
        if isempty(dataStruct(i).timeFrames)
            warning('Empty timeFrames for %s. Setting Start/End to NaN.', dataStruct(i).trialID);
            mod_dataStruct(i).Start_timeFrame = NaN;
            mod_dataStruct(i).End_timeFrame   = NaN;
        else
            mod_dataStruct(i).Start_timeFrame = dataStruct(i).timeFrames(1);
            mod_dataStruct(i).End_timeFrame   = dataStruct(i).timeFrames(end);
        end
    end

    assignin('base', 'afterchange_TimeFrames', mod_dataStruct);

    % Keep your activity naming
    if numActivities > 1
        activity_out = 'AllAct';
    else
        activity_out = activity;
    end

    filename_csv = [activity_out '_TimeFrames.csv'];
    filename_mat = [activity_out '_TimeFrames.mat'];

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

    % Convert struct to table (handles empty gracefully)
    if isempty(mod_dataStruct)
        warning('mod_dataStruct is empty. Writing an empty CSV with headers.');
        dataTable = struct2table(struct('trialID', {}, 'Subject', {}, 'Fatigue', {}, 'Activity', {}, ...
                                        'Stimulation', {}, 'Trial', {}, 'Start_timeFrame', {}, 'End_timeFrame', {}));
    else
        dataTable = struct2table(mod_dataStruct);
    end

    % Write to CSV file
    writetable(dataTable, filename);

    disp(['Data written to ', filename]);
end
