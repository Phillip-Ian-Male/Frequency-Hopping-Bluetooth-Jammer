function X = encodeWindow(channels, cfg, slotIndex, clockValues, deviceAddress)
%ENCODEWINDOW Convert channel observations into one sequence-model input.

arguments
    channels (:,1) double
    cfg (1,1) struct
    slotIndex (:,1) double = (0:numel(channels) - 1).'
    clockValues (:,1) double = zeros(numel(channels), 1)
    deviceAddress (1,1) string = "000000000000"
end

channels = round(channels(:));
if any(channels < 0) || any(channels > 78)
    error("Channel indices must be in [0, 78].");
end

windowLength = numel(channels);
slotIndex = slotIndex(:);
clockValues = clockValues(:);

includeDeltas = getLogical(cfg, "IncludeDeltas", true);
includeClockPhase = getLogical(cfg, "IncludeClockPhase", true);
featureMode = getString(cfg, "FeatureMode", "sequenceOnly");
clockMods = getNumeric(cfg, "ClockModuloFeatures", [2 4 8 16 32]);

numFeatures = 79 + 1;
if includeDeltas
    numFeatures = numFeatures + 1;
end
if includeClockPhase
    numFeatures = numFeatures + 2 * numel(clockMods);
end
if strcmpi(featureMode, "oracleFeatures")
    numFeatures = numFeatures + 28 + 24;
end

X = zeros(numFeatures, windowLength, "single");

rowIdx = channels.' + 1;
colIdx = 1:windowLength;
X(sub2ind(size(X), rowIdx, colIdx)) = 1;

row = 80;
X(row, :) = single(channels.' / 78);
row = row + 1;

if includeDeltas
    channelDelta = [0; diff(channels)];
    channelDelta = mod(channelDelta + 39, 79) - 39;
    X(row, :) = single(channelDelta.' / 39);
    row = row + 1;
end

if includeClockPhase
    for modIdx = 1:numel(clockMods)
        m = clockMods(modIdx);
        phase = 2 * pi * mod(slotIndex(:).', m) / m;
        X(row, :) = single(sin(phase));
        X(row + 1, :) = single(cos(phase));
        row = row + 2;
    end
end

if strcmpi(featureMode, "oracleFeatures")
    for bitIdx = 1:28
        X(row, :) = single(bitget(uint32(clockValues(:).'), bitIdx));
        row = row + 1;
    end

    addressBits = lowerAddressBits(deviceAddress, 24);
    X(row:(row + 23), :) = repmat(addressBits, 1, windowLength);
end
end

function value = getLogical(cfg, fieldName, defaultValue)
if isfield(cfg, fieldName)
    value = logical(cfg.(fieldName));
else
    value = defaultValue;
end
end

function value = getString(cfg, fieldName, defaultValue)
if isfield(cfg, fieldName)
    value = string(cfg.(fieldName));
else
    value = string(defaultValue);
end
end

function value = getNumeric(cfg, fieldName, defaultValue)
if isfield(cfg, fieldName)
    value = double(cfg.(fieldName));
else
    value = defaultValue;
end
end

function bits = lowerAddressBits(address, numBits)
address = upper(char(address));
address = regexprep(address, '[^0-9A-F]', '');
if isempty(address)
    address = '0';
end

numHex = ceil(numBits / 4);
if numel(address) < numHex
    address = [repmat('0', 1, numHex - numel(address)), address];
end

hexPart = address((end - numHex + 1):end);
value = uint32(hex2dec(hexPart));

bits = zeros(numBits, 1, "single");
for bitIdx = 1:numBits
    bits(bitIdx) = single(bitget(value, bitIdx));
end
end
