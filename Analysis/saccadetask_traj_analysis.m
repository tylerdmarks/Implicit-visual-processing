%% import data
clear
% each file is one participant
[matfn, ~] = uigetfile('.mat', 'MultiSelect', 'on');

if iscell(matfn)
    num_subjects = length(matfn);
    for ii = 1:length(matfn)
        edffn{ii} = sprintf('%s.edf', erase(matfn{ii}, '.mat'));
    end
else
    num_subjects = 1;
    edffn = sprintf('%s.edf', erase(matfn, '.mat'));
end 

mistrial_thresh = 3;         % rt standard deviations to consider excluding trials 
min_rt = 0.1;                % minimum rt for valid trial
max_rt = 0.8;                  % maximum rt for valid trial
etsamplerate = 250;          % hz, sample rate of edf eyetracking data

% store each subject as an entry in a struct
if num_subjects > 1
    data = struct();
    edfdata = struct();

    for nn = 1:num_subjects
        currdata = importdata(matfn{nn});
        fields = fieldnames(currdata);
        for ff = 1:length(fields)
            data(nn).(fields{ff}) = currdata.(fields{ff});
        end
        curredfdata = edfmex(edffn{nn});
        fields = fieldnames(curredfdata);
        for ff = 1:length(fields)
            edfdata(nn).(fields{ff}) = curredfdata.(fields{ff});
        end
    end
else
    data = importdata(matfn);
    edfdata = edfmex(edffn);
end

etdata = cell(1, num_subjects);        % eyetracking data, each cell is one subject
rtdata = cell(1, num_subjects);        % reaction time data, each cell is one subject
trialdata = cell(1, num_subjects);     % trial structure data
timing = cell(1, num_subjects);    % trial epochs duration data
for nn = 1:num_subjects
    % get eyetracking data
    etdata{nn}.time = edfdata(nn).FSAMPLE.time;
    etdata{nn}.x = edfdata(nn).FSAMPLE.gx;
    etdata{nn}.y = edfdata(nn).FSAMPLE.gy;
    
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
    
    % get condition data
    primer = curr_trialdata(:, 5);
    cue = curr_trialdata(:, 3);
    
    % get reaction time data for this subject (for excluding mistrials)
    curr_rtdata = rtdata{ii}(trialdata{ii}(:, 1) == block);
    
    % get timing data
    curr_timing.fix = timing{ii}.fix(trialdata{ii}(:, 1) == block);
    curr_timing.primer = timing{ii}.primer(trialdata{ii}(:, 1) == block);
    curr_timing.ISI = timing{ii}.ISI(trialdata{ii}(:, 1) == block);
    curr_timing.mask = timing{ii}.mask(trialdata{ii}(:, 1) == block);
    curr_timing.delay = timing{ii}.delay(trialdata{ii}(:, 1) == block);
    curr_timing.target = timing{ii}.target(trialdata{ii}(:, 1) == block);
    curr_timing.trial = timing{ii}.trial(trialdata{ii}(:, 1) == block);

    %%%%%% get trajectory data for this subject
    
    % determine which eye to use and extract x trajectory
    tstamp = etdata{ii}.time;
    both_x = etdata{ii}.x;
    both_x(both_x > 10000) = NaN;
    if mean(both_x(1, :)) < 0
        x = both_x(2, :);
    else
        x = both_x(1, :);
    end
    
    num_trials = length(curr_timing.fix);
    first_trial = (block-1)*num_trials+1;
    last_trial = num_trials*block;
    
    % sort each trial's trajectory into 1) fix period 2) primer period 3) target period
    x_sorted = cell(1, num_trials);
    
