function new_XYdata = convertOldETdata(old_XYdata, exptData)
    % old_XYdata is the old format of eyetracking data
    % rows = time, col 1 = block, col 2 = trial, col 3 = x, col 4 = y
    % exptData is the reaction time data file
    % each row is 1 trial
    % col 1 = block, col 2 = trial, col 3 = cue dir, col 4 = prosac/antisac, col 5 = primer pres, col 6 = pretrial RT, col 7 = trial RT
    % used to instruct structure of new_XYdata
    
    new_XYdata = struct();      % [1 x numBlocks] struct with field(s) pretrialXY (not in old data) and trialXY, (1 x numTrials) cell arrays with x y data
    
    numBlocks = exptData(end, 1);
    for bb = 1:numBlocks
        numTrials = sum(exptData(:, 1) == bb);
        new_XYdata(bb).trialXY = cell(1, numTrials);
        for tt = 1:numTrials
            new_XYdata(bb).trialXY{tt} = old_XYdata(old_XYdata(:, 1) == bb & old_XYdata(:, 2) == tt, 3:4);
        end
    end
end
    

    
    