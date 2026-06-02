function trace = generateHopTrace(cfg, opts)
%GENERATEHOPTRACE Generate a simulated Bluetooth Classic BR/EDR hop trace.

arguments
    cfg (1,1) struct
    opts.NumHops (1,1) double {mustBeInteger, mustBePositive} = cfg.HopsPerSequence
    opts.DeviceAddress (1,1) string = btHopPredictor.randomDeviceAddress()
    opts.InitialClock (1,1) double {mustBeInteger, mustBeNonnegative} = randi([0, 2^28 - 1], 1, 1)
    opts.UsedChannels (1,:) double = btHopPredictor.makeUsedChannels(cfg)
end

freqHop = bluetoothFrequencyHop;
freqHop.SequenceType = char(cfg.SequenceType);
freqHop.DeviceAddress = char(opts.DeviceAddress);

if strcmpi(string(cfg.SequenceType), "Connection adaptive")
    freqHop.UsedChannels = double(opts.UsedChannels);
end

numHops = opts.NumHops;
modulus = 2^28;
clockValues = mod(opts.InitialClock + (0:numHops - 1).', modulus);
channelIndex = zeros(numHops, 1);
xControl = zeros(numHops, 1);

for k = 1:numHops
    [channelIndex(k), xControl(k)] = nextHop(freqHop, clockValues(k));
end

trace = struct;
trace.ChannelIndex = double(channelIndex);
trace.FrequencyMHz = btHopPredictor.channelToFrequencyMHz(channelIndex);
trace.X = double(xControl);
trace.Clock = double(clockValues);
trace.RelativeSlot = (0:numHops - 1).';
trace.DeviceAddress = opts.DeviceAddress;
trace.UsedChannels = double(opts.UsedChannels);
trace.SequenceType = string(cfg.SequenceType);
trace.InitialClock = double(opts.InitialClock);
end

