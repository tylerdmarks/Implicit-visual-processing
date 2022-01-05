classdef PropixxSaccadeTaskDrawer < handle
    % This class performs the presentation of items on screen through Psychtoolbox
    % Last updated TDM Jan 2022
    
    properties
        param           % contains graphical info about how to present screen items
        stim            % contains exact spatial info for presenting items
        state           % contains info that instructs presentation for current trial
        ptr             % screen info for PTB
        env
        mask_method   % type of mask used
        pattern_type        % type of mask pattern (if pattern masking)
        pattern_info  % information for drawing multiple elements on the screen during mask period
        mask_text       % random string for lexical mask
        rand_primer_text    % random string for lexical primer for use in no-primer trials
        TEXT_X_OFFSET     % X offset for positioning primer/mask text (pixels)
        TEXT_Y_OFFSET     % Y offset for positioning primer/mask text (pixels)
        TEXT_SIZE
        packet_frame           % packet counter, tells drawing methods where to draw (quadrant, color)
        global_clock
    end

    properties (Access = protected)
    end

    methods
        
        % constructor initializes parameters
        function obj = PropixxSaccadeTaskDrawer(param, stim, ptr, env)
            obj.param = param;
            obj.stim = stim;
            obj.ptr = ptr;
            obj.env = env;
            obj.pattern_type = 'disc';          % default pattern type for pattern masking method
            obj.mask_method = 'metacontrast'; % default primer/mask type
            obj.TEXT_X_OFFSET = -40;              % X pos offset for primer/mask text 
            obj.TEXT_Y_OFFSET = -20;              % Y pos offset for primer/mask text
            obj.TEXT_SIZE = 32;                 % text size for lexical masking
        end

        % setters 
        function set.param(obj, param)
            obj.param = param;
        end

        function set.stim(obj, stim)
            obj.stim = stim;
        end

        function set.state(obj, state)
            obj.state = state;
        end

        function set.ptr(obj, ptr)
            obj.ptr = ptr;
        end

        function set.pattern_type(obj, pattern)
            obj.pattern_type = pattern;
        end 

        function set.mask_method(obj, method)
            obj.mask_method = method;
        end 

        function mask_method = get.mask_method(obj)
            mask_method = obj.mask_method;
        end

        function set.packet_frame(obj, packet_frame)
            obj.packet_frame = packet_frame;
        end

        function packet_frame = get.packet_frame(obj)
            packet_frame = obj.packet_frame;
        end 

        function setClock(obj, global_clock)
            obj.global_clock = global_clock;

            if mod(global_clock, 12) == 0
                obj.packet_frame = 12;
            else
                obj.packet_frame = mod(global_clock, 12);
            end 
        end
 

        % drawing methods

        function obj = drawFP(obj)
            % Draws fixation cross
            
            % get packet frame
            frame = obj.packet_frame;
            % determine color channel [R G B]
            fix_color = obj.selectColorChannel(frame);
            % convert coords to new quadrant
            fix_pos = obj.convertToQuadrant(obj.stim.fix_pos, obj.env.displaySize, frame);
            fix_coords = 0.5*obj.stim.fix_coords;
            fix_width = 0.5*obj.param.fix_width;
      
            % Draws the fixation cross
            Screen('DrawLines', obj.ptr, fix_coords, fix_width, fix_color, fix_pos, 2);
        end

        function obj = drawCue(obj)
            % Draws prosaccade/antisaccade cue (shape around fixation point)
            % right now, they are both the same because we're not alternating, randomizing this trial condition
            
            % get packet frame
            frame = obj.packet_frame;
            % determine color chahnnel [R G B]
            cue_color = obj.selectColorChannel(frame);
            % convert coords and sizes to new quadrant
            cue_pos = obj.convertToQuadrant(obj.stim.fix_pos, obj.env.displaySize, frame);
            cue_size = 0.5*obj.param.cue_size;
            cue_width = 0.5*obj.param.cue_width;

            % draw cue according to condition 
            if obj.state.antisaccadeYN == 0
                Screen('FrameOval', obj.ptr, cue_color, CenterRectOnPoint(cue_size * [0 0 1 1], cue_pos(1), cue_pos(2)), cue_width);
            elseif obj.state.antisaccadeYN == 1
                Screen('FrameOval', obj.ptr, cue_color, CenterRectOnPoint(cue_size * [0 0 1 1], cue_pos(1), cue_pos(2)), cue_width);
            end
        end

        function obj = drawTargetBoxes(obj, landed)
            % Draw target box regions
            
            thickness_scaler = 4;
            % get packet frame
            frame = obj.packet_frame;
            % determine color channel [R G B]
            box_color = obj.selectColorChannel(frame);
            % convert coords to new quadrant and scale sizes
            tgt_pos{1} = obj.convertToQuadrant(obj.stim.tgt_pos{1}, obj.env.displaySize, frame);
            tgt_pos{2} = obj.convertToQuadrant(obj.stim.tgt_pos{2}, obj.env.displaySize, frame);
            box_frame_size = 0.5*obj.param.tgt_frame_size;
            box_frame_width = 0.5*obj.param.tgt_frame_width;

            % Draws the box frames for target regions
            if nargin < 2 || ~landed       % if no input arg is provided, or if saccade hasn't landed yet (landed = 0), draw boxes as normal
                Screen('FrameRect', obj.ptr, box_color, CenterRectOnPoint(box_frame_size * [0 0 1 1], tgt_pos{1}(1), tgt_pos{1}(2)), box_frame_width);
                Screen('FrameRect', obj.ptr, box_color, CenterRectOnPoint(box_frame_size * [0 0 1 1], tgt_pos{2}(1), tgt_pos{2}(2)), box_frame_width);
            elseif landed == 1             % if saccade landed
                % Give positive feedback by turning the frame around the correct answer thicker
                if (~obj.state.antisaccadeYN && ~obj.state.cueDir) || (obj.state.antisaccadeYN && obj.state.cueDir) % left side
                    Screen('FrameRect', obj.ptr, box_color, CenterRectOnPoint(box_frame_size * [0 0 1 1], tgt_pos{1}(1), tgt_pos{1}(2)), thickness_scaler*box_frame_width);
                else % right side
                    Screen('FrameRect', obj.ptr, box_color, CenterRectOnPoint(box_frame_size * [0 0 1 1], tgt_pos{2}(1), tgt_pos{2}(2)), thickness_scaler*box_frame_width);
                end
            elseif landed == 2          % if saccade landed and location doesn't matter
                % Make both frames yellow
                Screen('FrameRect', obj.ptr, box_color, CenterRectOnPoint(box_frame_size * [0 0 1 1], tgt_pos{1}(1), tgt_pos{1}(2)), thickness_scaler*box_frame_width);
                Screen('FrameRect', obj.ptr, box_color, CenterRectOnPoint(box_frame_size * [0 0 1 1], tgt_pos{2}(1), tgt_pos{2}(2)), thickness_scaler*box_frame_width);
            end
        end 

        function obj = drawPrimer(obj)
            % Draws primer according to primer/mask method

            % get packet frame
            frame = obj.packet_frame;
            % determine color channel [R G B]
            primer_color = obj.selectColorChannel(frame);
            % convert coords to new quadrant and scale sizes
            tgt_pos{1} = obj.convertToQuadrant(obj.stim.tgt_pos{1}, obj.env.displaySize, frame);
            tgt_pos{2} = obj.convertToQuadrant(obj.stim.tgt_pos{2}, obj.env.displaySize, frame);
            prm_size = 0.5*obj.param.prm_size;
            text_size = 0.5*obj.TEXT_SIZE;
            text_x_offset = 0.5*obj.TEXT_X_OFFSET;
            text_y_offset = 0.5*obj.TEXT_Y_OFFSET;
            text_pos = obj.convertToQuadrant(obj.stim.fix_pos, obj.env.displaySize, frame);


            % if primer is presented, determine location of primer (or lexical cue) and present 
            if obj.state.primer ~= 0

                if obj.state.primer == 1
                    primer_loc = obj.state.cueDir;          % if present in target location, set primer location to cue direction
                elseif obj.state.primer == 2
                    primer_loc = ~obj.state.cueDir;         % if present in non-target location, set primer location to opposite cue direction
                end

                if strcmp(obj.mask_method, 'metacontrast')
                    Screen('FillRect', obj.ptr, primer_color, CenterRectOnPoint(prm_size*[0 0 1 1], tgt_pos{primer_loc+1}(1), tgt_pos{primer_loc+1}(2)));
                elseif strcmp(obj.mask_method, 'pattern')
                    if strcmp(obj.pattern_type, 'disc')
                        % display a disc at target location
                        Screen('FillOval', obj.ptr, primer_color, CenterRectOnPoint(prm_size*[0 0 1 1], tgt_pos{primer_loc+1}(1), tgt_pos{primer_loc+1}(2)));
                    elseif strcmp(obj.pattern_type, 'square')
                        % display a square (same shape as target) in target location
                        Screen('FillRect', obj.ptr, primer_color, CenterRectOnPoint(prm_size*[0 0 1 1], tgt_pos{primer_loc+1}(1), tgt_pos{primer_loc+1}(2)));
                    elseif strcmp(obj.pattern_type, 'triangle')
                        % display a triangle in target location
                        verts = obj.findTriangleVertices(tgt_pos{primer_loc+1}(1), tgt_pos{primer_loc+1}(2), prm_size);
                        Screen('FillPoly', obj.ptr, primer_color, verts, 1);
                    end
                elseif strcmp(obj.mask_method, 'lexical')
                    % Display word indicating target location
                    if primer_loc == 0
                        primer_text = 'Left';
                    else
                        primer_text = 'Right';
                    end    
                    Screen('TextSize', obj.ptr, text_size);
                    Screen('DrawText', obj.ptr, primer_text, (text_pos(1) + text_x_offset), text_pos(2) + text_y_offset, primer_color, [0 0 0]);
                end
            else            % if no primer is presented, do nothing for metacontrast and pattern, present random string for lexical
                if strcmp(obj.mask_method, 'lexical')
                    primer_text = obj.rand_primer_text;
                    Screen('TextSize', obj.ptr, text_size);
                    Screen('DrawText', obj.ptr, primer_text, (text_pos(1) + text_x_offset), text_pos(2) + text_y_offset, primer_color, [0 0 0]);
                end 
            end

        end

        function obj = drawMask(obj)
            % Draw bilateral masks
            
            % get packet frame
            frame = obj.packet_frame;
            % determine color channel [R G B]
            mask_color = obj.selectColorChannel(frame);
            % convert coords to new quadrant and scale sizes

            switch obj.mask_method
            case 'metacontrast'
                tgt_pos{1} = obj.convertToQuadrant(obj.stim.tgt_pos{1}, obj.env.displaySize, frame);
                tgt_pos{2} = obj.convertToQuadrant(obj.stim.tgt_pos{2}, obj.env.displaySize, frame);
                mask_size = 0.5*obj.param.mask_size;
                mask_width = 0.5*obj.param.mask_width;
            case 'pattern'
                % convert elements of pattern mask
                if ~strcmp(obj.pattern_type, 'triangle')
                    rects = zeros(size(obj.pattern_info.rects, 1), size(obj.pattern_info.rects, 2));
                    curr_rect = zeros(1, 4);
                    for rr = 1:size(obj.pattern_info.rects, 1)
                        curr_oldrect = obj.pattern_info.rects(:, rr);
                        curr_rect(1:2) = obj.convertToQuadrant(curr_oldrect(1:2), obj.env.displaySize, frame);
                        curr_rect(3:4) = obj.convertToQuadrant(curr_oldrect(3:4), obj.env.displaySize, frame);
                        rects(:, rr) = curr_rect;
                    end 
                else
                    verts = obj.pattern_info.verts;         % initialize as old verts array
                    for vv = 1:length(obj.pattern_info.verts)
                        curr_oldverts = obj.pattern_info.verts{vv};
                        verts{vv}(1, :) = obj.convertToQuadrant(curr_oldverts(1, 1:2), obj.env.displaySize, frame);
                        verts{vv}(2, :) = obj.convertToQuadrant(curr_oldverts(2, 1:2), obj.env.displaySize, frame);
                        verts{vv}(3, :) = obj.convertToQuadrant(curr_oldverts(3, 1:2), obj.env.displaySize, frame);
                    end
                end 
            case 'lexical'
                % convert text elements
                text_size = 0.5*obj.TEXT_SIZE;
                text_x_offset = 0.5*obj.TEXT_X_OFFSET;
                text_y_offset = 0.5*obj.TEXT_Y_OFFSET;
                text_pos = obj.convertToQuadrant(obj.stim.fix_pos, obj.env.displaySize, frame);
            end


            if strcmp(obj.mask_method, 'metacontrast')
                % Metacontrast mask
                Screen('FrameRect', obj.ptr, mask_color, CenterRectOnPoint(mask_size*[0 0 1 1], tgt_pos{1}(1), tgt_pos{1}(2)), mask_width);
                Screen('FrameRect', obj.ptr, mask_color, CenterRectOnPoint(mask_size*[0 0 1 1], tgt_pos{2}(1), tgt_pos{2}(2)), mask_width);
            elseif strcmp(obj.mask_method, 'pattern')
                % Pattern mask
                % the pattern_info property was generated previously using the preparePattern method
                if strcmp(obj.pattern_type, 'disc')
                    Screen('FillOval', obj.ptr, mask_color, rects);
                elseif strcmp(obj.pattern_type, 'square')
                    Screen('FillRect', obj.ptr, mask_color, rects);
                elseif strcmp(obj.pattern_type, 'triangle')
                    % triangle requires its own loop to manually draw each triangle, PTB can't draw them all at once
                    for ii = 1:length(verts)
                        Screen('FillPoly', obj.ptr, mask_color, verts{ii}, 1);
                    end
                end
            elseif strcmp(obj.mask_method, 'lexical')
                % Lexical mask
                Screen('TextSize', obj.ptr, text_size);
                Screen('DrawText', obj.ptr, obj.mask_text, (text_pos(1) + text_x_offset), text_pos(2) + text_y_offset, mask_color, [0 0 0]);
            end
        end   

        function obj = drawTarget(obj, override)
            % Draw target stimulus
            
            % get packet frame
            frame = obj.packet_frame;
            % determine color channel
            tgt_color = obj.selectColorChannel(frame);
            % convert coords 
            tgt_pos{1} = obj.convertToQuadrant(obj.stim.tgt_pos{1}, obj.env.displaySize, frame);
            tgt_pos{2} = obj.convertToQuadrant(obj.stim.tgt_pos{2}, obj.env.displaySize, frame);
            tgt_size = 0.5*obj.param.tgt_size;

            if nargin > 1
                display_both = true;
            else
                display_both = false;
            end
            % Draws target in left or right location
            Screen('FillRect', obj.ptr, tgt_color, CenterRectOnPoint(tgt_size * [0 0 1 1], tgt_pos{obj.state.cueDir+1}(1), tgt_pos{obj.state.cueDir+1}(2)));
            % if override argument is given, display target in the other location too
            if display_both
                Screen('FillRect', obj.ptr, tgt_color, CenterRectOnPoint(tgt_size * [0 0 1 1], tgt_pos{~obj.state.cueDir+1}(1), tgt_pos{~obj.state.cueDir+1}(2)));
            end 
        end

        function obj = drawEyeTracker(obj, coords)
            % draw indicator for eyetracker (testing purposes)
            
            % get packet frame
            frame = obj.packet_frame;
            % determine color channel [R G B]
            tracker_color = obj.selectColorChannel(frame);
            % convert coords to new quadrant and scale sizes
            tracker_size = 0.5*obj.param.tracker_size;
            newcoords = obj.convertToQuadrant([coords.x coords.y], obj.env.displaySize, frame);

            Screen('FillRect', obj.ptr, tracker_color, CenterRectOnPoint(tracker_size * [0 0 1 1], newcoords(1), newcoords(2)));
        end


        function [flip_flag, curr_clock] = present(obj, preserve_flag)
            curr_clock = obj.global_clock;
            flip_flag = 0;

            % if 12th frame in the packet has been reached and drawn to, flips and sends the packet to the projector
            if mod(curr_clock, 12) == 0
                if nargin < 2
                    Screen('Flip', obj.ptr);
                else    % if we want to preserve what's on the screen for eyetracking feedback
                    Screen('Flip', obj.ptr, 0, 1);
                end
                flip_flag = 1;
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

        function newposition = convertToQuadrant(obj, oldposition, displaySize, frame)
            %This scales an x, y position into a specific quadrant of the screen   
            % oldposition is old xy coord
            % display size is xy dimensions of the screen
            % frame is packet frame number 

            % determine quadrant
            switch frame 
            case {1, 5, 9}
                quad = 1;
            case {2, 6, 10}
                quad = 2;
            case {3, 7, 11}
                quad = 3;
            case {4, 8, 12}
                quad = 4;
            end

            scale = 0.5;

            switch quad
                case 1; xOffset = 0; yOffset = 0;
                case 2; xOffset = displaySize(1)/2; yOffset = 0; 
                case 3; xOffset = 0; yOffset = displaySize(2)/2;
                case 4; xOffset = displaySize(1)/2; yOffset = displaySize(2)/2;
            end
                
            x = (oldposition(1)*scale)+xOffset;
            y = (oldposition(2)*scale)+yOffset;
            newposition = [x y];

        end

        function color = selectColorChannel(obj, frame)
            % frame is the packet frame number
            switch frame 
            case {1, 4, 7, 10}
                color = [255 0 0];
            case {2, 5, 8, 11}
                color = [0 255 0];
            case {3, 6, 9, 12}
                color = [0 0 255];
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





        
        
        
        
        