%     offset = floor(((((length(tstamp)/etsamplerate) - sum(timing{ii}.trial))/num_trials)*etsamplerate)/2);  % some offest to account for discrepancies between matlab timing and etdata timing
    % need some offset to account for weird timing mismatch crap
    offset = 3;
    curr_frame = 1 + ceil(etsamplerate*sum(timing{ii}.trial(1:first_trial-1))) + ((offset+1)*num_trials)*(block-1);           % keep track of where we are
    for tt = 1:num_trials
        trialdur = ceil(curr_timing.trial(tt)*etsamplerate);           % get duration of current trial
        try
            x_sorted{tt} = x(curr_frame:curr_frame+trialdur);
        catch
            x_sorted{tt} = x(curr_frame:end);
        end
        curr_frame = curr_frame + trialdur + offset + 1;
    end  
    %%%%%
   
    % find included trials
    [~, good_trials] = exclude_outliers(curr_rtdata, mistrial_thresh, min_rt, max_rt);
    
    f = figure;
    fig_filename = 'trajectory_plot.gif';
    set(f, 'Position', [100 00 800 800]);
    % plot for each condition, for each participant
    % full plots
    subplot(2, 2, 1)
    title('No primer')
    axis square
    xlabel('time (s)')
    ylabel('xpos')
    xlim([-0.3 1])
    ylim([400 1500])
    hold on
    xline(0)
    xline(curr_timing.primer(1) + curr_timing.ISI(1) + curr_timing.mask(1));
%     xticks([0.1 0.4]*etsamplerate);
%     xticklabels({'.1', '.4'});

    subplot(2, 2, 2)
    title('Primer')
    axis square
    xlabel('time (s)')
    ylabel('xpos')
    xlim([-0.3 1])
    ylim([400 1500])
    hold on
    xline(0)
    xline(curr_timing.primer(1) + curr_timing.ISI(1) + curr_timing.mask(1));
%     xticks([0.1 0.4]*etsamplerate);
%     xticklabels({'.1', '.4'});
    
    % zoomed in plots
    subplot(2, 2, 3)
    title('No primer')
    axis square
    xlabel('time (s)')
    ylabel('xpos')
    xlim([-0.3 0.6])
    ylim([850 1100])
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})

    subplot(2, 2, 4)
    title('Primer')
    axis square
    xlabel('time (s)')
    ylabel('xpos')
    xlim([-0.3 0.6])
    ylim([800 1100])
    hold on
%     xticks([0.1 0.2 0.3 0.4]*etsamplerate)
%     xticklabels({'.1', '.2', '.3', '.4'})
     
    for tt = 1:num_trials
        good_traj = 1;
        curr_x = x_sorted{tt};
        % if either the x or y trajectory is weird, exclude the trial
        if curr_x(1) < 200 || curr_x(1) > 1600
            good_traj = 0;
        end
        if any(curr_x < 0 | curr_x > 1920)
            curr_x = patch_trajectory(curr_x);
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
            
            % find offset for plotting based on fix time
            curr_fixtime = floor(curr_timing.fix(tt)*etsamplerate);
            time_vector = linspace(-curr_fixtime, length(curr_x)-curr_fixtime, length(curr_x))/etsamplerate;
            
            subplot(2, 2, condition)
            light_plt = plot(time_vector, curr_x, 'Color', color, 'LineWidth', 0.5);
            light_plt.Color(4) = 1;
            heavy_plt = plot(time_vector, curr_x, 'Color', color, 'LineWidth', 2);
            heavy_plt.Color(4) = 1;
%             yl = yline(curr_x.target(1));
            
            subplot(2, 2, condition+2)
            zplt = plot(time_vector, curr_x, 'Color', color, 'LineWidth', 0.5);
            zplt.Color(4) = 0.8;
%             zyl = yline(curr_x.target(1));
            pause

            drawnow
            frame = getframe(1);
            im = frame2im(frame);
            [imind,cm] = rgb2ind(im,256);
            if tt == 1
                imwrite(imind,cm,fig_filename,'gif', 'DelayTime', 0.1, 'Loopcount',inf);
            else
                imwrite(imind,cm,fig_filename,'gif', 'DelayTime', 0.1, 'WriteMode','append');
            end
            
            delete(zplt);
