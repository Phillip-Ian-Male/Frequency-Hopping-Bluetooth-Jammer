function burst = generateWaveformBurst(channelIndex, opts)
%GENERATEWAVEFORMBURST Generate an optional BR/EDR baseband waveform preview.

arguments
    channelIndex (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(channelIndex, 0), mustBeLessThanOrEqual(channelIndex, 78)}
    opts.DeviceAddress (1,1) string = "2A96EF25ABCD"
    opts.PacketType (1,1) string = "DH1"
    opts.Mode (1,1) string = "BR"
    opts.SamplesPerSymbol (1,1) double {mustBeInteger, mustBePositive} = 8
    opts.NumPackets (1,1) double {mustBeInteger, mustBePositive} = 1
end

cfgWaveform = bluetoothWaveformConfig;
cfgWaveform.PacketType = char(opts.PacketType);
cfgWaveform.Mode = char(opts.Mode);

if isprop(cfgWaveform, "DeviceAddress")
    cfgWaveform.DeviceAddress = char(opts.DeviceAddress);
end

if isprop(cfgWaveform, "SamplesPerSymbol")
    cfgWaveform.SamplesPerSymbol = opts.SamplesPerSymbol;
end

payloadBytes = getPayloadLength(cfgWaveform);
if payloadBytes <= 0
    error("Packet type %s has no payload for waveform generation.", opts.PacketType);
end

dataBits = randi([0 1], payloadBytes * 8 * opts.NumPackets, 1);
waveform = bluetoothWaveformGenerator(dataBits, cfgWaveform);

burst = struct;
burst.Waveform = waveform;
burst.Config = cfgWaveform;
burst.ChannelIndex = channelIndex;
burst.CenterFrequencyMHz = btHopPredictor.channelToFrequencyMHz(channelIndex);
burst.SampleRate = opts.SamplesPerSymbol * 1e6;
burst.DataBits = dataBits;
end

