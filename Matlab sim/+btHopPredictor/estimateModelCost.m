function cost = estimateModelCost(cfg, numFeatures, numClasses)
%ESTIMATEMODELCOST Estimate parameter count and MACs for the recurrent model.

arguments
    cfg (1,1) struct
    numFeatures (1,1) double {mustBeInteger, mustBePositive}
    numClasses (1,1) double {mustBeInteger, mustBePositive} = 79
end

hiddenUnits = cfg.HiddenUnits;
numLayers = cfg.NumRecurrentLayers;
windowLength = cfg.WindowLength;

if strcmpi(string(cfg.PredictorType), "gru")
    gates = 3;
else
    gates = 4;
end

macs = 0;
params = 0;
inputSize = numFeatures;
for layerIdx = 1:numLayers
    layerParams = gates * hiddenUnits * (inputSize + hiddenUnits + 1);
    params = params + layerParams;
    macs = macs + layerParams * windowLength;
    inputSize = hiddenUnits;
end

denseMacs = hiddenUnits * cfg.DenseUnits + cfg.DenseUnits * numClasses;
denseParams = denseMacs + cfg.DenseUnits + numClasses;
params = params + denseParams;
macs = macs + denseMacs;

cost = struct;
cost.PredictorType = string(cfg.PredictorType);
cost.WindowLength = windowLength;
cost.NumFeatures = numFeatures;
cost.HiddenUnits = hiddenUnits;
cost.NumRecurrentLayers = numLayers;
cost.NumClasses = numClasses;
cost.Parameters = params;
cost.ModelSizeFP32MB = params * 4 / 1024^2;
cost.ModelSizeINT8MB = params / 1024^2;
cost.MACsPerPrediction = macs;
cost.GMACsPerSecondAt1600 = macs * 1600 / 1e9;
end

