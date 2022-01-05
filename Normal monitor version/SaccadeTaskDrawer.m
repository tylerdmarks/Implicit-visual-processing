classdef SaccadeTaskDrawer < handle
    % This class performs the presentation of items on screen through Psychtoolbox
    properties
        % a bunch of these will be made protected or private at some point
        param           % contains graphical info about how to present screen items
        stim            % contains exact spatial info for presenting items
        state           % contains info that instructs presentation for current trial
        ptr             % screen info for PTB
        mask_method   
        pattern_type        % type of mask pattern
        pattern_info  % information for drawing multiple elements on the screen during mask period
        mask_text       % random string for lexical mask
        rand_primer_text    % random string for lexical primer for use in no-primer trials
        TEXT_X_OFFSET     % X offset for positioning primer/mask text (pixels)
        TEXT_Y_OFFSET     % Y offset for positioning primer/mask text (pixels)
        TEXT_SIZE
    end

    properties (Access = protected)
    end

    methods
        
        % constructor initializes parameters
        function obj = SaccadeTaskDrawer(param, stim, ptr)
            obj.param = param;
            obj.stim = stim;
            obj.ptr = ptr;
            obj.pattern_type = 'disc';          % default pattern type for pattern masking method
            obj.mask_method = 'metacontrast'; % default primer/mask type
            obj.TEXT_X_OFFSET = -40;              % X pos offset for primer/mask text 
            obj.TEXT_Y_OFFSET = -20;              % Y pos offset for primer/mask text
            obj.TEXT_SIZE = 32;                 % text size for lexical masking
        end

        % setters 
        function obj = setParam(obj, param)
            obj.param = param;
        end

        function obj = setStim(obj, stim)
            obj.stim = stim;
        end

        function obj = setState(obj, state)
            obj.state = state;
        end

        function obj = setPtr(obj, ptr)
            obj.ptr = ptr;
        end

        function obj = setPattern(obj, pattern)
            obj.pattern_type = pattern;
        end 

        function obj = setMaskMethod(obj, method)
            obj.mask_method = method;
        end 

        % wrapper methods for controlling timing
        % there is no wrapper method for the target period because timing during this period is controlled by subject
        function obj = cuePeriod(obj)
            % cue presentation epoch
            curr_cue_dur = obj.param.cue_duration_min + rand*(obj.param.cue_duration_max - obj.param.cue_duration_min);
            for ff = 1:curr_cue_dur       
                
                % Draw target boxes
                obj.drawTargetBoxes;
                
                % Draw cue behind fixation point
                obj.drawCue;
                
                % Draw fixation point
                obj.drawFP;
                
                % render
                obj.present;
            end
        end

        function obj = maskPeriod(obj)

            for ff = 1:obj.param.prm_duration       
                % Draw target boxes
                obj.drawTargetBoxes;
                % Draw fixation point (if not using lexical mask)
                if ~strcmp(obj.mask_method, 'lexical')
                    obj.drawFP;
                end
                % Draw primer
                obj.drawPrimer;
                % render
                obj.present;
            end

            % determine ISI
            if obj.param.ISI_min == obj.param.ISI_max
                ISI = obj.param.ISI_min;
            else
                ISI = (obj.param.ISI_max-obj.param.ISI_min)*rand(1, obj.param.ISI_max) + obj.param.ISI_min;
            end 


            for ff = 1:ISI
                % Draw target boxes
                obj.drawTargetBoxes;
                % Draw fixation point (if not using lexical mask)
                if ~strcmp(obj.mask_method, 'lexical')
                    obj.drawFP;
                end
                % render       
                obj.present;
            end

            % Draw masks in both locations

            for ff = 1:obj.param.mask_duration                  
                % Draw target boxes
                obj.drawTargetBoxes;
                % Draw fixation point (if not using lexical mask)
                if ~strcmp(obj.mask_method, 'lexical')
                    obj.drawFP;
                end 
                % Draw mask
                obj.drawMask;
                % render
                obj.present;
            end
        end 


        % drawing methods

        function obj = drawFP(obj)
            % Draws the fixation cross
            Screen('DrawLines', obj.ptr.win, obj.stim.fix_coords, obj.param.fix_width, obj.param.fix_color, obj.stim.fix_pos, 2);
        end

        function obj = drawCue(obj)
            % Draws the Red or green cue according to trial type
            % saccade state is saccade = 0, anti-saccade = 1
            Screen('FillRect', obj.ptr.win, obj.param.cue_color(obj.state.antisaccadeYN+1, :), CenterRectOnPoint(2 * obj.param.fix_size * [0 0 1 1], obj.stim.fix_pos(1), obj.stim.fix_pos(2))); % index for cue_color is 1 for saccade (green), 2 for anti-saccade (red)
        end     

        function obj = drawTargetBoxes(obj, landed)
            % Draws the box frames for target regions
            if nargin < 2 || ~landed       % if no input arg is provided, or if saccade hasn't landed yet (landed = 0), draw boxes as normal
                Screen('FrameRect', obj.ptr.win, obj.param.tgt_color, CenterRectOnPoint(obj.param.tgt_frame_size * [0 0 1 1], obj.stim.tgt_pos{1}(1), obj.stim.tgt_pos{1}(2)), obj.param.tgt_frame_width);
                Screen('FrameRect', obj.ptr.win, obj.param.tgt_color, CenterRectOnPoint(obj.param.tgt_frame_size * [0 0 1 1], obj.stim.tgt_pos{2}(1), obj.stim.tgt_pos{2}(2)), obj.param.tgt_frame_width);
            elseif landed == 1             % if saccade landed
                % Give positive feedback by turning the frame around the
                % correct answer yellow
                if (~obj.state.antisaccadeYN && ~obj.state.cueDir) || (obj.state.antisaccadeYN && obj.state.cueDir) % left
                    Screen('FrameRect', obj.ptr.win, obj.param.tgt_feedback_color, CenterRectOnPoint(obj.param.tgt_frame_size * [0 0 1 1], obj.stim.tgt_pos{1}(1), obj.stim.tgt_pos{1}(2)), 2 * obj.param.tgt_frame_width);
                else % right
                    Screen('FrameRect', obj.ptr.win, obj.param.tgt_feedback_color, CenterRectOnPoint(obj.param.tgt_frame_size * [0 0 1 1], obj.stim.tgt_pos{2}(1), obj.stim.tgt_pos{2}(2)), 2 * obj.param.tgt_frame_width);
                end
            elseif landed == 2          % if saccade landed and location doesn't matter
                % Make both frames yellow
                Screen('FrameRect', obj.ptr.win, obj.param.tgt_feedback_color, CenterRectOnPoint(obj.param.tgt_frame_size * [0 0 1 1], obj.stim.tgt_pos{1}(1), obj.stim.tgt_pos{1}(2)), obj.param.tgt_frame_width);
                Screen('FrameRect', obj.ptr.win, obj.param.tgt_feedback_color, CenterRectOnPoint(obj.param.tgt_frame_size * [0 0 1 1], obj.stim.tgt_pos{2}(1), obj.stim.tgt_pos{2}(2)), obj.param.tgt_frame_width);
            end
        end 

        function obj = drawPrimer(obj)
            % Draws primer according to primer/mask method

            % if primer is presented, determine location of primer (or lexical cue) and present 
            if obj.state.primer ~= 0

                if obj.state.primer == 1
                    primer_loc = obj.state.cueDir;          % if present in target location, set primer location to cue direction
                elseif obj.state.primer == 2
                    primer_loc = ~obj.state.cueDir;         % if present in non-target location, set primer location to opposite cue direction
                end

                if strcmp(obj.mask_method, 'metacontrast')
                    Screen('FillRect', obj.ptr.win, obj.param.prm_color, CenterRectOnPoint(obj.param.prm_size*[0 0 1 1], obj.stim.tgt_pos{primer_loc+1}(1), obj.stim.tgt_pos{primer_loc+1}(2)));
                elseif strcmp(obj.mask_method, 'pattern')
                    if strcmp(obj.pattern_type, 'disc')
                        % display a disc at target location
                        Screen('FillOval', obj.ptr.win, obj.param.prm_color, CenterRectOnPoint(obj.param.prm_size*[0 0 1 1], obj.stim.tgt_pos{primer_loc+1}(1), obj.stim.tgt_pos{primer_loc+1}(2)));
                    elseif strcmp(obj.pattern_type, 'square')
                        % display a square (same shape as target) in target location
                        Screen('FillRect', obj.ptr.win, obj.param.prm_color, CenterRectOnPoint(obj.param.prm_size*[0 0 1 1], obj.stim.tgt_pos{primer_loc+1}(1), obj.stim.tgt_pos{primer_loc+1}(2)));
                    elseif strcmp(obj.pattern_type, 'triangle')
                        % display a triangle in target location
                        verts = obj.findTriangleVertices(obj.stim.tgt_pos{primer_loc+1}(1), obj.stim.tgt_pos{primer_loc+1}(2), obj.param.prm_size);
                        Screen('FillPoly', obj.ptr.win, obj.param.prm_color, verts, 1);
                    end
                elseif strcmp(obj.mask_method, 'lexical')
                    % Display word indicating target location
                    if primer_loc == 0
                        primer_text = 'Left';
                    else
                        primer_text = 'Right';
                    end    
                    Screen('TextSize', obj.ptr.win, obj.TEXT_SIZE);
                    Screen('DrawText', obj.ptr.win, primer_text, (obj.stim.fix_pos(1) + obj.TEXT_X_OFFSET), obj.stim.fix_pos(2) + obj.TEXT_Y_OFFSET, obj.param.fix_color, [0 0 0]);
                end
            else            % if no primer is presented, do nothing for metacontrast and pattern, present random string for lexical
                if strcmp(obj.mask_method, 'lexical')
                    primer_text = obj.rand_primer_text;
                    Screen('TextSize', obj.ptr.win, obj.TEXT_SIZE);
                    Screen('DrawText', obj.ptr.win, primer_text, (obj.stim.fix_pos(1) + obj.TEXT_X_OFFSET), obj.stim.fix_pos(2) + obj.TEXT_Y_OFFSET, obj.param.fix_color, [0 0 0]);
                end 
            end

        end

        function obj = drawMask(obj)
            if strcmp(obj.mask_method, 'metacontrast')
                % Metacontrast mask
                Screen('FrameRect', obj.ptr.win, obj.param.prm_color, CenterRectOnPoint(obj.param.mask_size*[0 0 1 1], obj.stim.tgt_pos{1}(1), obj.stim.tgt_pos{1}(2)), obj.param.mask_width);
                Screen('FrameRect', obj.ptr.win, obj.param.prm_color, CenterRectOnPoint(obj.param.mask_size*[0 0 1 1], obj.stim.tgt_pos{2}(1), obj.stim.tgt_pos{2}(2)), obj.param.mask_width);
            elseif strcmp(obj.mask_method, 'pattern')
                % Pattern mask
                % the pattern_info property was generated previously using the preparePattern method
                if strcmp(obj.pattern_type, 'disc')
                    Screen('FillOval', obj.ptr.win, obj.param.prm_color, obj.pattern_info.rects);
                elseif strcmp(obj.pattern_type, 'square')
                    Screen('FillRect', obj.ptr.win, obj.param.prm_color, obj.pattern_info.rects);
                elseif strcmp(obj.pattern_type, 'triangle')
                    % triangle requires its own loop to manually draw each triangle, PTB can't draw them all at once
                    for ii = 1:length(obj.pattern_info.verts)
                        Screen('FillPoly', obj.ptr.win, obj.param.prm_color, obj.pattern_info.verts{ii}, 1);
                    end
                end
            elseif strcmp(obj.mask_method, 'lexical')
                % Lexical mask
                Screen('TextSize', obj.ptr.win, obj.TEXT_SIZE);
                Screen('DrawText', obj.ptr.win, obj.mask_text, (obj.stim.fix_pos(1) + obj.TEXT_X_OFFSET), obj.stim.fix_pos(2) + obj.TEXT_Y_OFFSET, obj.param.fix_color, [0 0 0]);
            end
        end 
        
        function obj = drawTargetMask(obj)
            if strcmp(obj.mask_method, 'metacontrast')
                % Metacontrast mask
                Screen('FrameRect', obj.ptr.win, obj.param.prm_color, CenterRectOnPoint(obj.param.mask_size*[0 0 1 1], obj.stim.tgt_pos{obj.state.cueDir+1}(1), obj.stim.tgt_pos{obj.state.cueDir+1}(2)), obj.param.mask_width);
            elseif strcmp(obj.mask_method, 'pattern')
                % Pattern mask
                % the pattern_info property was generated previously using the preparePattern method
                % if cueDir is left (0), use the first half of rect elements, if right (1) use second half of elements
                if obj.state.cueDir == 0
                    ele_idx = 1:size(obj.pattern_info.rects, 2)/2;
                elseif obj.state.cueDir == 1
                    ele_idx = size(obj.pattern_info.rects, 2)/2+1:size(obj.pattern_info.rects, 2);
                end
                if strcmp(obj.pattern_type, 'disc')
                    Screen('FillOval', obj.ptr.win, obj.param.prm_color, obj.pattern_info.rects(:, ele_idx));
                elseif strcmp(obj.pattern_type, 'square')
                    Screen('FillRect', obj.ptr.win, obj.param.prm_color, obj.pattern_info.rects(:, ele_idx));
                elseif strcmp(obj.pattern_type, 'triangle')
                    % triangle requires its own loop to manually draw each triangle, PTB can't draw them all at once
                    curr_verts = obj.pattern_info.verts{ele_idx};
                    for ii = 1:length(curr_verts)
                        Screen('FillPoly', obj.ptr.win, obj.param.prm_color, curr_verts{ii}, 1);
                    end
                end
            end
        end

        function obj = drawTarget(obj, override)
            if nargin > 1
                display_both = true;
            else
                display_both = false;
            end
            % Draws target in left or right location
            Screen('FillRect', obj.ptr.win, obj.param.tgt_color, CenterRectOnPoint(obj.param.tgt_size * [0 0 1 1], obj.stim.tgt_pos{obj.state.cueDir+1}(1), obj.stim.tgt_pos{obj.state.cueDir+1}(2)));
            % if override argument is given, display target in the other location too
            if display_both
                Screen('FillRect', obj.ptr.win, obj.param.tgt_color, CenterRectOnPoint(obj.param.tgt_size * [0 0 1 1], obj.stim.tgt_pos{~obj.state.cueDir+1}(1), obj.stim.tgt_pos{~obj.state.cueDir+1}(2)));
            end 
        end

        function obj = drawEyeTracker(obj, coords)
            % draw indicator for eyetracker (testing purposes)
            Screen('FillRect', obj.ptr.win, obj.param.tracker_color, CenterRectOnPoint(obj.param.tracker_size * [0 0 1 1], coords.x, coords.y));
        end


        function obj = present(obj, preserve_flag)
            % renders to screen
            if nargin < 2
                Screen('Flip', obj.ptr.win);
            else    % if we want to preserve what's on the screen for eyetracking feedback
                Screen('Flip', obj.ptr.win, 0, 1);
            end

        end

        function obj = prepareMask(obj)
            if strcmp(obj.mask_method, 'pattern')
                % pre-generates the rect info for drawing pattern elements
                pattern_frame_size = 1*obj.param.tgt_frame_size;            % size of the square-shaped area within which the pattern is presented
                pattern_primer_size = 0.8*obj.param.prm_size;               % adjust size of the primer for pattern masking, some factor of the original target size
                num_pattern_eles = 20;          % number of pattern elements to presented in each location
                left_boundaries = CenterRectOnPoint(pattern_frame_size*[0 0 1 1], obj.stim.tgt_pos{1}(1), obj.stim.tgt_pos{1}(2));  % boundaries (rect) of left pattern presentation area
                right_boundaries = CenterRectOnPoint(pattern_frame_size*[0 0 1 1], obj.stim.tgt_pos{2}(1), obj.stim.tgt_pos{2}(2)); % boundaries (rect) of right pattern presentation area
                element_coords = obj.generateRandomCenters(left_boundaries, num_pattern_eles);       
                element_coords = cat(1, obj.generateRandomCenters(right_boundaries, num_pattern_eles), element_coords);   % center coordinates for all pattern elements to be presented, col 1 is x coord, col 2 is y coord
                
                % generate the list of rects to plug into the Screen function for disc or square patterns 
                if any(strcmp(obj.pattern_type, {'disc', 'square'}))
                    rects = zeros(4, 2*num_pattern_eles);
                    for jj = 1:(2*num_pattern_eles)
                        rects(:, jj) = CenterRectOnPoint(pattern_primer_size*[0 0 1 1], element_coords(jj, 1), element_coords(jj, 2));
                    end

                    obj.pattern_info.rects = rects;
                end

                % generate the list of vertices for making triangles
                if strcmp(obj.pattern_type, 'triangle')
                    verts = cell(1, 2*num_pattern_eles);
                    for ii = 1:(2*num_pattern_eles)
                        verts{ii} = obj.findTriangleVertices(element_coords(ii, 1), element_coords(ii, 2), pattern_primer_size);
                    end
                    obj.pattern_info.verts = verts;
                end
            elseif strcmp(obj.mask_method, 'lexical')
                % generate random string for mask
                obj.mask_text = obj.generateRandString(5);
                % generate random string for primer text for use if no-primer trial
                obj.rand_primer_text = obj.generateRandString(5);
            end
        end

    end 

    methods (Access = 'protected')

        function verts = findTriangleVertices(obj, x, y, l)
            % finds vertices of an equilateral triangle centered on (x, y) and with edge length l
            % verts is matrix where each row is the xy coords of a vertex

            % x coords
            verts(1, 1) = x;
            verts(2, 1) = x - l/2;
            verts(3, 1) = x + l/2;

            % y coords
            verts(1, 2) = y - sqrt((l^2)/4 - 3.9/(l^2));
            verts(2, 2) = y + sqrt((l^2)/4 - 3.9/(l^2));
            verts(3, 2) = verts(2, 2);
        end 

        function coords = generateRandomCenters(obj, bounds, n)
            % generates n random uniformly distributed coordinates within bounds
            % where bounds(1) = xmin, bounds(2) = ymin, bounds(3) = xmax, bounds(4) = ymax
            coords(:, 1) = bounds(1) + (bounds(3)-bounds(1))*rand(n, 1);
            coords(:, 2) = bounds(2) + (bounds(4)-bounds(2))*rand(n, 1);
        end

        function out_text = generateRandString(obj, n)
            % n = length of string to generate
            % possible random characters
            s = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

            % find number of random characters to choose from
            numChars = length(s); 

            % generate random string
            out_text = s(ceil(rand(1,n)*numChars));
        end


    end
 

end





        
        
        
        
        