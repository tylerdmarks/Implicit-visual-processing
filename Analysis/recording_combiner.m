function data = recording_combiner(label)
% for pooling data within subjects

% import data
[fn, ~] = uigetfile('.mat', 'MultiSelect', 'on');


for nn = 1:length(fn)
    currdata = importdata(fn{nn});
    
    if nn == 1
        data.mask_method = currdata.mask_method;
        data.pattern_type = currdata.pattern_type;
        data.param = currdata.param;
        data.stim = currdata.stim;
        data.ETdata = currdata.ETdata;
        data.exptData = currdata.exptData;
    else
        data.mask_method = [data.mask_method currdata.mask_method];
        data.pattern_type = [data.pattern_type currdata.pattern_type];
        try
        data.param = [data.param currdata.param];
        catch
        end
        data.stim = [data.stim currdata.stim];
        
        % pool exptData
        num_blocks = data.exptData(end, 1);
        for bb = 1:num_blocks
            % find number of trials that have already been pooled for this block
            pooled_numtrials = length(data.exptData(data.exptData(:, 1) == bb, 2));
            % find number of trials to add to pooled data for this block
            curr_numtrials = length(currdata.exptData(currdata.exptData(:, 1) == bb, 2));
            % get new trial numbers for the added trials based on how many have already been added 
            new_trialidx = pooled_numtrials+1:pooled_numtrials+curr_numtrials;
            % get current chunk of data to be added
            new_exptData = currdata.exptData(currdata.exptData(:, 1) == bb, :);
            % change trial numbers for the new chunk of data
            new_exptData(:, 2) = new_trialidx;
            % concatenate the new chunk of data onto the end of pooled exptData
            data.exptData = cat(1, data.exptData, new_exptData);
        end
        
        % pool ETdata
        for bb = 1:num_blocks
            data.ETdata(bb).trialXY = [data.ETdata(bb).trialXY currdata.ETdata(bb).trialXY];
            if any(strcmp(fieldnames(data.ETdata), 'pretrialXY'))
                data.ETdata(bb).pretrialXY = [data.ETdata(bb).pretrialXY currdata.ETdata(bb).pretrialXY];
            end
        end

    end
    
    
        
    
    
end

fname = sprintf('%s_combineddata.mat', label);
save(fname, 'data');

end