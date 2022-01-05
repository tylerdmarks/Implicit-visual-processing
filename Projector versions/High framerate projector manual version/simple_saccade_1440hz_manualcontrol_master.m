
% Written for 1440hz display

%% Settings
clear
KbName('UnifyKeyNames');        % fixes an error calling KbName('ESCAPE'), might be a Windows thing

useMouse = 0;           % Manual cursor implementation for testing (eyelink dummy mode not working), use mouse = 1 instead of gaze
screenID = 0;           % screenID = 0 for laptop alone, screenID = 1 for laptop on dual monitor setup, screenID = 2 for second monitor 
display_tracker = 0;

mask_method = 'metacontrast';
pattern_type = 'disc';
% Change for each new participant
ID = 'AC_simplesaccade_meta_211117';

% set up save directory and save file for experiment data
fullpath = ('C:\Experiment Data\Implicit visual processing\Simple saccade');            % operational folder for this computer

data_filename = sprintf('%s.mat', ID);

% set up timing 
fr = 1440;                       % framerate and highspeed mode
fix_duration_min = 1;       % seconds, min duration of initial fixation
fix_duration_max = 1.5;       % seconds, max duration of initial fixation
primer_duration = 0.010;    % seconds, duration of primer
% set ISI_min == ISI_max for constant ISI
ISI_min = 0.010;                % seconds, minimum duration of interval between primer and mask
ISI_max = 0.010;                % seconds, max duration of "
mask_duration = 0.06;      % seconds, duration of mask

% filename for eyelink stuff
EyelinkFilename = 'test';

% Fixation parameters
param.fix_size = 20; % pixels, cross
param.fix_width = 4; % pixels, line width
param.fix_color = [150 150 150]; % usual color of fixation (gray)
param.fix_tolerance = 100; % pixels, square around fixation
param.fix_samples = 200; % number of pre-trial gaze samples (to check if fixating correctly)
param.fix_duration_min = ceil(fix_duration_min/(1/fr));     % frames, min duration of initial fixation
param.fix_duration_max = ceil(fix_duration_max/(1/fr));     % frames, max duration of initial fixation

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
param.prm_duration = ceil(primer_duration/(1/fr)); % frames, duration of primer presentation 
param.ISI_min = ceil(ISI_min/(1/fr));  % frames, min duration in between primer and mask
param.ISI_max = ceil(ISI_max/(1/fr));  % frames, max duration in between primer and mask
param.mask_duration = ceil(mask_duration/(1/fr)); % frames, duration of mask presentation 

% Eye tracker drawing parameters
param.tracker_color = [255 255 255]; % color for eye tracking location drawing
param.tracker_size = 10; % pixels, square

% Generate trial order using written presets
expt = generateSaccadeTaskTrials('simple_saccade');        % test_preset1 = testing preset

%% Initialize

% Shift focus to command window so typing doesn't go to code editor if something
% happens to break
commandwindow
HideCursor;

% initialize propixx
ppx = propixxControllerManual();
% projector is initialized in normal display mode
Screen('Preference', 'SkipSyncTests', 1);  % can't run PTB on my laptop without skipping sync tests

[ptr, winrect] = ppx.initialize(screenID);


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

% Initialize variables for data
ETdata = struct();
for bb = 1:expt.numBlocks
    ETdata(bb).trialXY = cell(1, expt.block(bb).numTrials);
    ETdata(bb).pretrialXY = cell(1, expt.block(bb).numTrials);
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

primertime = [];
ISItime = [];
masktime = [];

% Press key to continue after calibration
for ii = 1:12
    % tell presenter which frame we're on for drawing FP
    presenter.setClock(ii);
    
    % convert coords for text (don't have a method for this and I'm lazy)
    color = presenter.selectColorChannel(ii);
    newctr = presenter.convertToQuadrant(env.winCtr, env.displaySize, ii);
    
    DrawFormattedText(ptr, 'Look at the fixation cross, then press the space bar.', newctr(1) - env.displaySize(1)/8, newctr(2) - env.displaySize(2)/8, color);
    % Draw fixation point
    presenter.drawFP;
    
    %flips only on last loop iteration
    presenter.present();
end
KbStrokeWait(-1);

packet_clock = 1;           % clock that counts 1:1440 to track packet position and flip every 12

%% Main loop
while state.runningYN
    
    % Start pretrial period -- TODO: check if it needs to be removed?
    pretrialStart = GetSecs;
    
    if ~useMouse
        % Do Drift Correction on first trial and then every n trials
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
    presenter.state = state;
    
    % if pattern masking, randomly generate the pattern info ahead of time
    if any(strcmp(mask_method, {'pattern', 'lexical'}))
        presenter.prepareMask;
    end
    
    prefixtime = GetSecs;

    % INITIAL FIXATION
    
    curr_fix_duration = ceil(param.fix_duration_min + rand*(param.fix_duration_max - param.fix_duration_min));
    
    for ff = 1:curr_fix_duration            
        % tell the presenter which frame we're on so the drawers know where to draw
        presenter.setClock(packet_clock);

        % draw stuff
        presenter.drawFP;
        presenter.drawTargetBoxes;
      
        % only flips if global packet clock is a multiple of 12
        presenter.present;
