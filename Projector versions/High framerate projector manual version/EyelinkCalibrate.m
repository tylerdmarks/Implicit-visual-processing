function EyelinkCalibrate(el)
  
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);

    % Check calibration using drift correction
    EyelinkDoDriftCorrection(el);
end