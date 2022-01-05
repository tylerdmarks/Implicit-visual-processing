classdef propixxController < handle
    % Class that handles the configuration of the propixx projector 
    % Last updated TDM Jan 2022
    
    properties
        % framerate
        ptr             % screen pointer
        env
    end
    
    methods
        
        function obj = propixxController()
        end
        
        function set.env(obj, env)
            obj.env = env;
        end
        
        function obj = setMode(obj, fr)
            % switch mode according to desired framerate
            switch fr 
            case 1440
                mode = 5;
            case 480
                mode = 2;
            case 120
                mode = 0;
            end
            % Show black screen while mode switches
            Screen('FillRect', obj.ptr, [0 0 0], [0 0 obj.env.displaySize(1) obj.env.displaySize(2)]);
            Screen('Flip', obj.ptr);
            
            Datapixx('SetPropixxDlpSequenceProgram', mode);
            Datapixx('RegWrRd');
            
            pause(1);
            
            % not sure if this is needed in manual version
            % if mode == 5
            %     PsychProPixx('SetupFastDisplayMode', obj.ptr, 12, 0); 
            % elseif mode == 2
            %     PsychProPixx('SetupFastDisplayMode', obj.ptr, 4, 0);            % this is a guess
            % end
        end 


        function [ptr, env] = initialize(obj, screenID)

            %Check connection and open Datapixx if it's not open yet
            isConnected = Datapixx('isReady');
            if ~isConnected
                Datapixx('Open')
            end

            %Open a display on the Propixx
            AssertOpenGL;
            KbName('UnifyKeyNames');
            [ptr,env] = Screen('OpenWindow', screenID, 0);

            % initialize in non-fast display mode
            Datapixx('SetPropixxDlpSequenceProgram', 0);
            Datapixx('RegWrRd');

            obj.ptr = ptr;

        end  

        function obj = shutdown(obj)
            Datapixx('SetPropixxDlpSequenceProgram', 0);
            Datapixx('RegWrRd');
            
            Datapixx('Close')
        end
    end
end