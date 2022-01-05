clear
%% import data
% each file is one participant
[fn, ~] = uigetfile('.mat', 'MultiSelect', 'on');

if iscell(fn)
    num_subjects = length(fn);
else
    num_subjects = 1;
end 

mistrial_thresh = 3;         % std above mean, to consider excluded trials
min_rt = 0.1;                   % min reaction time
max_rt = 1;                     % max reaction time
% store each subject as an entry in a struct
if num_subjects > 1
    data = struct();

    for nn = 1:num_subjects
        currdata = importdata(fn{nn});
        fields = fieldnames(currdata);
        for ff = 1:length(fields)
            data(nn).(fields{ff}) = currdata.(fields{ff});
        end
    end
else
    data = importdata(fn);
end

etdata = cell(1, num_subjects);        % eyetracking data, each cell is one subject
rtdata = cell(1, num_subjects);        % reaction time data, each cell is one subject
trialdata = cell(1, num_subjects);     % trial structure data

for nn = 1:num_subjects
    % get eyetracking data
    etdata{nn} = data(nn).ETdata;

    % get reaction time and trial structure data
    % [total trials x 7] column 1: block, 2: trial, 3: cue loc, 4: sacc/antisacc, ...
    % 5: primer (0 none, 1 target loc, 2 non-target loc), 6: pretrial RT, 7: trial RT
    rtdata{nn} = data(nn).exptData(:, 7);
    trialdata{nn} = data(nn).exptData(:, 1:5);
end


%% plotting reaction times for individual subjects
figure
hold on
offset = 0.2;
pooled_primer_rt = [];
pooled_noprimer_rt = [];

for ii = 1:num_subjects
    curr_trialdata = trialdata{ii};
    curr_rtdata = rtdata{ii};    

    % get trials where primer was presented
    primer_trials = curr_trialdata(:, 5) == 1;
    
    % reaction times for primer and no primer conditions
    primer_rt = curr_rtdata(primer_trials);
    noprimer_rt = curr_rtdata(~primer_trials);

    % get rid of outliers (mistrials)
    primer_rt = exclude_outliers(primer_rt, mistrial_thresh, min_rt, max_rt);
    noprimer_rt = exclude_outliers(noprimer_rt, mistrial_thresh, min_rt, max_rt);
    
    % pool data (need to pool averages)
%     pooled_primer_rt = cat(1, pooled_primer_rt, primer_rt);           % this is wrong because of nested data
%     pooled_noprimer_rt = cat(1, pooled_noprimer_rt, noprimer_rt);
    
    % calculate avg rts with and without primer
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
title('Simple saccade task, by participant')
xticks(1:num_subjects)
for ss = 1:num_subjects
    labels{ss} = num2str(ss);
end
xticklabels(labels);

%% plotting rt data pooled across participants

rt_noprimer_avg = mean(pooled_noprimer_rt);
rt_noprimer_se = std(pooled_noprimer_rt)/sqrt(length(pooled_noprimer_rt));
rt_primer_avg = mean(pooled_primer_rt);
rt_primer_se = std(pooled_primer_rt)/sqrt(length(pooled_primer_rt));


bar_vector = [rt_noprimer_avg rt_primer_avg];
error_vector = [rt_noprimer_se rt_primer_se];
pooled_p = signrank(pooled_noprimer_rt, pooled_primer_rt);

figure
hold on
bar(1:2, bar_vector, 1);
errorbar(1:2, bar_vector, error_vector, '.');
text(1.5, max([rt_noprimer_avg rt_primer_avg]) + 0.025, sprintf('p = %0.3f', pooled_p));
xlabel('Condition')
ylabel('Mean reaction time (s)')
xticks([1 2])
xticklabels({'no primer', 'primer'})
title('Simple saccade task, pooled data')


    

