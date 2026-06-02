function [layers, info] = buildModel(cfg, numFeatures, numClasses)
%BUILDMODEL Create an LSTM/GRU sequence classifier for hop prediction.

arguments
    cfg (1,1) struct
    numFeatures (1,1) double {mustBeInteger, mustBePositive}
    numClasses (1,1) double {mustBeInteger, mustBePositive} = 79
end

layers = [
    sequenceInputLayer(numFeatures, "Normalization", "none", "Name", "input")
];

for layerIdx = 1:cfg.NumRecurrentLayers
    if layerIdx == cfg.NumRecurrentLayers
        outputMode = "last";
    else
        outputMode = "sequence";
    end

    switch lower(string(cfg.PredictorType))
        case "gru"
            recurrentLayer = gruLayer(cfg.HiddenUnits, "OutputMode", outputMode, ...
                "Name", "gru_" + string(layerIdx));
        otherwise
            recurrentLayer = lstmLayer(cfg.HiddenUnits, "OutputMode", outputMode, ...
                "Name", "lstm_" + string(layerIdx));
    end

    layers = [layers; recurrentLayer]; %#ok<AGROW>

    if cfg.Dropout > 0
        layers = [layers; dropoutLayer(cfg.Dropout, "Name", "dropout_r" + string(layerIdx))]; %#ok<AGROW>
    end
end

layers = [
    layers
    fullyConnectedLayer(cfg.DenseUnits, "Name", "dense")
    reluLayer("Name", "relu")
    dropoutLayer(cfg.Dropout, "Name", "dropout_dense")
    fullyConnectedLayer(numClasses, "Name", "channel_logits")
    softmaxLayer("Name", "channel_softmax")
    classificationLayer("Name", "channel_class")
];

info = struct;
info.NumFeatures = numFeatures;
info.NumClasses = numClasses;
info.Cost = btHopPredictor.estimateModelCost(cfg, numFeatures, numClasses);
end

