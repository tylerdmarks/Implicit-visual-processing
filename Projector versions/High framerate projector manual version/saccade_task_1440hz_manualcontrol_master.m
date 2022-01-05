
% Written for 1440hz display
% Master script for the saccade task on the propixx projector
% Last updated by TDM Jan 2022

%% Settings
clear
KbName('UnifyKeyNames');        % fixes an error calling KbName('ESCAPE'), might be a Windows thing

% some flags
useMouse = 0;           % Manual cursor implementation for testing, use mouse = 1 instead of gaze
screenID = 0;           % screenID = 0 for laptop alone, screenID = 1 for laptop on dual monitor setup, screenID = 2 for second monitor 
display_tracker = 0;    % display eyetracking feedback on the screen for the user
test_flag = 0;          % if testing on a display other than the propixx projector

% set masking method
mask_method = 'metacontrast';
% set pattern if using pattern masking
pattern_type = 'disc';
% File name, change for each new participant       'subjectnumber_nameoftask_maskmethod_date'
ID = 'S008_saccadetask_meta_211206';   

% set up save directory and save file for experiment data
fullpath = ('C:\Experiment Data\Implicit visual processing');            % operational folder for this computer

data_filename = sprintf('%s.mat', ID);

% set up timing 
% set min == max to restrict timing to a single value
fr = 1440;                       % framerate and highspeed mode
cue_duration = 0.6:0.05:1.0;       % seconds, vector of possible durations of initial fixation + cue (randomized)
% adjust primer duration based on participant's calibration results
primer_duration_min = 0.024;    % seconds, min duration of primer
primer_duration_max = 0.024;    % seconds, max duration of primer
% adjust ISI duration based on participant's calibration results
ISI_min = 0.010;                % seconds, minimum duration of interval between primer and mask
ISI_max = 0.010;                % seconds, max duration of "
mask_duration = 0.070;      % seconds, duration of mask
trial_delay_min = 0.05;      % seconds, min duration of delay in between primer/mask and target
trial_delay_max = 0.05;      % seconds, max duratin of delay in between primer/mask and target

% filename for eyelink stuff 
% THIS MUST BE VERY SHORT
EyelinkFilename = 'test';

% Fixation parameters
param.fix_size = 16; % pixels, cross
param.fix_width = 3; % pixels, line width
param.fix_color = [150 150 150]; % usual color of fixation (gray)
param.fix_tolerance = 100; % pixels, square around fixation
param.fix_samples = 200; % number of pre-trial gaze samples (to check if fixating correctly)

% saccade/antisaccade cue parameters
param.cue_duration = ceil(cue_duration/(1/fr));     % frames, durations of fixation + cue
param.cue_size = 3*param.fix_size;                          % pixels, size of cue
param.cue_width = param.fix_width;                          % pixels, width of cue

% Target parameters
param.tgt_distance = 400; % pixels, how far targets are from fixation (symmetric)
param.tgt_size = 40; % pixels, square, how large target is
param.tgt_color = [150 150 150]; % color of target (gray). Also frame color.
param.tgt_frame_size = 150; % pixels, square, size of frame
param.tgt_frame_width = 2; % pixels, line width of frame
param.tgt_time = 0.5; % time in seconds to keep recording eye movements after landing on target
param.tgt_tolerance = 150; % pixels, currently same size as frame

% Primer and mask parameters (backward masking of target primer)
param.prm_color = [150 150 150]; % color of primer and mask (gray).
param.prm_size = 40; % pixels, square, how large the primer is (same size as target).
param.mask_size = 120; % pixels, square, how large the mask is
param.mask_width = 40; % pixels, line width of mask, should spatially match border of primer
param.prm_duration_min = ceil(primer_duration_min/(1/fr)); % frames, min duration of primer presentation 
param.prm_duration_max = ceil(primer_duration_max/(1/fr)); % frames, max duration of primer presentation 
param.ISI_min = ceil(ISI_min/(1/fr));  % frames, min duration in between primer and mask
param.ISI_max = ceil(ISI_max/(1/fr));  % frames, max duration in between primer and mask
param.mask_duration = ceil(mask_duration/(1/fr)); % frames, duration of mask presentation 
param.trial_delay_min = ceil(trial_delay_min/(1/fr));   % frames, min duration of delay between primer and target
param.trial_delay_max = ceil(trial_delay_max/(1/fr));   % frames, max duration of delay between primer and target

