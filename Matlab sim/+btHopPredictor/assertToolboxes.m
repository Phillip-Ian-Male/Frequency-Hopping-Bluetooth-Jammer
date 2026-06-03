function assertToolboxes(cfg)
%ASSERTTOOLBOXES Check that required MATLAB products/functions are available.

arguments
    cfg (1,1) struct
end

missing = strings(0, 1);

if exist("bluetoothFrequencyHop", "class") ~= 8 && exist("bluetoothFrequencyHop", "file") ~= 2
    missing(end + 1) = "Bluetooth Toolbox function/class bluetoothFrequencyHop";
end

if isfield(cfg, "RequireWaveformGenerator") && cfg.RequireWaveformGenerator
    if exist("bluetoothWaveformGenerator", "file") ~= 2
        missing(end + 1) = "Bluetooth Toolbox function bluetoothWaveformGenerator";
    end
end

if exist("trainNetwork", "file") ~= 2
    missing(end + 1) = "Deep Learning Toolbox function trainNetwork";
end

if ~isempty(missing)
    separator = sprintf('\n  - ');
    error("Missing required MATLAB capability:\n  - %s", strjoin(missing, separator));
end

if isfield(cfg, "UseGPU") && any(strcmpi(string(cfg.UseGPU), ["gpu", "true"]))
    env = btHopPredictor.resolveExecutionEnvironment(cfg.UseGPU);
    if env == "cpu"
        warning("GPU was requested, but MATLAB could not initialize one. Training will fail or fall back to CPU depending on options.");
    end
end
end