%             delete(zyl);
            delete(heavy_plt);
%             delete(yl);
            light_plt.Color(4) = 0.4;
            
            
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

    
    
%% quantifying deflections
    % want to check 1) distribution of max deviations (violinplot)
    % 2) frequency of deflections between conditions (proportion of max deviations above some threshold)
    % and 3) magnitude of deflections between conditions (for all trials with max distance greater than some value, what is the average distance)
%% blocks 1 & 3
block = 2;
starting_frame = 0.6*etsamplerate;       % frame at which to start considering et data (to exclude refixation period)
ending_frame = 1*etsamplerate;         % frame at which to end considering et data (before end) (to exclude refix period)
pooled_deflectrate_npr = [];
pooled_deflectrate_pr = [];
pooled_deflectmag_npr = [];
pooled_deflectmag_pr = [];
v = figure;
e = figure;
hold on
v_offset = 0.2;
deflect_thresh = 50;
for ii = 1:num_subjects
    % get trial data for this subject
    curr_trialdata = trialdata{ii}(trialdata{ii}(:, 1) == block, :);
    
    % get condition data
    primer = curr_trialdata(:, 5);
    cue = curr_trialdata(:, 3);
    saccade = curr_trialdata(:, 4);
    
    % get reaction time data for this subject (for excluding mistrials)
    curr_rtdata = rtdata{ii}(trialdata{ii}(:, 1) == block);
    
    % get timing data
    curr_timing.fix = timing{ii}.fix(trialdata{ii}(:, 1) == block);
    curr_timing.primer = timing{ii}.primer(trialdata{ii}(:, 1) == block);
    curr_timing.ISI = timing{ii}.ISI(trialdata{ii}(:, 1) == block);
    curr_timing.mask = timing{ii}.mask(trialdata{ii}(:, 1) == block);
    curr_timing.delay = timing{ii}.delay(trialdata{ii}(:, 1) == block);
    curr_timing.target = timing{ii}.target(trialdata{ii}(:, 1) == block);
    curr_timing.trial = timing{ii}.trial(trialdata{ii}(:, 1) == block);

    %%%%%% get trajectory data for this subject
    
    % determine which eye to use and extract x trajectory
    tstamp = etdata{ii}.time;
    both_x = etdata{ii}.x;
    both_x(both_x > 10000) = NaN;
    if mean(both_x(1, :)) < 0
        x = both_x(2, :);
    else
        x = both_x(1, :);
    end
    
    num_trials = length(curr_timing.fix);
    first_trial = (block-1)*num_trials+1;
    last_trial = num_trials*block;
    
    % sort each trial's trajectory 
    x_sorted = cell(1, num_trials);
    
    curr_frame = 1 + ceil(etsamplerate*sum(timing{ii}.trial(1:first_trial-1)));           % keep track of where we are
%     offset = floor(((((length(tstamp)/etsamplerate) - sum(timing{ii}.trial))/num_trials)*etsamplerate)/2);  % some offest to account for discrepancies between matlab timing and etdata timing
    offset = 3;
    curr_frame = 1 + ceil(etsamplerate*sum(timing{ii}.trial(1:first_trial-1))) + ((offset+1)*num_trials)*(block-1);           % keep track of where we are
    for tt = 1:num_trials
        trialdur = ceil(curr_timing.trial(tt)*etsamplerate);           % get duration of current trial
        try
            x_sorted{tt} = x(curr_frame:curr_frame+trialdur);
        catch
            x_sorted{tt} = x(curr_frame:end);
        end
        curr_frame = curr_frame + trialdur + offset + 1;
    end 
    %%%%%%
    
    % matlab-procured data (as a backup)
%     trialXY = etdata{ii}(block).trialXY;
   
    
    % find included trials
    [~, good_trials] = exclude_outliers(curr_rtdata, mistrial_thresh, min_rt, max_rt);
    npr_devs = [];  % deviation logs
    pr_devs = [];
    % go through each trial, log the max deviation