% Eye tracker drawing parameters
param.tracker_size = 10; % pixels, square

% Generate trial order using written presets
expt = generateSaccadeTaskTrials('Exp1');        % test_preset1 = testing preset

%% Initialize

% Shift focus to command window so typing doesn't go to code editor if something
% happens to break
commandwindow
HideCursor;

% initialize propixx projector controller
% projector is initialized in normal display mode
ppx = propixxController();
% can't run PTB on laptop without skipping sync tests
Screen('Preference', 'SkipSyncTests', 1);  
[ptr, winrect] = ppx.initialize(screenID);

% if just testing, initialize PTB on its own
if test_flag
    AssertOpenGL;
    KbName('UnifyKeyNames');
    [ptr,winrect] = Screen('OpenWindow', screenID, 0);
end

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', ptr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Set target & fixation positions
env.displaySize = winrect(3:4);
env.winCtr = env.displaySize/2;    % get center position of the screen
ppx.env = env;
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
    el = EyelinkInitDefaults(ptr);
    el.backgroundcolour = BlackIndex(el.window);
    el.calibrationtargetcolour = GrayIndex(el.window);
    el.foregroundcolour = WhiteIndex(el.window);
    el.msgfontcolour    = GrayIndex(el.window);
    el.imgtitlecolour   = GrayIndex(el.window);
    el.devicenumber = -1; % use all keyboards
    EyelinkUpdateDefaults(el);

    % Open a file where the Eyelink can record data
    Eyelink('openfile', [EyelinkFilename '.edf']);
    
    % Calibrate the eyetracker and do drift correction
    EyelinkCalibrate(el);
end


% Start with 0 drift offset
env.offset = [0, 0];

% Initialize state variables
state.trialNum = 1;
state.blockNum = 1;
state.runningYN = true;

