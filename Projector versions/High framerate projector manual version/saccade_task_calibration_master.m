
% Written for 1440hz display
% Prime duration calibration task
% Last updated by TDM Jan 2022

%% Settings
clear
KbName('UnifyKeyNames');        % fixes an error calling KbName('ESCAPE'), might be a Windows thing

screenID = 0;           % screenID = 0 for laptop alone, screenID = 1 for laptop on dual monitor setup, screenID = 2 for second monitor 
test_flag = 0;

mask_method = 'metacontrast';
pattern_type = 'disc';
% Change for each new participant
ID = 'test';     

% set up save directory and save file for experiment data
fullpath = ('C:\Experiment Data\Implicit visual processing');            % operational folder for this computer

data_filename = sprintf('%s.mat', ID);

% set up timing 
fr = 1440;                       % framerate and highspeed mode
fix_duration = 0.6:0.05:1.0;       % seconds, vector of possible durations of initial fixation + cue (randomized)
% adjust primer duration based on participant's calibration results
primer_duration = 0.005;    % seconds, duration of primer
increm = 0.005;
ISI = 0.01;  % seconds, duration of interval between primer and mask
mask_duration = 0.07;      % seconds, duration of mask
num_turns = 6;            % number of oscillations to consider chance 

% Fixation parameters
param.fix_size = 16; % pixels, cross
param.fix_width = 4; % pixels, line width
param.fix_color = [150 150 150]; % usual color of fixation (gray)
param.fix_tolerance = 100; % pixels, square around fixation
param.fix_samples = 200; % number of pre-trial gaze samples (to check if fixating correctly)
param.fix_duration = ceil(fix_duration/(1/fr));     % frames, durations of fixation + cue

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
param.prm_duration = ceil(primer_duration/(1/fr)); % frames, starting duration of primer presentation 
param.ISI = ceil(ISI/(1/fr));  % frames, min duration in between primer and mask
param.mask_duration = ceil(mask_duration/(1/fr)); % frames, duration of mask presentation 
param.increm = ceil(increm/(1/fr));

%% Initialize

% Shift focus to command window so typing doesn't go to code editor if something
% happens to break
commandwindow
HideCursor;

% initialize propixx
if ~test_flag
    ppx = propixxController();
end
% projector is initialized in normal display mode
Screen('Preference', 'SkipSyncTests', 1);  % can't run PTB on my laptop without skipping sync tests

if ~test_flag
    [ptr, winrect] = ppx.initialize(screenID);
else
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

% to record performance
exptData = [];

% create an instance of the SaccadeTaskDrawer object to handle presentation of different components
% this object is instantiated with the information from param and stim, and the screen ptr
presenter = PropixxSaccadeTaskDrawer(param, stim, ptr, env);     
% set mask type
presenter.mask_method = mask_method;
% set pattern type if using pattern masking
presenter.pattern_type = pattern_type;

% set projector mode to high speed
if ~test_flag
    ppx.setMode(fr);      
end

packet_clock = 1;           % clock that counts 1:1440 to track packet position and flip every 12
prm_timing_reached = false; % flag for detecting when primer has become invisible
primer_log = [];            % records primer durations
osci_tracker = 0;           % tracks number of times performance has oscillated
trial_counter = 0;          % tracks trial number
directions = [];             % trajectory of performance. 1 is up. -1 is down