%     figure
    for tt = 1:num_trials
        % get rid of bad trajectories
        good_traj = 1;
        curr_x = x_sorted{tt};
        % if either the x or y trajectory is weird, exclude the trial
        if curr_x(1) < 200 || curr_x(1) > 1600
            good_traj = 0;
        end
        if any(curr_x < 0 | curr_x > 1920)
            curr_x = patch_trajectory(curr_x);
            if any(curr_x < 0 | curr_x > 1920)
                good_traj = 0;
            end
        end
        
        if good_trials(tt) && good_traj
            
            % find max deviation for the trial
            
            % using max deviation between two points in the trace (not ideal, introduces overshoot artifacts)
%             max_dev = abs(max(curr_x(starting_frame:end-ending_frame)) - min(curr_x(starting_frame:end-ending_frame)));

            % using max negative deviation from some starting value (fixation location)
            startpos = curr_x(starting_frame);          % reference position
            dev_window = curr_x(starting_frame:end-ending_frame);   % extracted window of data to evaluate
            
            % difference between trace and starting position
            deviation = dev_window - startpos;
            
            % determine which direction is incorrect
            % find maximum deflection in wrong direction
            if (saccade(tt) == 0 && cue(tt) == 1) || (saccade(tt) == 1 && cue(tt) == 0)
                % if prosaccade and cue right or antisaccade and cue left
                % wrong direction is negative direction
                max_dev = abs(min(deviation));
            elseif (saccade(tt) == 0 && cue(tt) == 0) || (saccade(tt) == 1 && cue(tt) == 1)
                % if prosaccade and cue left or antisaccade and cue right
                % wrong direction is positive direction
                max_dev = abs(max(deviation));
            end
                   
%             disp(max_dev);
%             plot(curr_x)
%             pause
            % add it to corresponding log
            switch primer(tt)
                case 0          % no primer
                    npr_devs = [npr_devs max_dev];
                case 1          % primer
                    pr_devs = [pr_devs max_dev];
            end
        end
    end
    
