function startup
%STARTUP Add this simulation package to the MATLAB path.

rootDir = fileparts(mfilename("fullpath"));
addpath(rootDir);
addpath(fullfile(rootDir, "scripts"));

fprintf("Bluetooth Classic hop predictor simulation package loaded.\n");
fprintf("Root: %s\n", rootDir);
end

