function patched = patch_trajectory(traj)

    for tt = 2:length(traj)
        if traj(tt) > traj(tt-1) + 0.8*traj(tt-1) || traj(tt) < traj(tt-1) - 0.8*traj(tt-1)
            traj(tt) = NaN;
        end
    end

%     m = median(traj);
%     % consider points that are 3x the mode above or below the mean as points that need fixing 
%     bad_points = find(traj >= m+1.5*m | traj <= m-1.5*m);
%     
%     for pt = 1:length(bad_points)
%         % replace each bad point with the previous point in a sequential manner
%         traj(bad_points(pt)) = traj(bad_points(pt)-1);
%     end
    
    patched = traj;
end
    