function [trainData, valData, testData] = splitDataset(data, trainFraction, valFraction)
%SPLITDATASET Randomly split a generated dataset.

arguments
    data (1,1) struct
    trainFraction (1,1) double {mustBeGreaterThanOrEqual(trainFraction, 0), mustBeLessThanOrEqual(trainFraction, 1)} = 0.8
    valFraction (1,1) double {mustBeGreaterThanOrEqual(valFraction, 0), mustBeLessThanOrEqual(valFraction, 1)} = 0.1
end

n = numel(data.X);
if trainFraction + valFraction > 1
    error("trainFraction + valFraction must be <= 1.");
end

idx = randperm(n);
nTrain = floor(trainFraction * n);
nVal = floor(valFraction * n);

trainIdx = idx(1:nTrain);
valIdx = idx((nTrain + 1):(nTrain + nVal));
testIdx = idx((nTrain + nVal + 1):end);

trainData = subset(data, trainIdx);
valData = subset(data, valIdx);
testData = subset(data, testIdx);
end

function out = subset(data, idx)
out = struct;
out.X = data.X(idx);
out.Y = data.Y(idx);
out.Meta = data.Meta;
out.Meta.NumObservations = numel(idx);
end

