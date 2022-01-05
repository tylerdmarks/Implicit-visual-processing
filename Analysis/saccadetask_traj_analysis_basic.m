clear
%% import data
% each file is one participant
[matfn, ~] = uigetfile('.mat', 'MultiSelect', 'on');

if iscell(matfn)
    num_subjects = length(matfn);
else
    num_subjects = 1;
end 

mistrial_thresh = 3;         % rt standard deviations to consider excluding trials 
min_rt = 0.1;                % minimum rt for valid trial
max_rt = 0.8;                  % maximum rt for valid trial
etsamplerate = 250;          % hz, sample rate of edf eyetracking data

% store each subject as an entry in a struct
if num_subjects > 1
    data = struct();

    for nn = 1:num_subjects
        currdata = importdata(matfn{nn});
        fields = fieldnames(currdata);
        for ff = 1:length(fields)
            data(nn).(fields{ff}) = currdata.(fields{ff});
        end
    end
else
    data = importdata(matfn);
end

etdata = cell(1, num_subjects);        % eyetracking data, each cell is one subject
rtdata = cell(1, num_subjects);        % reaction time data, each cell is one subject
trialdata = cell(1, num_subjects);     % trial structure data
timing = cell(1, num_subjects);    % trial epochs duration data
for nn = 1:num_subjects
    % get eyetracking data
    etdata{nn}.trialXY = data(nn).ETdata;

    % get reaction time and trial structure data
    % [total trials x 7] column 1: block, 2: trial, 3: cue loc, 4: sacc/antisacc, ...
    % 5: primer (0 none, 1 target loc, 2 non-target loc), 6: pretrial RT, 7: trial RT
    rtdata{nn} = data(nn).exptData(:, 7);
    trialdata{nn} = data(nn).exptData(:, 1:5);
    timing{nn} = data(nn).timing;
end

%% visualizing eye trajectories

%% BLOCK 1 & 3  (50/50)
block = 1;
for ii = 1:num_subjects
    % get trial data for this subject
    curr_trialdata = trialdata{ii}(trialdata{ii}(:, 1) == block, :);
    
    % matlab-procured data (as a backup)
    trialXY = etdata{ii}.trialXY(block);
    % get condition data
    primer = curr_trialdata(:, 5);
    cue = curr_trialdata(:, 3);
    
    % get reaction time data for this subject (for excluding mistrials)
    curr_rtdata = rtdata{ii}(trialdata{ii}(:, 1) == block);
    num_trials = length(curr_rtdata);

    % find included trials
    [~, good_trials] = exclude_outliers(curr_rtdata, mistrial_thresh, min_rt, max_rt);
    
    figure
    % plot for each condition, for each participant
    % full plots
    subplot(2, 2, 1)
    title('No primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})

    subplot(2, 2, 2)
    title('Primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})
    
    % zoomed in plots
    subplot(2, 2, 3)
    title('No primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    xlim([0 500])
    ylim([850 1100])
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})

    subplot(2, 2, 4)
    title('Primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    xlim([0 500])
    ylim([800 1100])
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})
     
    for tt = 1:num_trials
        good_traj = 1;
        curr_x = trialXY.trialXY{tt}(:, 1);
        % if either the x or y trajectory is weird, exclude the trial
        if curr_x(1) < 700 || curr_x(1) > 1200
            good_traj = 0;
        end
        if any(curr_x < 0 | curr_x > 1920)
            if any(curr_x < 0 | curr_x > 1920)
                good_traj = 0;
            end
        end
        
        if good_trials(tt) && good_traj
            idx = randi(300);
            cmap = jet(1000);
            cold = cmap(1:300, :);
            warm = cmap(701:1000, :);
            switch cue(tt)
                case 0          % target is left
                    color = cold(idx, :);           % use random cold color
                case 1          % target is right
                    color = warm(idx, :);           % use random warm color
            end
            
            switch primer(tt)
                case 0          % no primer
                    condition = 1;
                case 1          % primer
                    condition = 2;
            end
            
            subplot(2, 2, condition)
            light_plt = plot(curr_x, 'Color', color, 'LineWidth', 0.5);
            light_plt.Color(4) = 1;
            heavy_plt = plot(curr_x, 'Color', color, 'LineWidth', 2);
            heavy_plt.Color(4) = 1;
%             yl = yline(curr_x.target(1));
            
            subplot(2, 2, condition+2)
            zplt = plot(curr_x, 'Color', color, 'LineWidth', 0.5);
            zplt.Color(4) = 0.8;
%             zyl = yline(curr_x.target(1));
            pause
            delete(zplt);
%             delete(zyl);
            delete(heavy_plt);
%             delete(yl);
            light_plt.Color(4) = 0.6;
        end
    end       

    
