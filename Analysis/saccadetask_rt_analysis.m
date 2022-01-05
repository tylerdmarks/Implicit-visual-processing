%% import data
clear
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
    % get reaction time and trial structure data
    % [total trials x 7] column 1: block, 2: trial, 3: cue loc, 4: sacc/antisacc, ...
    % 5: primer (0 none, 1 target loc, 2 non-target loc), 6: pretrial RT, 7: trial RT
    rtdata{nn} = data(nn).exptData(:, 7);
    trialdata{nn} = data(nn).exptData(:, 1:5);
    timing{nn} = data(nn).timing;
end


%% plotting reaction times 

%% BLOCKS 1 & 3  (50/50)
block = 2;
figure
hold on
offset = 0.2;
pooled_noprimer_rt = [];
pooled_primer_rt = [];

for ii = 1:num_subjects
    curr_trialdata = trialdata{ii};
    curr_rtdata = rtdata{ii};
    
    block_idx = curr_trialdata(:, 1) == block;
    % get trials where primer was presented
    primer_trials = curr_trialdata(:, 5) == 1 & block_idx;
    noprimer_trials = curr_trialdata(:, 5) == 0 & block_idx;
    
    % reaction times for primer and no primer conditions
    primer_rt = curr_rtdata(primer_trials);
    noprimer_rt = curr_rtdata(noprimer_trials);

    % get rid of outliers (mistrials)
    % outliers are considered greater than k standard deviations above the mean
    primer_rt = exclude_outliers(primer_rt, mistrial_thresh, min_rt, max_rt);
    noprimer_rt = exclude_outliers(noprimer_rt, mistrial_thresh, min_rt, max_rt);
    
    % pool data
    pooled_noprimer_rt = [pooled_noprimer_rt mean(noprimer_rt)];
    pooled_primer_rt = [pooled_primer_rt mean(primer_rt)];

    % overlay violin plots of individual points
    violinplot(ii-offset, noprimer_rt, {sprintf('%d', ii)}, 'Width', 0.2, 'ViolinColor', [0.5 0.8 0.1], 'DataAlpha', 0.4, 'ViolinAlpha', 0.1);
    violinplot(ii+offset, primer_rt, {sprintf('%d', ii)}, 'Width', 0.2, 'ViolinColor', [0.3 0.2 0.9], 'DataAlpha', 0.4, 'ViolinAlpha', 0.1);
  
    p(ii) = ranksum(noprimer_rt, primer_rt);
    text(ii, max([max(noprimer_rt) max(primer_rt)]), sprintf('p = %0.3f', p(ii)));
    
    
end
xlim([0.5 num_subjects+0.5])
xlabel('Participant')
ylabel('Reaction time (s)')
% legend(plotdata, {'no primer', 'primer'})
title(sprintf('Saccade task block %d, by participant', block))
xticks(1:num_subjects)
for ss = 1:num_subjects
    labels{ss} = num2str(ss);
end
xticklabels(labels);
ylim([0 0.8])

% plotting rt data pooled across participants

rt_noprimer_avg = mean(pooled_noprimer_rt);
rt_noprimer_se = std(pooled_noprimer_rt)/sqrt(length(pooled_noprimer_rt));
rt_primer_avg = mean(pooled_primer_rt);
rt_primer_se = std(pooled_primer_rt)/sqrt(length(pooled_primer_rt));

bar_vector = [rt_noprimer_avg rt_primer_avg];
error_vector = [rt_noprimer_se rt_primer_se];
[~, pooled_p] = ttest(pooled_noprimer_rt, pooled_primer_rt);
% pooled_p = signrank(pooled_noprimer_rt, pooled_primer_rt);
colors = jet(num_subjects);
figure
hold on
% bar(1:2, bar_vector, 1);
for dd = 1:length(pooled_noprimer_rt)
    plot(1:2, [pooled_noprimer_rt(dd) pooled_primer_rt(dd)], 'k');
    scatter(1, pooled_noprimer_rt(dd), 'filled', 'MarkerFaceColor', colors(dd, :));
    scatter(2, pooled_primer_rt(dd), 'filled', 'MarkerFaceColor', colors(dd, :));
end
scatter(1, rt_noprimer_avg, 'filled', 'k');
scatter(2, rt_primer_avg, 'filled', 'k');
errorbar(1:2, bar_vector, error_vector, '.');
text(1.5, max([rt_noprimer_avg rt_primer_avg]) + 0.025, sprintf('p = %0.3f', pooled_p));
xlabel('Condition')
xlim([0 3])
ylim([0.16 0.3])
ylabel('Mean reaction time (s)')
xticks([1 2])
xticklabels({'no primer', 'primer'})
title(sprintf('Saccade task block %d, pooled data', block))


%% BLOCK 2 & 4
block = 4;
figure
hold on
offset = 0.3;
pooled_noprimer_rt = [];
pooled_primer_rt = [];
pooled_antiprimer_rt = [];