% Initialize variables for ET data (but this doesn't really work, use the eyetracking data directly from Eyelink
ETdata = struct();
for bb = 1:expt.numBlocks
    ETdata(bb).trialXY = cell(1, expt.block(bb).numTrials);
%     ETdata(bb).pretrialXY = cell(1, expt.block(bb).numTrials);
    ETdata(bb).primerXY = cell(1, expt.block(bb).numTrials);
    ETdata(bb).fixXY = cell(1, expt.block(bb).numTrials);
end
exptData = [];

% create an instance of the SaccadeTaskDrawer object to handle presentation of different components
% this object is instantiated with the information from param and stim, and the screen ptr
presenter = PropixxSaccadeTaskDrawerManual(param, stim, ptr, env);     
% set mask type
presenter.mask_method = mask_method;
% set pattern type if using pattern masking
presenter.pattern_type = pattern_type;

% set projector mode to high speed
ppx.setMode(fr);         

% timing measurements
timing.fix = [];
timing.primer = [];
timing.ISI = [];
timing.mask = [];
timing.delay = [];
timing.target = [];
timing.trial = [];

% Press key to continue after calibration
% for ii = 1:12
%     % tell presenter which frame we're on for drawing FP
%     presenter.setClock(ii);
%     
%     % convert coords for text (don't have a method for this and I'm lazy)
%     color = presenter.selectColorChannel(ii);
%     newctr = presenter.convertToQuadrant(env.winCtr, env.displaySize, ii);
%     
%     DrawFormattedText(ptr, 'Look at the fixation cross, then press the space bar.', newctr(1) - env.displaySize(1)/8, newctr(2) - env.displaySize(2)/8, color);
%     % Draw fixation point
%     presenter.drawFP;
%     
%     %flips only on last loop iteration
%     presenter.present();
% end
% KbStrokeWait(-1);

% initialize clock that counts 1:1440 to track packet position and flip every 12
packet_clock = 1;     

preEXPstart = GetSecs;

prev_time = -1;
%% Main loop
while state.runningYN
    %% DRIFT CORRECTION 
    if ~useMouse
        % Do Drift Correction on first trial and then every 10 trials
        if mod(state.trialNum, 10) == 1
            ppx.setMode(120);
            EyelinkDoDriftCorrection(el);
            ppx.setMode(fr);
        end
    else
        if mod(state.trialNum, 10) == 1
            fprintf('%d\n', state.trialNum);
        end
    end
    
    %% BLOCK TITLE CARD
    if state.trialNum == 1
        while true
            % tell presenter which frame we're on for drawing FP
            presenter.setClock(packet_clock);

            % convert coords for text (don't have a method for this and I'm lazy)
            color = presenter.selectColorChannel(presenter.packet_frame);
            newctr = presenter.convertToQuadrant(env.winCtr, env.displaySize, presenter.packet_frame);
            DrawFormattedText(ptr, sprintf('Block %d', state.blockNum), newctr(1) - env.displaySize(1)/40, newctr(2) - env.displaySize(2)/6, color);
            DrawFormattedText(ptr, 'Look at the fixation cross, then press the space bar.', newctr(1) - env.displaySize(1)/8, newctr(2) - env.displaySize(2)/8, color);
            % Draw fixation point
            presenter.drawFP;

            %flips only on last loop iteration
            presenter.present();
            % increment clock
            packet_clock = packet_clock+1;

            [~, ~, keycode, ~] = KbCheck(-1);
            if keycode(KbName('Space'))
                break
            end
        end
    end
    
    %% SET STATE INFO
    
    % first column of trialOrder is cue dir (left = 0, right = 1)
    % second column is prosaccade/antisaccade (0 = prosaccade, 1 = antisaccade)
    % third column is primer/no primer (no primer = 0, primer in target loc = 1, primer in non-target loc = 2)
    % Set cue direction for this trial (left = 0, right = 1)
    state.cueDir = expt.block(state.blockNum).trialOrder(state.trialNum, 1);        
    
    % Set saccade = 0 or antisaccade = 1 for this trial
    state.antisaccadeYN = expt.block(state.blockNum).trialOrder(state.trialNum, 2);
    
    % Set whether primer is to be presented this trial (0 = not presented, 1 = presented in target loc, 2 = presented in non-target loc)
    state.primer = expt.block(state.blockNum).trialOrder(state.trialNum, 3);
        
    % update the SaccadeTaskDrawer object with the state information (cue direction and trial type) for this trial
    presenter.state = state;
    
    % if pattern masking, randomly generate the pattern info ahead of time
    if any(strcmp(mask_method, {'pattern', 'lexical'}))
        presenter.prepareMask;
    end
    
    %% START EYETRACKING FOR THIS TRIAL AND LOG TRIAL START TIME
    
    if ~useMouse
        % Start recording eye tracking
        Eyelink('StartRecording');
    end
    
    pretrialstart = GetSecs;

    %% INITIAL FIXATION
    
    % randomize fixation duration
    rand_idx = randi(length(param.cue_duration));
    curr_cue_duration = param.cue_duration(rand_idx);
    % log fix start time
    prefixtime = GetSecs;
    % present fixation + cue
    for ff = 1:curr_cue_duration      
        if ~useMouse
            % Get eye data
            evt = Eyelink('NewestFloatSample');
            % only collect data if there is a new sample (time stamp doesn't match previous time stamp)
            if ~(evt.time == prev_time)
                ETcoords = getETdata(evt);
                prev_time = evt.time;
                ETdata(state.blockNum).fixXY{state.trialNum} = [ETdata(state.blockNum).fixXY{state.trialNum}; ETcoords.x ETcoords.y];
            end
        else
            % if testing without eyetracking, use cursor position
            [ETcoords.x, ETcoords.y, ~] = GetMouse;
        end
        % tell the presenter which frame we're on so the drawers know where to draw
        presenter.setClock(packet_clock);

        % draw stuff
        presenter.drawFP;       % fixation point
        presenter.drawTargetBoxes;      % target regions
        presenter.drawCue;      % circle around fixation point (doesn't mean anything right now)
      
        % only flips if global packet clock is a multiple of 12
        presenter.present;

        % increment global clock
        packet_clock = packet_clock+1;

    end
    % store fix time for current trial
    timing.fix = [timing.fix GetSecs-prefixtime];
     
    %% SUBLIMINAL PRIMER
    % get primer duration
    curr_prm_duration = ceil(param.prm_duration_min + rand*(param.prm_duration_max - param.prm_duration_min));
    % log primer start time
    preprimertime = GetSecs;
    % present primer
    for ff = 1:curr_prm_duration   
        if ~useMouse
            % Get eye data
            evt = Eyelink('NewestFloatSample');
            % only collect data if there is a new sample (time stamp doesn't match previous time stamp)
            if ~(evt.time == prev_time)
                ETcoords = getETdata(evt);
                prev_time = evt.time;
                ETdata(state.blockNum).primerXY{state.trialNum} = [ETdata(state.blockNum).primerXY{state.trialNum}; ETcoords.x ETcoords.y];
            end
        else
            % if testing without eyetracking, use cursor position
            [ETcoords.x, ETcoords.y, ~] = GetMouse;
        end
        % tell the presenter which frame we're on
        presenter.setClock(packet_clock);

        % Draw target boxes
        presenter.drawTargetBoxes;
        % Draw fixation point (if not using lexical mask)
        if ~strcmp(presenter.mask_method, 'lexical')
            presenter.drawFP;
        end
        % Draw cue
        presenter.drawCue;
        % Draw primer
        presenter.drawPrimer;

        % only flips if global packet clock is a multiple of 12
        presenter.present;

        packet_clock = packet_clock+1;
    end
    
    % log primer duration
    primertime = GetSecs-preprimertime;
    timing.primer = [timing.primer primertime];

    %% INTERSTIMULUS INTERVAL

    % get ISI duration
    curr_ISI = ceil(param.ISI_min + rand*(param.ISI_max-param.ISI_min));
    % log ISI start time
    preISItime = GetSecs;
    % present ISI
    for ff = 1:curr_ISI
        if ~useMouse
            % Get eye data
            evt = Eyelink('NewestFloatSample');
            % only collect data if there is a new sample (time stamp doesn't match previous time stamp)
            if ~(evt.time == prev_time)
                ETcoords = getETdata(evt);
                prev_time = evt.time;
                ETdata(state.blockNum).primerXY{state.trialNum} = [ETdata(state.blockNum).primerXY{state.trialNum}; ETcoords.x ETcoords.y];
            end
        else
            % if testing without eyetracking, use cursor position
            [ETcoords.x, ETcoords.y, ~] = GetMouse;
        end
        
        % tell the presenter which frame we're on
        presenter.setClock(packet_clock);

        % Draw target boxes
        presenter.drawTargetBoxes;
        % Draw fixation point (if not using lexical mask)
        if ~strcmp(presenter.mask_method, 'lexical')
            presenter.drawFP;
        end
        % Draw cue
        presenter.drawCue;
        % only flips if global packet clock is a multiple of 12
        presenter.present;

        packet_clock = packet_clock+1;
    end
    
    ISItime = GetSecs-preISItime;
    timing.ISI = [timing.ISI ISItime];   

    %% BACKWARD MASK
    % get mask duration
    curr_mask_duration = param.mask_duration;
    % log mask start time
    premasktime = GetSecs;
    % present mask
    for ff = 1:curr_mask_duration   
        if ~useMouse
            % Get eye data
            evt = Eyelink('NewestFloatSample');
            % only collect data if there is a new sample (time stamp doesn't match previous time stamp)
            if ~(evt.time == prev_time)
                ETcoords = getETdata(evt);
                prev_time = evt.time;
                ETdata(state.blockNum).primerXY{state.trialNum} = [ETdata(state.blockNum).primerXY{state.trialNum}; ETcoords.x ETcoords.y];
            end
        else
            % if testing without eyetracking, use cursor position
            [ETcoords.x, ETcoords.y, ~] = GetMouse;
        end
        
        % tell the presenter which frame we're on
        presenter.setClock(packet_clock);    

        % Draw target boxes
        presenter.drawTargetBoxes;
        % Draw fixation point (if not using lexical mask)
        if ~strcmp(presenter.mask_method, 'lexical')
            presenter.drawFP;
        end 
        % Draw mask
        presenter.drawMask;
        % Draw cue
        presenter.drawCue;
        % only flips if global packet clock is a multiple of 12
        presenter.present;

        packet_clock = packet_clock+1;
    end
    % log mask time
    masktime = GetSecs-premasktime;
    timing.mask = [timing.mask masktime];
    
    %% DELAY
    
    if useMouse == 1
        SetMouse(stim.fix_pos(1), stim.fix_pos(2));
    end
    
    predelaytime = GetSecs;
    curr_trial_delay = ceil(param.trial_delay_min + rand*(param.trial_delay_max - param.trial_delay_min));
    
    for ff = 1:curr_trial_delay
        
        if ~useMouse
            % Get eye data
            evt = Eyelink('NewestFloatSample');
            if ~(evt.time == prev_time)
                ETcoords = getETdata(evt);
                prev_time = evt.time;
                ETdata(state.blockNum).trialXY{state.trialNum} = [ETdata(state.blockNum).trialXY{state.trialNum}; ETcoords.x ETcoords.y];
            end
        else
            % if testing without eyetracking, use cursor position
            [ETcoords.x, ETcoords.y, ~] = GetMouse;
        end
        
        % tell the presenter which frame we're on
        presenter.setClock(packet_clock);    

        % Draw target boxes
        presenter.drawTargetBoxes;
        % Draw fixation point 
        presenter.drawFP;
        % Draw cue
        presenter.drawCue;
        % Draw tracker
        if display_tracker == 1
            presenter.drawEyeTracker(ETcoords);
        end

        % only flips if global packet clock is a multiple of 12
        presenter.present;

        packet_clock = packet_clock+1;   
    end
    
    timing.delay = [timing.delay GetSecs-predelaytime];
    
    %% SACCADE PERIOD
    
    % Start a timer to measure RT until saccade lands on target
    state.saccadeLandedYN = false;
    state.trialOverYN = false;
    trialStart = GetSecs;
   
    % saccade period loop
    while ~state.trialOverYN
        
        if ~useMouse
            % Get eye data
            evt = Eyelink('NewestFloatSample');
            % only collect data if there is a new sample (time stamp doesn't match previous time stamp)
            if ~(evt.time == prev_time)
                ETcoords = getETdata(evt);
                prev_time = evt.time;
                ETdata(state.blockNum).trialXY{state.trialNum} = [ETdata(state.blockNum).trialXY{state.trialNum}; ETcoords.x ETcoords.y];
            end
        else
            % if testing without eyetracking, use cursor position
            [ETcoords.x, ETcoords.y, ~] = GetMouse;
        end

        % Determine if saccade has landed in target region, if so record time landed
        if ~state.saccadeLandedYN
            if ~state.antisaccadeYN        % if saccade trial
                correct_pos = state.cueDir;
            else                           % if antisaccade trial
                correct_pos = ~state.cueDir;
            end
            if IsInRect(ETcoords.x, ETcoords.y, CenterRectOnPoint(param.tgt_tolerance * [0 0 1 1], stim.tgt_pos{correct_pos+1}(1), stim.tgt_pos{correct_pos+1}(2)))
        
                state.saccadeLandedYN = true;
                landedTime = GetSecs;
            end
        end

       % If saccade has landed, give visual feedback
        if state.saccadeLandedYN && (GetSecs - landedTime > param.tgt_time)
            state.trialOverYN = true;
            
            for ff = 1:1440         % for 1 second
                if ~useMouse
                    % Get eye data
                    evt = Eyelink('NewestFloatSample');
                    % only collect data if there is a new sample (time stamp doesn't match previous time stamp)
                    if ~(evt.time == prev_time)
                        ETcoords = getETdata(evt);
                        prev_time = evt.time;
                        ETdata(state.blockNum).trialXY{state.trialNum} = [ETdata(state.blockNum).trialXY{state.trialNum}; ETcoords.x ETcoords.y];
                    end
                end
                presenter.setClock(packet_clock);
                presenter.drawTarget;
                presenter.drawTargetBoxes(1);   % call with input arg == 1 to indicate saccade has landed and to provide visual feedback 
                if display_tracker == 1
                    presenter.drawEyeTracker(ETcoords);
                end
                presenter.present;
                packet_clock = packet_clock + 1;
            end
        else
            % tell the presenter which frame we're on
            presenter.setClock(packet_clock);
            % Draw target
            presenter.drawTarget;
            % Draw target frames
            presenter.drawTargetBoxes;

            if display_tracker == 1
                presenter.drawEyeTracker(ETcoords);
            end
            % only flips if global packet clock is a multiple of 12
            presenter.present;           % call with input arg to preserve trace on screen (or not? dunno yet how this works)
        
            packet_clock = packet_clock+1;
        end

        % Check if ESC or Q have been pressed, and stop early if so
        [~, ~, keyCode] = KbCheck(-1);
        
        if keyCode(KbName('ESCAPE')) || keyCode(KbName('q'))
            % Clear screen
            sca
            
            % Save all workspace variables
            save(data_filename)
            
            timing.target = [timing.target GetSecs-trialStart];
            timing.trial = [timing.trial GetSecs-pretrialstart];
            
            if ~useMouse
            % Shut down eye tracking
                Eyelink('StopRecording');
                Eyelink('CloseFile');
                status = Eyelink('ReceiveFile', EyelinkFilename, fullfile([ID '.edf']));
                disp(status)
                Eyelink('Shutdown')
            end

            % reset projector (turn off fast display)
            ppx.shutdown;

            return
        end
    end
    
    timing.target = [timing.target GetSecs-trialStart];
    timing.trial = [timing.trial GetSecs-pretrialstart];
       
    if ~useMouse
        Eyelink('StopRecording');
    end
    
    % Get reaction time
    trialRT = landedTime - trialStart;
    
    % Save trial data
    pretrialRT = 0;             % just preserving this so it doesn't screw up my analysis code
    exptData = [exptData; state.blockNum state.trialNum state.cueDir state.antisaccadeYN state.primer pretrialRT trialRT];
    
    % Check if there are still more trials to go in this block
    state.trialNum = state.trialNum + 1;
    if state.trialNum > expt.block(state.blockNum).numTrials
        % Offer a break between blocks
        if state.blockNum < expt.numBlocks
            ppx.setMode(120);
            DrawFormattedText(ptr, 'You may take a break now.\nPress any key to continue.', 'center', 'center', [150 150 150]);
            Screen('Flip', ptr);
            KbStrokeWait(-1);
        end
             
        state.blockNum = state.blockNum + 1;
        
        % Check if there are more blocks
        if state.blockNum > expt.numBlocks
            state.runningYN = false;
        else
            state.trialNum = 1;
            if ~useMouse
                ppx.setMode(120);
                EyelinkCalibrate(el);
                ppx.setMode(fr);
            else
                fprintf('Calibration check goes here\n');
                ppx.setMode(fr);
            end
        end
    end
    
end

EXPtime = GetSecs - preEXPstart;

%disengage fast mode on projector
ppx.shutdown();

%% Clean up
% Clear screen
sca

if ~useMouse
    % Shut down eye tracking
    Eyelink('CloseFile');
    status = Eyelink('ReceiveFile', EyelinkFilename, fullfile([ID '.edf']));
    disp(status)
    Eyelink('Shutdown')
end

% Save all workspace variables
try cd('data');
catch
    mkdir('data');
    cd('data');
end
save(data_filename);
cd(fullpath);


