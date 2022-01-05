
% saccade or antisaccade, with primer presentation variation


%% Settings
KbName('UnifyKeyNames');        % fixes an error calling KbName('ESCAPE'), might be a Windows thing

useMouse = 0;           % Manual cursor implementation for testing (eyelink dummy mode not working), use mouse = 1 instead of gaze
screenID = 1;           % screenID = 0 for laptop alone, screenID = 1 for laptop on dual monitor setup, screenID = 2 for second monitor 

mask_method = 'metacontrast';
pattern_type = 'disc';

% set up timing based on monitor's refresh rate
fr = 60;           % frames per second
cue_duration_min = 1;       % seconds, min duration of saccade/antisaccade cue
cue_duration_max = 3;       % seconds, max duration of saccade/antisaccade cue
primer_duration = 0.015;    % seconds, duration of primer
% set ISI_min == ISI_max for constant ISI
ISI_min = 0.015;                % seconds, minimum duration of interval between primer and mask
ISI_max = 0.015;                % seconds, max duration of "
mask_duration = 0.060;      % seconds, duration of mask
trial_delay_min = 1;      % seconds, min duration of delay in between primer/mask and target
trial_delay_max = 2;      % seconds, max duratin of delay in between primer/mask and target

% Change for each new participant
ID = 'TDM_saccadetask_rec1_211102';

% set up save directory and save file for experiment data
fullpath = ('/Users/slab/Documents/tyler/Implicit-visual-processing-main/Normal monitor version/Exp1');            % operational folder for this computer
% C:\Code\Implicit visual processing\Normal monitor version\Exp1
data_filename = sprintf('%s.mat', ID);


% filename for eyelink stuff
EyelinkFilename = 'test';

% Fixation parameters
param.fix_size = 20; % pixels, cross
param.fix_width = 4; % pixels, line width
param.fix_color = [150 150 150]; % usual color of fixation (gray)
param.fix_tolerance = 100; % pixels, square around fixation
param.fix_samples = 200; % number of pre-trial gaze samples (to check if fixating correctly)

% Drift correct (pretrial) parameters for beeps
param.pretrial_nchannels = 2;  % number of channels
param.pretrial_sampleRate = 48000; % sampling rate of sound
param.pretrial_beepLength = 0.5; % seconds
param.pretrial_freq = 500; % frequency of sound

% Target parameters
param.tgt_distance = 400; % pixels, how far targets are from fixation (symmetric)
param.tgt_size = 40; % pixels, square, how large target is
param.tgt_color = [150 150 150]; % color of target (gray). Also frame color.
param.tgt_frame_size = 150; % pixels, square, size of frame
param.tgt_frame_width = 2; % pixels, line width of frame
param.tgt_time = 0.5; % time in seconds to keep recording eye movements after landing on target
param.tgt_tolerance = 150; % pixels, currently same size as frame
param.tgt_feedback_color = [255 255 0]; % yellow

% Cue parameters
param.cue_color(1, :) = [0 255 0]; % first row, color for saccade trials (green)
param.cue_color(2, :) = [255 0 0]; % second row, color for anti-saccade trials(red)
param.cue_duration_min = ceil(cue_duration_min/(1/fr)); % frames, min duration of cue presentation
param.cue_duration_max = ceil(cue_duration_max/(1/fr)); % frames, max duration of cue presentation

% Primer and mask parameters (backward masking of target primer)
param.prm_color = [150 150 150]; % color of primer and mask (gray).
param.prm_size = 40; % pixels, square, how large the primer is (same size as target).
param.mask_size = 120; % pixels, square, how large the mask is
param.mask_width = 40; % pixels, line width of mask, should spatially match border of primer
param.prm_duration = ceil(primer_duration/(1/fr)); % frames, duration of primer presentation 
param.ISI_min = ceil(ISI_min/(1/fr));  % frames, min duration in between primer and mask
param.ISI_max = ceil(ISI_max/(1/fr));  % frames, max duration in between primer and mask
param.mask_duration = ceil(mask_duration/(1/fr)); % frames, duration of mask presentation 
param.trial_delay_min = ceil(trial_delay_min/(1/fr));   % frames, min duration of delay between primer and target
param.trial_delay_max = ceil(trial_delay_max/(1/fr));   % frames, max duration of delay between primer and target

% Eye tracker drawing parameters
param.tracker_color = [0 0 255]; % color for eye tracking location drawing
param.tracker_size = 10; % pixels, square

% Generate trial order using written presets
expt = generateSaccadeTaskTrials('Exp1');        % test_preset1 = testing preset


%% Initialize

% Shift focus to command window so typing doesn't go to code editor if something
% happens to break
commandwindow
HideCursor;

