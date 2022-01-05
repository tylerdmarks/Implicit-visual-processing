function [outvec, included_idx] = exclude_outliers(invec, thresh, min, max)
    % returns elements of invec that are thresh times the std above the mean of invec
    included_idx = invec < mean(invec)+thresh*std(invec);
    if nargin > 2
        included_idx = included_idx & invec >= min & invec <= max;
    end
    outvec = invec(included_idx);
end