for ii = 1:num_subjects
    curr_trialdata = trialdata{ii};
    curr_rtdata = rtdata{ii};
    
    block_idx = curr_trialdata(:, 1) == block;
    % get trials where primer was presented
    primer_trials = curr_trialdata(:, 5) == 1 & block_idx;
    noprimer_trials = curr_trialdata(:, 5) == 0 & block_idx;
    antiprimer_trials = curr_trialdata(:, 5) == 2 & block_idx;
    
    % reaction times for primer and no primer conditions
    primer_rt = curr_rtdata(primer_trials);
    noprimer_rt = curr_rtdata(noprimer_trials);
    antiprimer_rt = curr_rtdata(antiprimer_trials);

    % get rid of outliers (mistrials)
    primer_rt = exclude_outliers(primer_rt, mistrial_thresh, min_rt, max_rt);
    noprimer_rt = exclude_outliers(noprimer_rt, mistrial_thresh, min_rt, max_rt);
    antiprimer_rt = exclude_outliers(antiprimer_rt, mistrial_thresh, min_rt, max_rt);
    
    % pool data
    pooled_noprimer_rt = [pooled_noprimer_rt mean(noprimer_rt)];
    pooled_primer_rt = [pooled_primer_rt mean(primer_rt)];
    pooled_antiprimer_rt = [pooled_antiprimer_rt mean(antiprimer_rt)];

    % overlay violin plots of individual points
    violinplot(ii-offset, noprimer_rt, {sprintf('%d', ii)}, 'Width', 0.15, 'ViolinColor', [0.5 0.8 0.1], 'DataAlpha', 0.4, 'ViolinAlpha', 0.1);
    violinplot(ii, primer_rt, {sprintf('%d', ii)}, 'Width', 0.15, 'ViolinColor', [0.3 0.2 0.9], 'DataAlpha', 0.4, 'ViolinAlpha', 0.1);
    violinplot(ii+offset, antiprimer_rt, {sprintf('%d', ii)}, 'Width', 0.15, 'ViolinColor', [0.8 0.4 0.3], 'DataAlpha', 0.4, 'ViolinAlpha', 0.1);

    p_nvsp(ii) = ranksum(noprimer_rt, primer_rt);
    p_nvsap(ii) = ranksum(noprimer_rt, antiprimer_rt);
    p_pvsap(ii) = ranksum(primer_rt, antiprimer_rt);
%     text(ii, max(noprimer_rt)+0.05, sprintf('p1v2 = %0.3f', p_nvsp(ii)));
%     text(ii, max(noprimer_rt), sprintf('p1v3 = %0.3f', p_nvsap(ii)));
%     text(ii, max(noprimer_rt)-0.05, sprintf('p2v3 = %0.3f', p_pvsap(ii)));
   
end
xlim([0.5 num_subjects+0.5])
xlabel('Participant')
ylabel('Reaction time (s)')
% legend(plotdata, {'no primer', 'primer'})
title(sprintf('Saccade task block %d, by participant', block))
xticks(1:num_subjects)
for ss = 1:num_subjects
    labels{ss} = num2str(ss);
end
xticklabels(labels);

% plotting rt data pooled across participants

rt_noprimer_avg = mean(pooled_noprimer_rt);
rt_noprimer_se = std(pooled_noprimer_rt)/sqrt(length(pooled_noprimer_rt));
rt_primer_avg = mean(pooled_primer_rt);
rt_primer_se = std(pooled_primer_rt)/sqrt(length(pooled_primer_rt));
rt_antiprimer_avg = mean(pooled_antiprimer_rt);
rt_antiprimer_se = std(pooled_antiprimer_rt)/sqrt(length(pooled_antiprimer_rt));

bar_vector = [rt_noprimer_avg rt_primer_avg rt_antiprimer_avg];
error_vector = [rt_noprimer_se rt_primer_se rt_antiprimer_se];
pooled_p_1v2 = signrank(pooled_noprimer_rt, pooled_primer_rt);
pooled_p_1v3 = signrank(pooled_noprimer_rt, pooled_antiprimer_rt);
pooled_p_2v3 = signrank(pooled_primer_rt, pooled_antiprimer_rt);

figure
hold on
bar(1:3, bar_vector, 1);
errorbar(1:3, bar_vector, error_vector, '.');
% text(1.5, rt_noprimer_avg + 0.075, sprintf('p = %0.3f', pooled_p_1v2));
% text(1.5, rt_noprimer_avg + 0.05, sprintf('p = %0.3f', pooled_p_1v3));
% text(1.5, rt_noprimer_avg + 0.025, sprintf('p = %0.3f', pooled_p_2v3));
ylim([0 rt_noprimer_avg + 0.2])
xlabel('Condition')
ylabel('Mean reaction time (s)')
xticks([1 2 3])
xticklabels({'no primer', 'primer', 'antiprimer'})
title(sprintf('Saccade task block %d, pooled data', block))

    
    
    