%     for tt = 1:length(trialXY)
%         good_traj = 1;
%         x = trialXY{tt}(:, 1);
%         y = trialXY{tt}(:, 2);
%         % if either the x or y trajectory is weird, exclude the trial
%         if x(1) < 300 || x(1) > 1200
%             good_traj = 0;
%         end
%         if any(x < 0 | x > 1920)
%             x = patch_trajectory(x);
%             if any(x < 0 | x > 1920)
%                 good_traj = 0;
%             end
%         end
%         
%         if good_trials(tt) && good_traj
%             idx = randi(300);
%             cmap = jet(1000);
%             cold = cmap(1:300, :);
%             warm = cmap(701:1000, :);
%             switch cue(tt)
%                 case 0          % target is left
%                     color = cold(idx, :);           % use random cold color
%                 case 1          % target is right
%                     color = warm(idx, :);           % use random warm color
%             end
%             
%             switch primer(tt)
%                 case 0          % no primer
%                     condition = 1;
%                 case 1          % primer
%                     condition = 2;
%             end
%             
%             subplot(2, 2, condition)
%             light_plt = plot(x, 'Color', color, 'LineWidth', 0.5);
%             light_plt.Color(4) = 1;
%             heavy_plt = plot(x, 'Color', color, 'LineWidth', 2);
%             heavy_plt.Color(4) = 1;
%             yl = yline(x(1));
%             
%             subplot(2, 2, condition+2)
%             zplt = plot(x, 'Color', color, 'LineWidth', 0.5);
%             zplt.Color(4) = 0.8;
%             zyl = yline(x(1));
%             pause
%             delete(zplt);
%             delete(zyl);
%             delete(heavy_plt);
%             delete(yl);
%             light_plt.Color(4) = 0.6;
%         end
%     end       
end
    
%% Block 2 & 4
block = 2;
zoom = 500;
for ii = 1:num_subjects
    % get trajectory data for this subject
    curr_trialdata = trialdata{ii}(trialdata{ii}(:, 1) == block, :);
    trialXY = etdata{ii}(block).trialXY;
    % get condition data
    primer = curr_trialdata(:, 5);
    cue = curr_trialdata(:, 3);
    
    % get reaction time data for this subject (for excluding mistrials)
    curr_rtdata = rtdata{ii}(trialdata{ii}(:, 1) == block);
    
    % find included trials
    [~, good_trials] = exclude_outliers(curr_rtdata, mistrial_thresh, min_rt, max_rt);
    
   figure
    % plot for each condition, for each participant
    % full plots
    subplot(2, 3, 1)
    title('No primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})

    subplot(2, 3, 2)
    title('Primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})
    
    subplot(2, 3, 3)
    title('Anti-primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})
    
    % zoomed in plots
    subplot(2, 3, 4)
    title('No primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    xlim([0 zoom])
    ylim([850 1100])
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})

    subplot(2, 3, 5)
    title('Primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    xlim([0 zoom])
    ylim([800 1100])
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})
    
    subplot(2, 3, 6)
    title('Anti-primer')
    axis square
    xlabel('time')
    ylabel('xpos')
    xlim([0 zoom])
    ylim([800 1100])
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})
    
    
    for tt = 1:length(trialXY)
        good_traj = 1;
        x = trialXY{tt}(:, 1);
        y = trialXY{tt}(:, 2);
        % if either the x or y trajectory is weird, exclude the trial
        if any(x < 0 | x > 1920)
%             good_traj = 0;
            x = patch_trajectory(x);
            if any(x < 0 | x > 1920) || x(1) < 300 || x(1) > 1200
                good_traj = 0;
            end
        end
        
        if good_trials(tt) && good_traj
            idx = randi(300);
            cmap = jet(1000);
            cold = cmap(1:300, :);
            warm = cmap(701:1000, :);
            switch cue(tt)
                case 0          % target is left
                    color = cold(idx, :);           % use random cold color
                case 1          % target is right
                    color = warm(idx, :);           % use random warm color
            end
            
            switch primer(tt)
                case 0          % no primer
                    condition = 1;
                case 1          % primer
                    condition = 2;
                case 2          % anti-primer
                    condition = 3;
            end
            
            subplot(2, 3, condition)
            light_plt = plot(x, 'Color', color, 'LineWidth', 0.5);
            light_plt.Color(4) = 0.8;
            heavy_plt = plot(x, 'Color', color, 'LineWidth', 2);
            heavy_plt.Color(4) = 0.8;
            yl = yline(x(1));
    
            subplot(2, 3, condition+3)
            zplt = plot(x, 'Color', color, 'LineWidth', 0.5);
            zplt.Color(4) = 0.8;
            zyl = yline(x(1));
            pause
            delete(zplt);
            delete(zyl);
            delete(heavy_plt);
            delete(yl);
        end
    end 
end

    
    
    