% Now, set up PTB
% PsychDefaultSetup(1); % Checks Screen() mex file and unifies key names
% Screen('Preference', 'SkipSyncTests', 1);  % can't run PTB on my laptop without skipping sync tests

% Get window pointers, set background to black
[ptr.win, env.winRect] = Screen('OpenWindow', screenID, [0 0 0]);      % monitor index 0 for single monitor, 1 for second monitor

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', ptr.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Set target & fixation positions
env.winCtr = env.winRect(3:4)/2;    % get center position of monitor
stim.fix_pos = env.winCtr;          % set fixation position to center of monitor
stim.fix_X = [-param.fix_size param.fix_size 0 0];
stim.fix_Y = [0 0 -param.fix_size param.fix_size];
stim.fix_coords = [stim.fix_X; stim.fix_Y];
stim.tgt_pos{1} = env.winCtr - [param.tgt_distance 0];
stim.tgt_pos{2} = env.winCtr + [param.tgt_distance 0];



if ~useMouse
    % Initialize Eyelink. If unsuccessful, exit program.
    if EyelinkInit() ~= 1
        sca
        return;
    end

    % Give Eyelink information about graphics, do more initializations, etc.
    el = EyelinkInitDefaults(ptr.win);
    el.backgroundcolour = BlackIndex(el.window);
    el.calibrationtargetcolour = GrayIndex(el.window);
    el.foregroundcolour = WhiteIndex(el.window);
    el.msgfontcolour    = GrayIndex(el.window);
    el.imgtitlecolour   = GrayIndex(el.window);
    el.devicenumber = -1; % use all keyboards
    EyelinkUpdateDefaults(el);

    % Open a file where the Eyelink can record data
    Eyelink('openfile', [EyelinkFilename '.edf']);

    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);

    % Check calibration using drift correction
    EyelinkDoDriftCorrection(el);
end

% Press key to continue after calibration
DrawFormattedText(ptr.win, 'Look at the fixation cross, then press the space bar.', 'center', env.winCtr(2) / 4, [150 150 150]);
% Draw fixation point
Screen('DrawLines', ptr.win, stim.fix_coords, param.fix_width, param.fix_color, stim.fix_pos, 2);
Screen('Flip', ptr.win);
KbStrokeWait(-1);

% Start with 0 drift offset
env.offset = [0, 0];

% Initialize state variables
state.trialNum = 1;
state.blockNum = 1;
state.runningYN = true;

% Initialize variables for data
trialXY = [];
exptData = [];

% create an instance of the SaccadeTaskDrawer object to handle presentation of different components
% this object is instantiated with the information from param and stim, and the screen ptr
presenter = SaccadeTaskDrawer(param, stim, ptr);     
% set mask type
presenter.setMaskMethod(mask_method);
% set pattern type if using pattern masking
presenter.setPattern(pattern_type);

testtime = [];

