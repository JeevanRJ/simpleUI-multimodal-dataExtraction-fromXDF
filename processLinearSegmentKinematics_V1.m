function processLinearSegmentKinematics_V1(activity, additionalInput, additionalSegment, all_time_stamps, all_time_series, xdfNames)
    % Initialize an empty array of structs
    dataStruct = struct('activityID', {}, 'subjectID', {}, 'trialID', {}, 'timeSeriesData', {}, 'timeStampsData', {});

    % Get dimensions
    numActivities = size(xdfNames, 2);
    numSubjects = size(xdfNames, 1);

    structIdx = 1;

    % Loop through each activity and subject
    for activityIdx = 1:numActivities
        for subjectIdx = 1:numSubjects
            trialNamesCell = xdfNames{subjectIdx, activityIdx};

            for trialIdx = 1:length(trialNamesCell)
                trialID = trialNamesCell{trialIdx};

                % Attempt to get data or assign NaN if missing
                try
                    timeSeriesData = all_time_series{activityIdx}{subjectIdx, trialIdx};
                    if isempty(timeSeriesData)
                        timeSeriesData = NaN;
                    end
                catch
                    timeSeriesData = NaN;
                end

                try
                    timeStampsData = all_time_stamps{activityIdx}{subjectIdx, trialIdx};
                    if isempty(timeStampsData)
                        timeStampsData = NaN;
                    end
                catch
                    timeStampsData = NaN;
                end

                % Add to struct
                dataStruct(structIdx).activityID = activityIdx;
                dataStruct(structIdx).subjectID = subjectIdx;
                dataStruct(structIdx).trialID = trialID;
                dataStruct(structIdx).timeSeriesData = timeSeriesData;
                dataStruct(structIdx).timeStampsData = timeStampsData;

                structIdx = structIdx + 1;
            end
        end
    end

    assignin('base', 'beforechange_LinearKin', dataStruct);

    % Define mappings
    inputMap = containers.Map({'Linear Position X', 'Linear Position Y', 'Linear Position Z', ...
                               'Linear Velocity X', 'Linear Velocity Y', 'Linear Velocity Z', ...
                               'Linear Acceleration X', 'Linear Acceleration Y', 'Linear Acceleration Z'}, 1:9);

    segmentMap = containers.Map({'Pelvis', 'L5', 'L3', 'T12', 'T8', 'Neck', 'Head', ...
                                 'Right Shoulder', 'Right Upper Arm', 'Right Forearm', 'Right Hand', ...
                                 'Left Shoulder', 'Left Upper Arm', 'Left Forearm', 'Left Hand', ...
                                 'Right Upper Leg', 'Right Lower Leg', 'Right Foot', 'Right Toe', ...
                                 'Left Upper Leg', 'Left Lower Leg', 'Left Foot', 'Left Toe'}, 1:23);

    segmentIndex = segmentMap(additionalSegment);
    inputRow = inputMap(additionalInput);
    rowToExtract = (segmentIndex - 1) * 9 + inputRow;

    % Extract the desired row from 207xN
    for i = 1:length(dataStruct)
        ts = dataStruct(i).timeSeriesData;
        if isnumeric(ts) && ~isscalar(ts) && size(ts, 1) >= rowToExtract
            dataStruct(i).timeSeriesData = ts(rowToExtract, :);
        elseif isnumeric(ts) && isscalar(ts) && isnan(ts)
            dataStruct(i).timeSeriesData = NaN;  % Already NaN
        else
            dataStruct(i).timeSeriesData = NaN;  % Handle unexpected shape
        end
    end

    % Split trialID into fields
    for i = 1:length(dataStruct)
        trialID = dataStruct(i).trialID;
        parts = strsplit(trialID, '-');

        if length(parts) >= 5
            dataStruct(i).Subject = parts{1};
            dataStruct(i).Fatigue = parts{2};
            dataStruct(i).Activity = parts{3};
            dataStruct(i).Stimulation = parts{4};
            dataStruct(i).Trial = parts{5};
        else
            dataStruct(i).Subject = '';
            dataStruct(i).Fatigue = '';
            dataStruct(i).Activity = '';
            dataStruct(i).Stimulation = '';
            dataStruct(i).Trial = '';
        end
    end

    % Reorder fields
    tempStruct = struct('trialID', [], 'Subject', [], 'Fatigue', [], 'Activity', [], ...
                        'Stimulation', [], 'Trial', [], 'timeSeriesData', [], 'timeStampsData', []);
    for i = 1:length(dataStruct)
        dataStructTemp = rmfield(dataStruct(i), {'activityID', 'subjectID'});
        tempStruct(i).trialID = dataStructTemp.trialID;
        tempStruct(i).Subject = dataStructTemp.Subject;
        tempStruct(i).Fatigue = dataStructTemp.Fatigue;
        tempStruct(i).Activity = dataStructTemp.Activity;
        tempStruct(i).Stimulation = dataStructTemp.Stimulation;
        tempStruct(i).Trial = dataStructTemp.Trial;
        tempStruct(i).timeSeriesData = dataStructTemp.timeSeriesData;
        tempStruct(i).timeStampsData = dataStructTemp.timeStampsData;
    end

    dataStruct = tempStruct;

    assignin('base', 'afterchange_LinearKin', dataStruct);

    % Determine filenames
    if numActivities > 1
        activity = 'AllAct';
    end

    filename_csv = [activity '_Xsens_' additionalInput '_' additionalSegment '.csv'];
    filename_mat = [activity '_Xsens_' additionalInput '_' additionalSegment '.mat'];

    writeToExcel(dataStruct, fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction_CF\Output Data\CSV', filename_csv));
    disp('csv file saved')

    save(fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction_CF\Output Data\MAT', filename_mat), 'dataStruct');
    disp('mat file saved')
end

function writeToExcel(dataStruct, filename)
    % Remove unwanted fields
    dataStruct = rmfield(dataStruct, {'trialID', 'timeStampsData'});

    % Replace timeSeriesData with RMS or NaN
    for i = 1:length(dataStruct)
        ts = dataStruct(i).timeSeriesData;
        if isnumeric(ts) && ~isscalar(ts)
            dataStruct(i).timeSeriesData = rms(ts);
        else
            dataStruct(i).timeSeriesData = NaN;
        end
    end

    % Convert and write
    dataTable = struct2table(dataStruct);
    writetable(dataTable, filename);
end