%     % exclude bad trials
%     npr_devs(npr_devs < 300) = [];
%     pr_devs(pr_devs < 300) = [];
    
    % visualize
    figure(v)
    violinplot(ii-v_offset, npr_devs', {sprintf('%d', ii)}, 'Width', 0.15, 'ShowBoxPlot', false, 'ViolinColor', [0.5 0.4 0.1], 'ViolinAlpha', 0.1, 'ShowWhiskers', false);
    violinplot(ii+v_offset, pr_devs', {sprintf('%d', ii)}, 'Width', 0.15, 'ShowBoxPlot', false, 'ViolinColor', [0.6 0.2 0.5], 'ViolinAlpha', 0.1, 'ShowWhiskers', false);

    figure(e)
    subplot(2, ceil(num_subjects/2), ii)
    ecdf(npr_devs);
    hold on
    ecdf(pr_devs);
    axis square
    xline(deflect_thresh);
    xlabel('Deviation size')
    ylabel('Cumulative proportion')
    
    % proportion of deviations that are greater than some threshold for both conditions
    deflectrate_npr = 100*sum(npr_devs > deflect_thresh)/length(npr_devs);
    deflectrate_pr = 100*sum(pr_devs > deflect_thresh)/length(pr_devs);
    
    pooled_deflectrate_npr = [pooled_deflectrate_npr deflectrate_npr];
    pooled_deflectrate_pr = [pooled_deflectrate_pr deflectrate_pr];
    
    % average size of deflections (deviations above threshold) for both conditions
    deflectmag_npr = nanmean(npr_devs(npr_devs > deflect_thresh));
    deflectmag_pr = nanmean(pr_devs(pr_devs > deflect_thresh));
    
    pooled_deflectmag_npr = [pooled_deflectmag_npr deflectmag_npr];
    pooled_deflectmag_pr = [pooled_deflectmag_pr deflectmag_pr];

end
figure(v)
yline(deflect_thresh);
xlim([0.5 num_subjects+0.5])
xlabel('Participant')
ylabel('Max deviation')
% legend(plotdata, {'no primer', 'primer'})
title(sprintf('Saccade task block %d, by participant', block))
xticks(1:num_subjects)
for ss = 1:num_subjects
    labels{ss} = num2str(ss);
end
xticklabels(labels);

dr_noprimer_avg = nanmean(pooled_deflectrate_npr);
dr_noprimer_se = nanstd(pooled_deflectrate_npr)/sqrt(length(pooled_deflectrate_npr));
dr_primer_avg = nanmean(pooled_deflectrate_pr);
dr_primer_se = nanstd(pooled_deflectrate_pr)/sqrt(length(pooled_deflectrate_pr));

dm_noprimer_avg = nanmean(pooled_deflectmag_npr);
dm_noprimer_se = nanstd(pooled_deflectmag_npr)/sqrt(length(pooled_deflectmag_npr));
dm_primer_avg = nanmean(pooled_deflectmag_pr);
dm_primer_se = nanstd(pooled_deflectmag_pr)/sqrt(length(pooled_deflectmag_pr));

[~, dr_pooled_p] = ttest(pooled_deflectrate_npr, pooled_deflectrate_pr);
[~, dm_pooled_p] = ttest(pooled_deflectmag_npr, pooled_deflectmag_pr);

% pooled_p = signrank(pooled_noprimer_rt, pooled_primer_rt);
colors = jet(num_subjects);

figure
hold on
% bar(1:2, bar_vector, 1);
for dd = 1:length(pooled_deflectrate_npr)
    plot(1:2, [pooled_deflectrate_npr(dd) pooled_deflectrate_pr(dd)], 'k');
    scatter(1, pooled_deflectrate_npr(dd), 'filled', 'MarkerFaceColor', colors(dd, :));
    scatter(2, pooled_deflectrate_pr(dd), 'filled', 'MarkerFaceColor', colors(dd, :));
end
scatter(1, dr_noprimer_avg, 'filled', 'k');
scatter(2, dr_primer_avg, 'filled', 'k');
errorbar(1:2, [dr_noprimer_avg dr_primer_avg], [dr_noprimer_se dr_primer_se], '.');
text(1.5, max([dr_noprimer_avg dr_primer_avg]) + 5, sprintf('p = %0.3f', dr_pooled_p));
xlabel('Condition')
xlim([0 3])
ylabel('Deflection frequency')
xticks([1 2])
xticklabels({'no primer', 'primer'})
title(sprintf('Saccade task block %d, pooled data', block))

figure
hold on
% bar(1:2, bar_vector, 1);
for dd = 1:length(pooled_deflectmag_npr)
    plot(1:2, [pooled_deflectmag_npr(dd) pooled_deflectmag_pr(dd)], 'k');
    scatter(1, pooled_deflectmag_npr(dd), 'filled', 'MarkerFaceColor', colors(dd, :));
    scatter(2, pooled_deflectmag_pr(dd), 'filled', 'MarkerFaceColor', colors(dd, :));
end
scatter(1, dm_noprimer_avg, 'filled', 'k');
scatter(2, dm_primer_avg, 'filled', 'k');
errorbar(1:2, [dm_noprimer_avg dm_primer_avg], [dm_noprimer_se dm_primer_se], '.');
text(1.5, double(max([dm_noprimer_avg dm_primer_avg]) + 50), sprintf('p = %0.3f', dm_pooled_p));
xlabel('Condition')
xlim([0 3])
ylabel('Deflection magnitude')
xticks([1 2])
xticklabels({'no primer', 'primer'})
title(sprintf('Saccade task block %d, pooled data', block))