%% Main loop
while state.runningYN
    
    % Start pretrial period -- TODO: check if it needs to be removed?
    pretrialStart = GetSecs;
    
    if ~useMouse
        % Do Drift Correction on first trial and then every 4 trials
        if state.trialNum == 1 || mod(state.trialNum, 4) == 0
            EyelinkDoDriftCorrection(el);
        end
    end
    
    pretrialRT = GetSecs - pretrialStart;
    
    % first column of trialOrder is cue dir,
    % second column is saccade/antisaccade,
    % third column is primer/no primer
    % Set cue direction for this trial (left = 0, right = 1)
    state.cueDir = expt.block(state.blockNum).trialOrder(state.trialNum, 1);        
    
    % Set saccade = 0 or antisaccade = 1 for this trial
    state.antisaccadeYN = expt.block(state.blockNum).trialOrder(state.trialNum, 2);
    
    % Set whether primer is to be presented this trial (0 = not presented, 1 = presented in target loc, 2 = presented in non-target loc)
    state.primer = expt.block(state.blockNum).trialOrder(state.trialNum, 3);
        
    % update the SaccadeTaskDrawer object with the state information (cue direction and trial type) for this trial
    presenter.setState(state);
    
    % if pattern masking, randomly generate the pattern info ahead of time
    if any(strcmp(mask_method, {'pattern', 'lexical'}))
        presenter.prepareMask;
    end

    % Flash cue for set duration definied in param
    presenter.cuePeriod;
     
    premasktime = GetSecs;
    % Present subliminal primer
    presenter.maskPeriod;
    testtime = [testtime GetSecs-premasktime];
    
    % Delay period between primer and target
    trial_delay = param.trial_delay_min + rand*(param.trial_delay_max - param.trial_delay_min);
    for ff = 1:trial_delay
        % draw target boxes
        presenter.drawTargetBoxes;
        % draw fixation point
        presenter.drawFP;
        presenter.present;
    end
    
    % Start a timer to measure RT until saccade lands on target
    state.saccadeLandedYN = false;
    state.trialOverYN = false;
    trialStart = GetSecs;
    
    if ~useMouse
        % Start recording eye tracking
        Eyelink('StartRecording');
    else
        SetMouse(stim.fix_pos(1), stim.fix_pos(2));
    end
    
    while ~state.trialOverYN
        
        
        if ~useMouse
            % Get eye data
            evt = Eyelink('NewestFloatSample');
            ETcoords.x = evt.gx(2);
            ETcoords.y = evt.gy(2);
        else
            % if testing without eyetracking, use cursor position
            [ETcoords.x, ETcoords.y, ~] = GetMouse;
        end
        
        % Draw target boxes
        presenter.drawTargetBoxes;
       
        % Draw fixation point
        presenter.drawFP;
                
        % Draw target based on cue direction
        presenter.drawTarget;
        
        % Draw eye tracking (only for testing or eventually change code to
        % have 2nd monitor for observer)
        % presenter.drawEyeTracker(ETcoords);
     
        % Use option 'dontclear' to allow drawing feedback on top
        presenter.present(1);     % (call with any input to preserve eyetracking trace on screen)
        
        % Determine if saccade has landed in target region, if so record time landed
        if ~state.saccadeLandedYN
            if state.antisaccadeYN
                % If they should antisaccade, reverse the cue direction to get the target
                if IsInRect(ETcoords.x, ETcoords.y, CenterRectOnPoint(param.tgt_tolerance * [0 0 1 1], stim.tgt_pos{~state.cueDir+1}(1), stim.tgt_pos{~state.cueDir+1}(2)))
                    state.saccadeLandedYN = true;
                    landedTime = GetSecs;
                end
            else
                % If they should saccade, match cue direction
                if IsInRect(ETcoords.x, ETcoords.y, CenterRectOnPoint(param.tgt_tolerance * [0 0 1 1], stim.tgt_pos{state.cueDir+1}(1), stim.tgt_pos{state.cueDir+1}(2)))
                    state.saccadeLandedYN = true;
                    landedTime = GetSecs;
                end
            end
        end
        
        % If saccade has landed, give visual feedback
        if state.saccadeLandedYN && (GetSecs - landedTime > param.tgt_time)
            state.trialOverYN = true;
            
            presenter.drawTargetBoxes(1);   % call with input arg to indicate saccade has landed and to provide visual feedback on target box
            
            presenter.present;
            
            pause(0.5);
            
        end
        
        % Save x/y data throughout the trial
        trialXY = [trialXY; state.blockNum state.trialNum ETcoords.x ETcoords.y];
        
        % Check if ESC or Q have been pressed, and stop early if so
        [~, ~, keyCode] = KbCheck(-1);
        
        if keyCode(KbName('ESCAPE')) || keyCode(KbName('q'))
            % Clear screen
            sca
            
            % Save all workspace variables
            save(data_filename)
            
            if ~useMouse
            % Shut down eye tracking
                Eyelink('StopRecording');
                Eyelink('CloseFile');
                status = Eyelink('ReceiveFile', EyelinkFilename, fullfile([data_filename '.edf']));
                disp(status)
                Eyelink('Shutdown')
            end

            % Close audio device
            % PsychPortAudio('Close', env.audio_handle);
            return
        end
    end
    
    % Get reaction time
    trialRT = landedTime - trialStart;
    
    if ~useMouse
        Eyelink('StopRecording');
    end
    
    % Save trial data
    exptData = [exptData; state.blockNum state.trialNum state.cueDir state.antisaccadeYN state.primer pretrialRT trialRT];
    
    % Check if there are still more trials to go in this block
    state.trialNum = state.trialNum + 1;
    if state.trialNum > expt.block(state.blockNum).numTrials
        % Offer a break between blocks
        if state.blockNum < expt.numBlocks
            DrawFormattedText(ptr.win, 'You may take a break now.\nPress any key to continue.', 'center', 'center', [150 150 150]);
            Screen('Flip', ptr.win);
            KbStrokeWait(-1);
        end
        
        state.blockNum = state.blockNum + 1;
        
        % Check if there are more blocks
        if state.blockNum > expt.numBlocks
            state.runningYN = false;
        else
            state.trialNum = 1;
        end
    end
    
    
end

%% Clean up

% Clear screen
sca

% Save all workspace variables
try cd('data');
catch
    mkdir('data');
    cd('data');
end
save(data_filename);
cd(fullpath);


if ~useMouse
    % Shut down eye tracking
    Eyelink('CloseFile');
    status = Eyelink('ReceiveFile', EyelinkFilename, fullfile([data_filename '.edf']));
    disp(status)
    Eyelink('Shutdown')
end

% Close audio device
% PsychPortAudio('Close', env.audio_handle);
