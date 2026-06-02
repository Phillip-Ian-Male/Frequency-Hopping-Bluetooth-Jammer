function [net, info] = trainModel(trainData, valData, layers, cfg)
%TRAINMODEL Train the hop-prediction network.

arguments
    trainData (1,1) struct
    valData (1,1) struct
    layers
    cfg (1,1) struct
end

env = btHopPredictor.resolveExecutionEnvironment(cfg.UseGPU);

optionArgs = {
    "ExecutionEnvironment", env, ...
    "MaxEpochs", cfg.MaxEpochs, ...
    "MiniBatchSize", cfg.MiniBatchSize, ...
    "InitialLearnRate", cfg.InitialLearnRate, ...
    "GradientThreshold", cfg.GradientThreshold, ...
    "L2Regularization", cfg.L2Regularization, ...
    "Shuffle", "every-epoch", ...
    "SequenceLength", "longest", ...
    "Verbose", cfg.Verbose, ...
    "Plots", char(cfg.TrainingPlots)
};

if ~isempty(valData.X)
    optionArgs = [optionArgs, { ...
        "ValidationData", {valData.X, valData.Y}, ...
        "ValidationFrequency", cfg.ValidationFrequency}]; %#ok<AGROW>
end

options = trainingOptions("adam", optionArgs{:});

[net, trainInfo] = trainNetwork(trainData.X, trainData.Y, layers, options);

info = struct;
info.TrainingInfo = trainInfo;
info.ExecutionEnvironment = env;
info.NumTrainObservations = numel(trainData.X);
info.NumValidationObservations = numel(valData.X);
end

