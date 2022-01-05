function ETcoords = getETdata(evt)
    % Get eye data
    if evt.gx(2) > 0
        ETcoords.x = evt.gx(2);
        ETcoords.y = evt.gy(2);
    else 
        ETcoords.x = evt.gx(1);
        ETcoords.y = evt.gy(1);
    end
end