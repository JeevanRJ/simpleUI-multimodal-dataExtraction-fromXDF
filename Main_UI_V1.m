function Data_extraction_functions_v12()
    % Create the UI figure
    fig = uifigure('Name', 'Experiment Data Extraction', 'Position', [100 100 400 500]);

    % Subject selection
    uilabel(fig, 'Position', [20 430 100 22], 'Text', 'Select Subject(s):');
    subjectDropDown1 = uidropdown(fig, 'Position', [120 430 120 22], ...
                                  'Items', {'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10','S11','S12', 'S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19', 'S20', 'S21','S22', 'S23', 'S24', 'S25', 'S26'}, ...
                                  'Value', 'S1');
    subjectDropDown2 = uidropdown(fig, 'Position', [250 430 120 22], ...
                                  'Items', {'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10','S11','S12', 'S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19', 'S20', 'S21','S22', 'S23', 'S24', 'S25', 'S26'}, ...
                                  'Value', 'S1');

    % Activity selection
    uilabel(fig, 'Position', [20 380 100 22], 'Text', 'Select Activity:');
    activityDropDown = uidropdown(fig, 'Position', [120 380 250 22], ...
                                  'Items', {'TWEO', 'TWEC', 'TWDT', 'OW', 'HOW', 'FPEONF', 'FPECNF', 'FPEODT', 'FPECDT','FPEOWF','FPECWF','FNC','PP', 'All_Activities'}, ...
                                  'Value', 'TWEO');

    % Data type selection
    uilabel(fig, 'Position', [20 330 100 22], 'Text', 'Select Data Type:');
    dataTypeDropDown = uidropdown(fig, 'Position', [120 330 250 22], ...
                                  'Items', {'fNIRS', 'Homer3', 'EMG', 'HeartRate', 'ForcePlate','EyeTracking','LinearSegmentKinematicsDatagram1', 'AngularKinematics1', 'CenterOfMass1', 'EulerDatagram1', 'QuaternionDatagram1', 'video_data', 'TimestampStream'}, ...
                                  'Value', 'fNIRS', ...
                                  'ValueChangedFcn', @(dd, event) dataTypeSelectionChanged(dd, fig));

    % Additional input placeholder (e.g., Channel for EMG)
    additionalInputLabel = uilabel(fig, 'Position', [20 280 100 22], 'Text', 'Additional Input:');
    additionalInputField = uidropdown(fig, 'Position', [120 280 250 22], ...
                                      'ValueChangedFcn', @(dd, event) additionalInputChanged(dd));

    % Second Additional input placeholder for specific body segments or matrices
    additionalSegmentLabel = uilabel(fig, 'Position', [20 230 120 22], 'Text', 'Segment:');
    additionalSegmentField = uidropdown(fig, 'Position', [120 230 250 22]);

    % Extract Data Button
    extractButton = uibutton(fig, 'Position', [150 150 100 22], 'Text', 'Extract Data', ...
                             'ButtonPushedFcn', @(btn, event) extractData(subjectDropDown1.Value, ...
                                                                          subjectDropDown2.Value, ...
                                                                          activityDropDown.Value, ...
                                                                          dataTypeDropDown.Value, ...
                                                                          additionalInputField.Value, ...
                                                                          additionalSegmentField.Value)); %#ok<NASGU> 

    % Initialize the UI with the correct additional input based on the default data type
    dataTypeSelectionChanged(dataTypeDropDown, fig);

    % Nested function to handle data type selection changes
    function dataTypeSelectionChanged(dd, fig) %#ok<INUSD> 
        selectedType = dd.Value;
        switch selectedType
            case 'fNIRS'
                additionalInputLabel.Text = 'Select Channel:';
                additionalInputField.Items = {'Not_Required'};
                additionalInputField.Value = 'Not_Required';
                additionalSegmentLabel.Text = 'Segment:';
                additionalSegmentField.Items = {'Not_Required'};
                additionalSegmentField.Value = 'Not_Required';

            case 'Homer3'
                additionalInputLabel.Text = 'Select Channel:';
                additionalInputField.Items = {'Not_Required'};
                additionalInputField.Value = 'Not_Required';
                additionalSegmentLabel.Text = 'Segment:';
                additionalSegmentField.Items = {'Not_Required'};
                additionalSegmentField.Value = 'Not_Required';
            case 'EMG'
                additionalInputLabel.Text = 'Select Channel:';
                additionalInputField.Items = {'LES', 'RES', 'LVL', 'RVL', 'LGM', 'RGM', 'LTA', 'RTA'};
                additionalInputField.Value = 'LES';
                additionalSegmentLabel.Text = 'Segment:';
                additionalSegmentField.Items = {'Not_Required'};
                additionalSegmentField.Value = 'Not_Required';
            case 'HeartRate'
                additionalInputLabel.Text = 'Select Channel:';
                additionalInputField.Items = {'Not_Required'};
                additionalInputField.Value = 'Not_Required';
                additionalSegmentLabel.Text = 'Matrix:';
                additionalSegmentField.Items = {'timeSeries','Mean','Heart Rate Variability - SDNN', 'Heart Rate Variability - RMSSD'};
                additionalSegmentField.Value = 'timeSeries';
            case 'ForcePlate'
                additionalInputLabel.Text = 'Select Channel:';
                additionalInputField.Items = {'Fx', 'Fy', 'Fz', 'Mx', 'My', 'Mz', 'All'};
                additionalInputField.Value = 'Fx';
                additionalSegmentLabel.Text = 'Segment:';
                additionalSegmentField.Items = {'Not_Required'};
                additionalSegmentField.Value = 'Not_Required';
            case 'EyeTracking'
                additionalInputLabel.Text = 'Select Channel:';
                additionalInputField.Items = {'Pupil diameter right'};
                additionalInputField.Value = 'Pupil diameter right';
                additionalSegmentLabel.Text = 'Segment:';
                additionalSegmentField.Items = {'Not_Required'};
                additionalSegmentField.Value = 'Not_Required';
            case 'LinearSegmentKinematicsDatagram1'
                additionalInputLabel.Text = 'Additional Input:';
                additionalInputField.Items = {'Linear Position X', 'Linear Position Y', 'Linear Position Z', ...
                                              'Linear Velocity X', 'Linear Velocity Y', 'Linear Velocity Z', ...
                                              'Linear Acceleration X', 'Linear Acceleration Y', 'Linear Acceleration Z'};
                additionalInputField.Value = 'Linear Position X';
                additionalSegmentLabel.Text = 'Select Segment:';
                additionalSegmentField.Items = {'Pelvis', 'L5', 'L3', 'T12', 'T8', 'Neck', 'Head','Right Shoulder', 'Right Upper Arm', 'Right Forearm', 'Right Hand', 'Left Shoulder', 'Left Upper Arm', 'Left Forearm', 'Left Hand', 'Right Upper Leg', 'Right Lower Leg', 'Right Foot', 'Right Toe','Left Upper Leg', 'Left Lower Leg', 'Left Foot', 'Left Toe'};
                additionalSegmentField.Value = 'Pelvis';
            case 'AngularKinematics1'
                additionalInputLabel.Text = 'Additional Input:';
                additionalInputField.Items = {'Angular position around X', 'Angular position around Y', 'Angular position around Z', ...
                                              'Quaternion', 'Angular Velocity X', 'Angular Velocity Y', 'Angular Velocity Z', ...
                                              'Angular Acceleration X', 'Angular Acceleration Y', 'Angular Acceleration Z'};
                additionalInputField.Value = 'Angular position around X';
                additionalSegmentLabel.Text = 'Select Segment:';
                additionalSegmentField.Items = {'Pelvis', 'L5', 'L3', 'T12', 'T8', 'Neck', 'Head','Right Shoulder', 'Right Upper Arm', 'Right Forearm', 'Right Hand', 'Left Shoulder', 'Left Upper Arm', 'Left Forearm', 'Left Hand', 'Right Upper Leg', 'Right Lower Leg', 'Right Foot', 'Right Toe','Left Upper Leg', 'Left Lower Leg', 'Left Foot', 'Left Toe'};
                additionalSegmentField.Value = 'Pelvis';
            case 'CenterOfMass1'
                additionalInputLabel.Text = 'Select Channel:';
                additionalInputField.Items = {'Not_Required'};
                additionalInputField.Value = 'Not_Required';
                additionalSegmentLabel.Text = 'Segment:';
                additionalSegmentField.Items = {'Not_Required'};
                additionalSegmentField.Value = 'Not_Required';
            case 'video_data'
                additionalInputLabel.Text = 'Select Channel:';
                additionalInputField.Items = {'Not_Required'};
                additionalInputField.Value = 'Not_Required';
                additionalSegmentLabel.Text = 'Segment:';
                additionalSegmentField.Items = {'Not_Required'};
                additionalSegmentField.Value = 'Not_Required';
            case 'TimestampStream'
                additionalInputLabel.Text = 'Select Channel:';
                additionalInputField.Items = {'Not_Required'};
                additionalInputField.Value = 'Not_Required';
                additionalSegmentLabel.Text = 'Segment:';
                additionalSegmentField.Items = {'Not_Required'};
                additionalSegmentField.Value = 'Not_Required';
            case {'EulerDatagram1', 'QuaternionDatagram1'}
                additionalInputLabel.Text = 'Additional Input:';
                additionalInputField.Items = {'Not_Required'};
                additionalInputField.Value = 'Not_Required';
                additionalSegmentLabel.Text = 'Select Segment:';
                additionalSegmentField.Items = {'Pelvis', 'L5', 'L3', 'T12', 'T8', 'Neck', 'Head','Right Shoulder', 'Right Upper Arm', 'Right Forearm', 'Right Hand', 'Left Shoulder', 'Left Upper Arm', 'Left Forearm', 'Left Hand', 'Right Upper Leg', 'Right Lower Leg', 'Right Foot', 'Right Toe','Left Upper Leg', 'Left Lower Leg', 'Left Foot', 'Left Toe'};
                additionalSegmentField.Value = 'Pelvis';
            otherwise
                additionalInputLabel.Text = 'Additional Input:';
                additionalInputField.Items = {'Not_Required'};
                additionalInputField.Value = 'Not_Required';
                additionalSegmentLabel.Text = 'Segment:';
                additionalSegmentField.Items = {'Not_Required'};
                additionalSegmentField.Value = 'Not_Required';
        end
    end

    % Nested function to handle additional input selection change
    function additionalInputChanged(dd)
        % Get the selected data type
        dataType = dataTypeDropDown.Value;
        
        % Check if the selected data type is 'ForcePlate' and if 'All' is selected
        if strcmp(dataType, 'ForcePlate') && strcmp(dd.Value, 'All')
            additionalSegmentLabel.Text = 'Matrix:';
            additionalSegmentField.Items = {'Sway Area', 'Sway Velocity', 'Path Length'};
            additionalSegmentField.Value = 'Sway Area';
        elseif strcmp(dataType, 'HeartRate')
            additionalSegmentLabel.Text = 'Matrix:';
            additionalSegmentField.Items = {'timeSeries','Mean', 'Heart Rate Variability - SDNN', 'Heart Rate Variability - RMSSD'};
            additionalSegmentField.Value = 'timeSeries';
        elseif strcmp(dataType, 'LinearSegmentKinematicsDatagram1') || strcmp(dataType, 'AngularKinematics1')
            % Keep the segment dropdown as is for these data types
        else
            additionalSegmentLabel.Text = 'Segment:';
            additionalSegmentField.Items = {'Not_Required'};
            additionalSegmentField.Value = 'Not_Required';
        end
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END OF UI

