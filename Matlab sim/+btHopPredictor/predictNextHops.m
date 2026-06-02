function prediction = predictNextHops(net, observedChannels, cfg, opts)
%PREDICTNEXTHOPS Predict top-k next channels from one simulated observation window.

arguments
    net
    observedChannels (:,1) double
    cfg (1,1) struct
    opts.TopK (1,1) double {mustBeInteger, mustBePositive} = 5
    opts.InitialClock (1,1) double {mustBeInteger, mustBeNonnegative} = 0
    opts.DeviceAddress (1,1) string = "000000000000"
end

if numel(observedChannels) < cfg.WindowLength
    error("Need at least cfg.WindowLength observed channels.");
end

window = observedChannels((end - cfg.WindowLength + 1):end);
slotIndex = (numel(observedChannels) - cfg.WindowLength):(numel(observedChannels) - 1);
clockValues = mod(opts.InitialClock + slotIndex(:), 2^28);

X = {btHopPredictor.encodeWindow(window, cfg, slotIndex(:), clockValues, opts.DeviceAddress)};
env = btHopPredictor.resolveExecutionEnvironment(cfg.UseGPU);

scores = predict(net, X, ...
    "MiniBatchSize", 1, ...
    "SequenceLength", "longest", ...
    "ExecutionEnvironment", env);
scores = scores(:).';

[scoreSorted, order] = sort(scores, "descend");
topK = min(opts.TopK, numel(order));
channels = order(1:topK) - 1;

prediction = struct;
prediction.ChannelIndex = channels(:);
prediction.FrequencyMHz = btHopPredictor.channelToFrequencyMHz(channels(:));
prediction.Score = scoreSorted(1:topK).';
prediction.ExecutionEnvironment = env;
end