%         fprintf('curr_clock = %d, flip_flag = %d\n', cc, f);

        % increment global clock
        packet_clock = packet_clock+1;

    end
    
    fixtime = GetSecs-prefixtime;
     
    preprimertime = GetSecs;
    
    % PRESENT SUBLIMINAL PRIMER
    for ff = 1:param.prm_duration   
        % tell the presenter which frame we're on
        presenter.setClock(packet_clock);

        % Draw target boxes
        presenter.drawTargetBoxes;
        % Draw fixation point (if not using lexical mask)
        if ~strcmp(presenter.mask_method, 'lexical')
            presenter.drawFP;
        end
        % Draw primer
        presenter.drawPrimer;


        % only flips if global packet clock is a multiple of 12
        [f, cc] = presenter.present;
%         fprintf('curr_clock = %d, flip_flag = %d\n', cc, f);

        packet_clock = packet_clock+1;
    end
    
    primertime = [primertime GetSecs-preprimertime];

    % INTERSTIMULUS INTERVAL

    % determine number of frames for ISI

    ISI = ceil((param.ISI_max-param.ISI_min)*rand + param.ISI_min);

    preISItime = GetSecs;
    
    for ff = 1:ISI
        % tell the presenter which frame we're on
        presenter.setClock(packet_clock);

        % Draw target boxes
        presenter.drawTargetBoxes;
        % Draw fixation point (if not using lexical mask)
        if ~strcmp(presenter.mask_method, 'lexical')
            presenter.drawFP;
        end

        % only flips if global packet clock is a multiple of 12
        presenter.present;

        packet_clock = packet_clock+1;
    end
    
    ISItime = [ISItime GetSecs-preISItime];
    
    premasktime = GetSecs;

    % BACKWARD MASK
    for ff = 1:param.mask_duration    
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

        % only flips if global packet clock is a multiple of 12
        presenter.present;

        packet_clock = packet_clock+1;
    end

    masktime = [masktime GetSecs-premasktime];
    
    
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
    
    % trial loop
    while ~state.trialOverYN
             
        if ~useMouse
            % Get eye data
            evt = Eyelink('NewestFloatSample');
            if evt.gx(2) > 0
                ETcoords.x = evt.gx(2);
                ETcoords.y = evt.gy(2);
            else 
                ETcoords.x = evt.gx(1);
                ETcoords.y = evt.gy(1);
            end
        else
            % if testing without eyetracking, use cursor position
            [ETcoords.x, ETcoords.y, ~] = GetMouse;
        end

        % Determine if saccade has landed in target region, if so record time landed
        if ~state.saccadeLandedYN
            % saccade is considered landed in either location
            if IsInRect(ETcoords.x, ETcoords.y, CenterRectOnPoint(param.tgt_tolerance * [0 0 1 1], stim.tgt_pos{~state.cueDir+1}(1), stim.tgt_pos{~state.cueDir+1}(2)))...
                    || IsInRect(ETcoords.x, ETcoords.y, CenterRectOnPoint(param.tgt_tolerance * [0 0 1 1], stim.tgt_pos{state.cueDir+1}(1), stim.tgt_pos{state.cueDir+1}(2)))
        
                state.saccadeLandedYN = true;
                landedTime = GetSecs;
            end
        end   
        
        % If saccade has landed, give visual feedback
        if state.saccadeLandedYN && (GetSecs - landedTime > param.tgt_time)
            state.trialOverYN = true;
            
            for ff = 1:1440         % for 1 second
                presenter.setClock(packet_clock);
%                 presenter.drawFP;
                presenter.drawTargetBoxes(2);   % call with input arg == 2 to indicate saccade has landed and to provide visual feedback for both target boxes
                if display_tracker == 1
                    presenter.drawEyeTracker(ETcoords);
                end
                presenter.present;
                packet_clock = packet_clock + 1;
            end
        else
            % tell the presenter which frame we're on
            presenter.setClock(packet_clock);
        
            % Draw fixation point
%             presenter.drawFP;
            % Draw target frames
            presenter.drawTargetBoxes;

            % Draw eye tracking (only for testing or eventually change code to
            % have 2nd monitor for observer)
            if display_tracker == 1
                presenter.drawEyeTracker(ETcoords);
            end
            % only flips if global packet clock is a multiple of 12
            presenter.present;           % call with input arg to preserve trace on screen (or not? dunno yet how this works)
        
            packet_clock = packet_clock+1;
        end

        % Save x/y data throughout the trial
        ETdata(state.blockNum).trialXY{state.trialNum} = [ETdata(state.blockNum).trialXY{state.trialNum}; ETcoords.x ETcoords.y];

        
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
                status = Eyelink('ReceiveFile', EyelinkFilename, fullfile([ID '.edf']));
                disp(status)
                Eyelink('Shutdown')
            end

            % reset projector (turn off fast display)
            ppx.shutdown;

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

%disengage fast mode on projector
ppx.shutdown();

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
    status = Eyelink('ReceiveFile', EyelinkFilename, fullfile([ID '.edf']));
    disp(status)
    Eyelink('Shutdown')
end

