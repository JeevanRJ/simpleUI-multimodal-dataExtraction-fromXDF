
function processAngularKinematics1_V1(activity, additionalInput, additionalSegment, all_time_stamps, all_time_series, xdfNames)

    dataStruct = struct('activityID', {}, 'subjectID', {}, 'trialID', {}, 'timeSeriesData', {}, 'timeStampsData', {});

    numActivities = size(xdfNames, 2);
    numSubjects = size(xdfNames, 1);
    structIdx = 1;

    for activityIdx = 1:numActivities
        for subjectIdx = 1:numSubjects
            trialNamesCell = xdfNames{subjectIdx, activityIdx};

            for trialIdx = 1:length(trialNamesCell)
                trialID = trialNamesCell{trialIdx};
                timeSeriesData = all_time_series{activityIdx}{subjectIdx, trialIdx};
                timeStampsData = all_time_stamps{activityIdx}{subjectIdx, trialIdx};

                if isempty(timeSeriesData)
                    timeSeriesData = NaN;
                end
                if isempty(timeStampsData)
                    timeStampsData = NaN;
                end

                dataStruct(structIdx).activityID = activityIdx;
                dataStruct(structIdx).subjectID = subjectIdx;
                dataStruct(structIdx).trialID = trialID;
                dataStruct(structIdx).timeSeriesData = timeSeriesData;
                dataStruct(structIdx).timeStampsData = timeStampsData;

                structIdx = structIdx + 1;
            end
        end
    end

    inputMap = containers.Map({'Angular position around X', 'Angular position around Y', 'Angular position around Z', ...
                                'Quaternion', 'Angular Velocity X', 'Angular Velocity Y', 'Angular Velocity Z', ...
                                'Angular Acceleration X', 'Angular Acceleration Y', 'Angular Acceleration Z'}, 1:10);

    segmentMap = containers.Map({'Pelvis', 'L5', 'L3', 'T12', 'T8', 'Neck', 'Head', ...
                                 'Right Shoulder', 'Right Upper Arm', 'Right Forearm', 'Right Hand', ...
                                 'Left Shoulder', 'Left Upper Arm', 'Left Forearm', 'Left Hand', ...
                                 'Right Upper Leg', 'Right Lower Leg', 'Right Foot', 'Right Toe', ...
                                 'Left Upper Leg', 'Left Lower Leg', 'Left Foot', 'Left Toe'}, 1:23);

    segmentIndex = segmentMap(additionalSegment);
    inputRow = inputMap(additionalInput);
    rowToExtract = (segmentIndex - 1) * 10 + inputRow;

    for i = 1:length(dataStruct)
        currentData = dataStruct(i).timeSeriesData;

        if isempty(currentData) || all(isnan(currentData), 'all') || size(currentData, 1) < rowToExtract
            singleDataRow = NaN;
        else
            singleDataRow = currentData(rowToExtract, :);
        end

        dataStruct(i).timeSeriesData = singleDataRow;
    end

    for i = 1:length(dataStruct)
        trialID = dataStruct(i).trialID;
        parts = strsplit(trialID, '-');
        dataStruct(i).Subject = parts{1};
        dataStruct(i).Fatigue = parts{2};
        dataStruct(i).Activity = parts{3};
        dataStruct(i).Stimulation = parts{4};
        dataStruct(i).Trial = parts{5};
    end

    tempStruct = struct('trialID', [], 'Subject', [], 'Fatigue', [], 'Activity', [], 'Stimulation', [], 'Trial', [], 'timeSeriesData', [], 'timeStampsData', []);

    for i = 1:length(dataStruct)
        dataStructTemp = rmfield(dataStruct(i), {'activityID', 'subjectID'});
        tempStruct(i) = dataStructTemp;
    end

    dataStruct = tempStruct;
    assignin('base', 'afterchange_AngularKin', dataStruct);

    if numActivities > 1
        activity = 'AllAct';
    end

    filename_csv = [activity '_Xsens_' additionalInput '_' additionalSegment '.csv'];
    writeToExcel(dataStruct, fullfile('...\Output Data\CSV', filename_csv));
    disp('csv saved');

    filename_mat = [activity '_Xsens_' additionalInput '_' additionalSegment '.mat'];
    save(fullfile('...\Output Data\MAT', filename_mat), 'dataStruct');
    disp('mat saved');
end

function writeToExcel(dataStruct, filename)
    dataStruct = rmfield(dataStruct, {'trialID', 'timeStampsData'});

    for i = 1:length(dataStruct)
        timeSeriesData = dataStruct(i).timeSeriesData;

        if isempty(timeSeriesData) || all(isnan(timeSeriesData), 'all')
            dataStruct(i).timeSeriesData = NaN;
        else
            dataStruct(i).timeSeriesData = rms(timeSeriesData);
        end
    end

    dataTable = struct2table(dataStruct);
    writetable(dataTable, filename);
end