function extractData(subjectStart, subjectEnd, activity, dataType, additionalInput, additionalSegment)

    if ~strcmp(dataType, 'ForcePlate') && ~strcmp(dataType, 'HeartRate') && ~strcmp(dataType, 'EyeTracking') && ~strcmp(dataType, 'Homer3')

        % Process subject range selection
        subjects = generateSubjectList(subjectStart, subjectEnd);
    
        persistent loadedData lastSubjects lastActivity xdfNames allLoadedData;
        persistent isFirstCall; % This flag will persist between calls to the function
    
        % Initialize first call flag if empty
        if isempty(isFirstCall)
            isFirstCall = true; 
        end
    
        all_time_series = {};
        all_time_stamps = {};
    
       activity_list = {'TWEO', 'TWEC', 'TWDT', 'OW', 'HOW', 'FPEONF', 'FPECNF','FPEODT', 'FPECDT', 'FPEOWF','FPECWF','FNC','PP'};
      % activity_list = {'TWEO', 'TWEC', 'TWDT', 'OW', 'HOW'};
       %activity_list = {'OW'};
       %activity_list = {'FPEONF', 'FPECNF', 'FPEODT', 'FPECDT', 'FPEOWF','FPECWF'};

        % Update num_activities based on user selection
        if strcmp(activity, 'All_Activities')
            num_activities = 13;
        else
            num_activities = 1;
        end
    
        % Debugging info
        disp('--- Debugging Info ---');
        disp(['isFirstCall: ', num2str(isFirstCall)]);
        disp(['loadedData isempty: ', num2str(isempty(loadedData))]);
        disp(['Subjects changed: ', num2str(~isequal(subjects, lastSubjects))]);
        disp(['Activity changed: ', num2str(~strcmp(activity, lastActivity))]);
        disp('----------------------');

        % Check if we need to load new data based on first call or changed subjects/activity
        if isempty(loadedData) || ~isequal(subjects, lastSubjects) || isFirstCall || (num_activities == 1 && ~strcmp(activity, lastActivity))
            % Only reset loadedData if new data needs to be loaded
            loadedData = {}; % Reset loadedData here, before entering the loop
            
            % Debugging message when entering the data-loading block
            disp('Resetting loadedData and entering the data-loading block...');
        end
    
        % Loop through all activities (1 or more)
        for a = 1:num_activities
    
            % Handle currentActivity depending on whether All_Activities is selected
            if num_activities == 1
                currentActivity = activity; % Keep the current activity
            else
                currentActivity = activity_list{1, a}; % Assign from the list based on index 'a'
            end
         
            % Load data only if new data is being loaded (not during the looping)
            if isempty(loadedData) || ~isequal(subjects, lastSubjects) || isFirstCall || (num_activities == 1 && ~strcmp(currentActivity, lastActivity))
                % Debugging message for entering the loading block for each activity
                disp(['Entering the data-loading block for activity: ', currentActivity]);
                
                % Loop through each subject and load corresponding .xdf files
                for s = 1:length(subjects)
                    subject = subjects{s};
                  
                    % Generate filenames based on subject and activity
                    xdfFiles = generateXdfFilenames(subject, currentActivity);
                    xdfLables = generateXdfLables(subject, currentActivity);
        
                    xdfNames{a, s} = xdfLables;
                        
                    % Loop through each .xdf file for the current subject
                    for i = 1:length(xdfFiles)
                        % Load the .xdf file
                        filePath = fullfile('R:\Research Projects\NASA_Full\NASA Data Extraction_CF\Input Data\xdf_RawData', xdfFiles{i});    
                        if exist(filePath, 'file')
                            dataCellArray = load_xdf(filePath);
                            loadedData{s, i} = dataCellArray;
                        else
                        warning('File not found: %s', filePath);
                        loadedData{s, i} = {};  % Ensure structure is intact
                        end
 
                    end
                end

                allLoadedData{a} = loadedData;

            end % end of the loading loop

            if num_activities == 1
                activity_send = {activity};
            else
                activity_send = activity_list;  % activity_list is already a cell array
            end
           
        end % end of num_activities loop


        % After loading the data, process each activity's data in a separate loop
        for b = 1:num_activities

            loadedData = allLoadedData{1,b};
            assignin('base', 'allLoadedData', allLoadedData);

            % Initialize cell arrays for time_stamps and time_series with 2D structure
            time_stamps = cell(length(subjects), 8);  % 8 files per subject
            time_series = cell(length(subjects), 8);  % 8 files per subject
        
            % Extract the time_stamps and time_series for the selected data type
            for s = 1:length(subjects)
                for i = 1:8  % Assuming 8 files per subject
                    dataCellArray = loadedData{s, i};
                    for j = 1:length(dataCellArray)
                        currentStruct = dataCellArray{j};
                        if isfield(currentStruct, 'info') && isfield(currentStruct.info, 'name') && strcmp(currentStruct.info.name, dataType)
                            time_stamps{s, i} = currentStruct.time_stamps;
                            time_series{s, i} = currentStruct.time_series;
                        end
                    end
                end
            end
        
            % Save time_stamps and time_series here
            all_time_stamps{1, b} = time_stamps;
            all_time_series{1, b} = time_series;

        end

        
        % Update lastSubjects and lastActivity after all activities processed
        lastSubjects = subjects;
        if num_activities == 1
            lastActivity = activity;
        else
            lastActivity = 'All_Activities'; % Special value to indicate all activities were processed
        end

        % Set isFirstCall to false after the first complete execution
        isFirstCall = false;
    end % end of data type condition

    % Call appropriate function based on data type
    switch dataType
        case 'fNIRS'
            processfNIRS_V1(subjects', activity_send, loadedData, xdfNames');
        case 'Homer3'
            processHomer3_V1(subjectStart, subjectEnd, activity);
        case 'EMG'
            processEMG_V1(activity,additionalInput, all_time_stamps, all_time_series, xdfNames');
        case 'LinearSegmentKinematicsDatagram1'
            processLinearSegmentKinematics_V1(activity, additionalInput, additionalSegment, all_time_stamps, all_time_series, xdfNames');
        case 'AngularKinematics1'
            processAngularKinematics1_V1(activity, additionalInput, additionalSegment, all_time_stamps, all_time_series, xdfNames');
        case 'CenterOfMass1'
            processCenterOfMass1_V1(activity, all_time_stamps, all_time_series, xdfNames');
        case 'EulerDatagram1'
            processEulerDatagram1_V1(activity, additionalSegment, all_time_stamps, all_time_series, xdfNames');
        case 'HeartRate'
            processHeartRate_V1(subjectStart, subjectEnd, activity, additionalInput, additionalSegment);
        case 'ForcePlate'
            processForcePlate_V1(subjectStart, subjectEnd, activity, additionalInput, additionalSegment);
        case 'EyeTracking'
            processEyeTracking_V1(subjectStart, subjectEnd, activity, additionalInput);
        case 'QuaternionDatagram1'
            processQuaternion(subjects, activity, additionalInput, all_time_stamps, all_time_series);
        case 'video_data'
            processVideoFrames_V1(activity,all_time_stamps, all_time_series, xdfNames')
        case 'TimestampStream'
            processTimeFrames_V1(activity,all_time_stamps, all_time_series, xdfNames')
        otherwise
            disp(['Function for ', dataType, ' data was called']);
    end
end



% Function to generate subject list based on start and end
function subjects = generateSubjectList(subjectStart, subjectEnd)
    startIdx = str2double(subjectStart(2:end));
    endIdx = str2double(subjectEnd(2:end));
    subjects = arrayfun(@(x) ['S', num2str(x)], startIdx:endIdx, 'UniformOutput', false);
end

% Function to generate XDF filenames based on subject and activity
function xdfFiles = generateXdfFilenames(subject, activity)
    % This is just an example; modify according to your filename format
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

% Function to process Quaternion data
function processQuaternion(subjects, activity, bodySegment, time_stamps, time_series)
    disp('Processing Quaternion data for:');
    disp(['Subjects: ', strjoin(subjects, ', ')]);
    disp(['Activity: ', activity]);
    disp(['Body Segment: ', bodySegment]);
    % Perform further processing with time_stamps and time_series here
    assignin('base', 'time_stamps', time_stamps);
    assignin('base', 'time_series', time_series);
end