preEXPstart = GetSecs;
%% Trial loop
while ~prm_timing_reached
    trial_counter = trial_counter + 1;
    if mod(trial_counter, 20) == 1
        while true
            % tell presenter which frame we're on for drawing FP
            presenter.setClock(packet_clock);

            % convert coords for text (don't have a method for this and I'm lazy)
            color = presenter.selectColorChannel(presenter.packet_frame);
            newctr = presenter.convertToQuadrant(env.winCtr, env.displaySize, presenter.packet_frame);

            DrawFormattedText(ptr, 'Look at the fixation cross, then press the space bar.', newctr(1) - env.displaySize(1)/8, newctr(2) - env.displaySize(2)/8, color);
            % Draw fixation point
            presenter.drawFP;

            %flips only on last loop iteration
            presenter.present();
            packet_clock = packet_clock+1;

            [~, ~, keycode, ~] = KbCheck(-1);
            if keycode(KbName('Space'))
                break
            end
        end
    end
    
    % select target direction
    state.cueDir = randi(2)-1;    
    state.primer = 1;

    % update the SaccadeTaskDrawer object with the state information (cue direction and trial type) for this trial
    presenter.state = state;

    % if pattern masking, randomly generate the pattern info ahead of time
    if any(strcmp(mask_method, {'pattern', 'lexical'}))
        presenter.prepareMask;
    end    

    % INITIAL FIXATION + CUE
    rand_idx = randi(length(param.fix_duration));
    curr_fix_duration = param.fix_duration(rand_idx);

    for ff = 1:curr_fix_duration            
        % tell the presenter which frame we're on so the drawers know where to draw
        presenter.setClock(packet_clock);

        % draw stuff
        presenter.drawFP;
        presenter.drawTargetBoxes;

        % only flips if global packet clock is a multiple of 12
        presenter.present;

        % increment global clock
        packet_clock = packet_clock+1;

    end

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
        presenter.present;

        packet_clock = packet_clock+1;
    end

    % INTERSTIMULUS INTERVAL
    for ff = 1:param.ISI
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
    
    response_received = 0;
    while ~response_received
        % tell the presenter which frame we're on
        presenter.setClock(packet_clock);    

        % Draw target boxes
        presenter.drawTargetBoxes;
        % Draw fixation point 
        presenter.drawFP;

        % convert coords for text (don't have a method for this and I'm lazy)
        color = presenter.selectColorChannel(presenter.packet_frame);
        newctr = presenter.convertToQuadrant(env.winCtr, env.displaySize, presenter.packet_frame);

        DrawFormattedText(ptr, 'Did you see the square? (Y/N)', newctr(1) - env.displaySize(1)/12, newctr(2) - env.displaySize(2)/8, color);

        % only flips if global packet clock is a multiple of 12
        presenter.present;

        packet_clock = packet_clock+1;

        [~, ~, keycode, ~] = KbCheck(-1);
        if keycode(KbName('N'))
            visible = 0;
            response_received = 1;
        elseif keycode(KbName('Y'))
            visible = 1;
            response_received = 1;
        elseif keycode(KbName('ESCAPE'))
            sca
            % Save all workspace variables
            save(data_filename)
            % reset projector (turn off fast display)
            if ~test_flag
                ppx.shutdown;
            end
            return
        end
    end

    % if they reported seeing the primer, ask which side
    if visible == 1
        response_received = 0;
        % display FP and target boxes while decision is made
        while ~response_received
            % tell the presenter which frame we're on
            presenter.setClock(packet_clock);    

            % Draw target boxes
            presenter.drawTargetBoxes;
            % Draw fixation point 
            presenter.drawFP;

            % convert coords for text (don't have a method for this and I'm lazy)
            color = presenter.selectColorChannel(presenter.packet_frame);
            newctr = presenter.convertToQuadrant(env.winCtr, env.displaySize, presenter.packet_frame);

            DrawFormattedText(ptr, 'Which side was it on? (Left/Right)', newctr(1) - env.displaySize(1)/12, newctr(2) - env.displaySize(2)/12, color);

            % only flips if global packet clock is a multiple of 12
            presenter.present;

            packet_clock = packet_clock+1;

            [~, ~, keycode, ~] = KbCheck(-1);
            if keycode(KbName('LeftArrow'))
                resp = 0;
                response_received = 1;
            elseif keycode(KbName('RightArrow'))
                resp = 1;
                response_received = 1;
            elseif keycode(KbName('ESCAPE'))
                sca
                % Save all workspace variables
                save(data_filename)
                % reset projector (turn off fast display)
                if ~test_flag
                    ppx.shutdown;
                end
                return
            end
        end
    end
    % track primer durations
    primer_log = [primer_log param.prm_duration];
    
    % adjust primer duration
    if visible == 1 && state.cueDir == resp
        param.prm_duration = param.prm_duration - param.increm; % shorten if correct response
        currdirection = -1;
    else
        param.prm_duration = param.prm_duration + param.increm; % lengthen if incorrect response
        currdirection = 1;
    end
    
    % track consecutive oscillations
    if length(primer_log) > 2
        if currdirection ~= directions(end) %|| currdirection ~= directions(end-1)     
            osci_tracker = osci_tracker+1;
        else
            osci_tracker = 0;
        end
    end
   
    if osci_tracker >= num_turns        % if we've oscillated n times, we've reached plateau
        prm_timing_reached = true;
    end
    
    directions = [directions currdirection];
    % Check if ESC or Q have been pressed, and stop early if so
    [~, ~, keyCode] = KbCheck(-1);

    if keyCode(KbName('ESCAPE')) || keyCode(KbName('q'))
        % Clear screen
        sca

        % Save all workspace variables
        save(data_filename)
        % reset projector (turn off fast display)
        if ~test_flag
            ppx.shutdown;
        end

        return
    end

end
% compute final prime duration
final_prm_dur = mean(primer_log(end-num_turns:end))/fr;

EXPtime = GetSecs - preEXPstart;

%disengage fast mode on projector
if ~test_flag
    ppx.shutdown();
end

%% Clean up
    
% Clear screen
sca

% Save all workspace variables
save(data_filename);

disp(final_prm_dur);
% figure
% plot(primer_log/fr)

