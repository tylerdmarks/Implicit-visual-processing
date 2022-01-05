KbName('UnifyKeyNames');        % fixes an error calling KbName('ESCAPE'), might be a Windows thing

screenID = 0;           % screenID = 0 for laptop alone, screenID = 1 for laptop on dual monitor setup, screenID = 2 for second monitor 

mask_method = 'metacontrast';
pattern_type = 'disc';

% manually set cue dir and primer flag
cuedir = randi([0 1], 1, 4);
primerYN = ones(1, 4);              % for now present primer every time

% Fixation parameters
param.fix_size = 20; % pixels, cross
param.fix_width = 4; % pixels, line width
param.fix_color = [150 150 150]; % usual color of fixation (gray)

% Target parameters
param.tgt_distance = 400; % pixels, how far targets are from fixation (symmetric)
param.tgt_size = 40; % pixels, square, how large target is
param.tgt_color = [150 150 150]; % color of target (gray). Also frame color.
param.tgt_frame_size = 150; % pixels, square, size of frame
param.tgt_frame_width = 2; % pixels, line width of frame
param.tgt_tolerance = 150; % pixels, currently same size as frame

% Primer and mask parameters (backward masking of target primer)
param.prm_color = [150 150 150]; % color of primer and mask (gray).
param.prm_size = 40; % pixels, square, how large the primer is (same size as target).
param.mask_size = 120; % pixels, square, how large the metacontrast mask is
param.mask_width = 40; % pixels, line width of metacontrast mask, should spatially match border of primer
param.prm_duration = 100; % frames, duration of primer presentation (1 frame = ~17ms on a 60hz monitor)
param.mask_delay = 1;  % frames, duration in between primer and mask
param.mask_duration = 100; % frames, duration of mask presentation

commandwindow
HideCursor;

% skip sync tests if necessary (working on laptop)
Screen('Preference', 'SkipSyncTests', 1);  

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


% create an instance of the SaccadeTaskDrawer object to handle presentation of different components
% this object is instantiated with the information from param and stim, and the screen ptr
presenter = SaccadeTaskDrawer(param, stim, ptr);     
% set mask type
presenter.setMaskMethod(mask_method);
% set pattern type if using pattern masking
presenter.setPattern(pattern_type);

presenter.drawTargetBoxes;
presenter.drawFP;
DrawFormattedText(ptr.win, 'Press spacebar to continue.', 'center', env.winCtr(2) / 4, [150 150 150]);
presenter.present;
KbStrokeWait(-1);
for tt = 1:length(cuedir)
    % if pattern masking, randomly generate the pattern info ahead of time
    if any(strcmp(mask_method, {'pattern', 'lexical'}))
        presenter.prepareMask;
    end
    state.cueDir = cuedir(tt);
    state.primerYN = primerYN(tt);
    
    presenter.setState(state);
    
    presenter.drawTargetBoxes;
    presenter.drawFP;
    presenter.present;
    pause(2.0);

    if strcmp(mask_method, 'lexical')
        presenter.drawTargetBoxes;
        presenter.present;
        pause(0.5)
    end
        
    presenter.maskPeriod;
    
    if strcmp(mask_method, 'lexical')
        presenter.drawTargetBoxes;
        presenter.present;
        pause(0.5)
    end
    
    presenter.drawTargetBoxes;
    presenter.drawFP;
    DrawFormattedText(ptr.win, 'Press spacebar to continue.', 'center', env.winCtr(2) / 4, [150 150 150]);
    presenter.present;
    KbStrokeWait(-1);
end

sca
