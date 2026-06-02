function data = generateDataset(cfg)
%GENERATEDATASET Build a windowed sequence dataset from simulated hop traces.

arguments
    cfg (1,1) struct
end

rng(cfg.RngSeed);

numWindowsPerSequence = floor((cfg.HopsPerSequence - cfg.WindowLength - cfg.PredictionHorizon) / cfg.WindowStride) + 1;
if numWindowsPerSequence < 1
    error("HopsPerSequence must exceed WindowLength + PredictionHorizon.");
end

numObservations = cfg.NumSequences * numWindowsPerSequence;
X = cell(numObservations, 1);
labelStrings = strings(numObservations, 1);
sequenceId = zeros(numObservations, 1);
targetClock = zeros(numObservations, 1);

obs = 0;
for seqIdx = 1:cfg.NumSequences
    if strcmpi(string(cfg.DeviceAddressMode), "fixed")
        address = string(cfg.FixedDeviceAddress);
    else
        address = btHopPredictor.randomDeviceAddress();
    end

    usedChannels = btHopPredictor.makeUsedChannels(cfg);
    initialClock = randi([0, 2^28 - 1], 1, 1);
    trace = btHopPredictor.generateHopTrace(cfg, ...
        NumHops = cfg.HopsPerSequence, ...
        DeviceAddress = address, ...
        InitialClock = initialClock, ...
        UsedChannels = usedChannels);

    starts = 1:cfg.WindowStride:(cfg.HopsPerSequence - cfg.WindowLength - cfg.PredictionHorizon + 1);
    for startIdx = starts
        obs = obs + 1;
        inputIdx = startIdx:(startIdx + cfg.WindowLength - 1);
        targetIdx = startIdx + cfg.WindowLength + cfg.PredictionHorizon - 1;

        X{obs} = btHopPredictor.encodeWindow( ...
            trace.ChannelIndex(inputIdx), cfg, ...
            trace.RelativeSlot(inputIdx), ...
            trace.Clock(inputIdx), ...
            trace.DeviceAddress);

        labelStrings(obs) = string(trace.ChannelIndex(targetIdx));
        sequenceId(obs) = seqIdx;
        targetClock(obs) = trace.Clock(targetIdx);
    end

    if isfield(cfg, "Verbose") && cfg.Verbose && mod(seqIdx, max(1, floor(cfg.NumSequences / 10))) == 0
        fprintf("Generated %d/%d traces (%d observations)\n", seqIdx, cfg.NumSequences, obs);
    end
end

classNames = string(0:78);

data = struct;
data.X = X;
data.Y = categorical(labelStrings, classNames);
data.Meta = struct;
data.Meta.NumObservations = numObservations;
data.Meta.NumSequences = cfg.NumSequences;
data.Meta.NumFeatures = size(X{1}, 1);
data.Meta.NumClasses = 79;
data.Meta.WindowLength = cfg.WindowLength;
data.Meta.SequenceType = string(cfg.SequenceType);
data.Meta.FeatureMode = string(cfg.FeatureMode);
data.Meta.SequenceId = sequenceId;
data.Meta.TargetClock = targetClock;
data.Meta.ClassNames = classNames;
end

