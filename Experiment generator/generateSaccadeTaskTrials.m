function expt = generateSaccadeTaskTrials(preset_name)
    
    % Generates a struct 'expt' containing trial condition information based on established presets
    % to add a new preset, add another section to the if/else chain
    % Last updated TDM Jan 2022
    
    if strcmp(preset_name, 'test_preset1')

        % Set number of blocks. Block types are as follows:
        %   1  :  all saccade
        %   2  :  all anti-saccade
        %   3  :  alternating saccade/anti-saccade
        %   4+ :  random order but balanced
        expt.numBlocks = 4;

        % Block 1: all saccade
        expt.block(1).numTrials = 4;    % set number of trials for this block
        expt.block(1).trialOrder = zeros(expt.block(1).numTrials, 2);  % [trials x 2] where column 1 is target location, column 2 is saccade/antisaccade
        right_trials = binaryrandomize(expt.block(1).numTrials);        % select a random half of trials to cue right
        expt.block(1).trialOrder(right_trials, 1) = 1;          
        expt.block(1).trialOrder(:, 2) = 0;             % all saccade trials (saccade = 0)
        expt.block(1).trialOrder(:, 3) = 1;             % present primer on all trials
        % Block 2: all antisaccade
        expt.block(2).numTrials = 4;    % set number of trials for this block
        expt.block(2).trialOrder = zeros(expt.block(2).numTrials, 2);  % [trials x 2] where column 1 is target location, column 2 is saccade/antisaccade
        right_trials = binaryrandomize(expt.block(2).numTrials);        % select a random half of trials to cue right
        expt.block(2).trialOrder(right_trials, 1) = 1;          
        expt.block(2).trialOrder(:, 2) = 1;             % all antisaccade trials (antisaccade = 1)
        expt.block(2).trialOrder(:, 3) = 1;             % present primer on all trials
        % Block 3: alternating saccade/antisaccade
        expt.block(3).numTrials = 4;    % set number of trials for this block
        expt.block(3).trialOrder = zeros(expt.block(3).numTrials, 2);  % [trials x 2] where column 1 is target location, column 2 is saccade/antisaccade
        right_trials = binaryrandomize(expt.block(3).numTrials);        % select a random half of trials to cue right
        expt.block(3).trialOrder(right_trials, 1) = 1; 
        expt.block(3).trialOrder(2:2:end, 2) = 1;             % alternate saccade/antisaccade
        expt.block(3).trialOrder(:, 3) = 1;             % present primer on all trials
        % Block 4: randomize saccade/antisaccade
        expt.block(4).numTrials = 4;    % set number of trials for this block
        expt.block(4).trialOrder = zeros(expt.block(4).numTrials, 2);  % [trials x 2] where column 1 is target location, column 2 is saccade/antisaccade
        right_trials = binaryrandomize(expt.block(4).numTrials);        % select a random half of trials to cue right
        expt.block(4).trialOrder(right_trials, 1) = 1;   
        antisaccade_trials = binaryrandomize(expt.block(4).numTrials);
        expt.block(4).trialOrder(antisaccade_trials, 2) = 1;             % random half of trials are antisaccade
        expt.block(4).trialOrder(:, 3) = 1;             % present primer on all trials
    
    elseif strcmp(preset_name, 'Exp1')
        % Set number of blocks. Block types are as follows:
        %   1  :  all prosaccade, 50% chance primer in target loc, 50% no primer
        %   2  :  all antisacccade, 50% chance primer in target loc, 50% no primer
        
        expt.numBlocks = 2;

        % Block 1
        expt.block(1).numTrials = 160;    % set number of trials for this block
        % trialOrder is [trials x 3] 
        % column 1 is target location, left = 0, right = 1
        % column 2 is prosacccade = 0, antisaccade = 1
        % column 3 is primer presentation type, no primer = 0, target loc = 1, non-target loc = 2
        expt.block(1).trialOrder = zeros(expt.block(1).numTrials, 3);  
        right_trials = binaryrandomize(expt.block(1).numTrials);        % select a random half of trials to cue right
        expt.block(1).trialOrder(right_trials, 1) = 1;          
        expt.block(1).trialOrder(:, 2) = 0;             % all prosaccade trials 
        primer_trials = binaryrandomize(expt.block(1).numTrials);   % select random half of trials for primer presentation
        expt.block(1).trialOrder(primer_trials, 3) = 1;             % present primer on 50% of trials

        % Block 2
        expt.block(2).numTrials = 160;   
        expt.block(2).trialOrder = zeros(expt.block(2).numTrials, 3);  
        right_trials = binaryrandomize(expt.block(2).numTrials);        % select a random half of trials to cue right
        expt.block(2).trialOrder(right_trials, 1) = 1; 
        expt.block(2).trialOrder(:, 2) = 1;             % all antisaccade trials
        primer_trials = binaryrandomize(expt.block(2).numTrials);
        expt.block(2).trialOrder(primer_trials, 3) = 1;             % present primer on 50% of trials

    elseif strcmp(preset_name, 'simple_saccade')
        % all saccade, but doesn't matter because trial success is landing in either target location
        % block 1:          % all saccade, 50% chance primer to be in target location, 50% chance no primer
        expt.numBlocks = 1;
        % Block 1
        expt.block(1).numTrials = 120;    % set number of trials for this block
        expt.block(1).trialOrder = zeros(expt.block(1).numTrials, 3);  
        right_trials = binaryrandomize(expt.block(1).numTrials);        % select a random half of trials to cue right
        expt.block(1).trialOrder(right_trials, 1) = 1;          
        expt.block(1).trialOrder(:, 2) = 0;             % all saccade trials 
        primer_trials = binaryrandomize(expt.block(1).numTrials);   % select random half of trials for primer presentation
        expt.block(1).trialOrder(primer_trials, 3) = 1;             % present primer on 50% of trials   
    end


end

function idx = binaryrandomize(numTrials)      
    % outputs a random half of indices from the vector 1:numTrials
    shuffle = randperm(numTrials);
    idx = shuffle(1:floor(length(shuffle)/2));
end

function idx = tertiaryrandomize(numTrials)
    % outputs a vector of length numTrials where 1/3 of indices are 0, 1, or 2, evenly distributed
    onethird = floor(numTrials/3);
    r = mod(numTrials, 3);
    extra0 = 0;
    extra1 = 0;
    extra2 = 0;

    while r > 0
        a = randi(3);
        switch a 
        case 1 
            if extra0 ~= 1
                extra0 = 1;
                r = r-1;
            end
        case 2 
            if extra1 ~= 1
                extra1 = 1;
                r = r-1;
            end
        case 3
            if extra2 ~= 1
                extra2 = 1;
                r = r-1;
            end
        end
    end

    numzeros = onethird + extra0;
    numones = onethird + extra1;
    numtwos = onethird + extra2;

    shuffle = randperm(numTrials);
    idx(shuffle(1:numzeros)) = 0;
    idx(shuffle(numzeros+1:numzeros+numones)) = 1;
    idx(shuffle(numzeros+numones+1:end)) = 2;
end
