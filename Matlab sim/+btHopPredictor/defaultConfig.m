function cfg = defaultConfig(preset)
%DEFAULTCONFIG Return simulation, training, and deployment settings.

arguments
    preset (1,1) string {mustBeMember(preset, ["smoke", "desktop", "rtx4070", "embedded"])} = "desktop"
end

cfg = struct;
cfg.Preset = preset;

% Bluetooth Classic hop simulation.
cfg.SequenceType = "Connection adaptive";
cfg.DeviceAddressMode = "randomPerSequence";
cfg.FixedDeviceAddress = "2A96EF25ABCD";
cfg.UsedChannelsMode = "randomAFH";
cfg.StaticUsedChannels = 0:78;
cfg.MinUsedChannels = 45;
cfg.MaxUsedChannels = 79;
cfg.HopsPerSecond = 1600;

% Dataset construction.
cfg.NumSequences = 512;
cfg.HopsPerSequence = 384;
cfg.WindowLength = 48;
cfg.WindowStride = 2;
cfg.PredictionHorizon = 1;
cfg.FeatureMode = "sequenceOnly";
cfg.IncludeDeltas = true;
cfg.IncludeClockPhase = true;
cfg.ClockModuloFeatures = [2 4 8 16 32];
cfg.RngSeed = 402;

% Neural network.
cfg.PredictorType = "lstm";
cfg.NumRecurrentLayers = 2;
cfg.HiddenUnits = 160;
cfg.DenseUnits = 128;
cfg.Dropout = 0.15;
cfg.NumClasses = 79;

% Training.
cfg.MaxEpochs = 12;
cfg.MiniBatchSize = 256;
cfg.InitialLearnRate = 1e-3;
cfg.L2Regularization = 1e-4;
cfg.GradientThreshold = 1;
cfg.ValidationFrequency = 100;
cfg.TrainingPlots = "none";
cfg.UseGPU = "auto";
cfg.Verbose = true;

% IO.
cfg.ModelDir = "models";
cfg.ResultDir = "results";
cfg.RequireWaveformGenerator = true;

switch preset
    case "smoke"
        cfg.NumSequences = 48;
        cfg.HopsPerSequence = 128;
        cfg.WindowLength = 24;
        cfg.WindowStride = 4;
        cfg.NumRecurrentLayers = 1;
        cfg.HiddenUnits = 64;
        cfg.DenseUnits = 64;
        cfg.MaxEpochs = 2;
        cfg.MiniBatchSize = 64;
        cfg.ValidationFrequency = 20;
        cfg.UseGPU = "auto";

    case "desktop"
        cfg.NumSequences = 512;
        cfg.HopsPerSequence = 384;
        cfg.WindowLength = 48;
        cfg.WindowStride = 2;
        cfg.HiddenUnits = 160;
        cfg.DenseUnits = 128;
        cfg.MaxEpochs = 12;
        cfg.MiniBatchSize = 256;

    case "rtx4070"
        cfg.NumSequences = 768;
        cfg.HopsPerSequence = 768;
        cfg.WindowLength = 64;
        cfg.WindowStride = 2;
        cfg.NumRecurrentLayers = 2;
        cfg.HiddenUnits = 256;
        cfg.DenseUnits = 256;
        cfg.Dropout = 0.20;
        cfg.MaxEpochs = 35;
        cfg.MiniBatchSize = 512;
        cfg.ValidationFrequency = 200;
        cfg.UseGPU = "gpu";

    case "embedded"
        cfg.NumSequences = 256;
        cfg.HopsPerSequence = 256;
        cfg.WindowLength = 24;
        cfg.WindowStride = 2;
        cfg.NumRecurrentLayers = 1;
        cfg.HiddenUnits = 48;
        cfg.DenseUnits = 64;
        cfg.Dropout = 0.05;
        cfg.MaxEpochs = 10;
        cfg.MiniBatchSize = 128;
end
end

