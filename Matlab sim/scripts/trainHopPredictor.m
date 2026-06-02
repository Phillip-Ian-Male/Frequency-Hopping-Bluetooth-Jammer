%TRAINHOPPREDICTOR Train a GPU-oriented Bluetooth Classic hop predictor.

cfg = btHopPredictor.defaultConfig("rtx4070");

% Keep the default realistic setting. Change to "oracleFeatures" only for an
% upper-bound experiment where simulated address and clock state are known.
cfg.FeatureMode = "sequenceOnly";

btHopPredictor.assertToolboxes(cfg);

fprintf("Preset: RTX 4070\n");
fprintf("Sequences: %d, hops/sequence: %d, window: %d, stride: %d\n", ...
    cfg.NumSequences, cfg.HopsPerSequence, cfg.WindowLength, cfg.WindowStride);

data = btHopPredictor.generateDataset(cfg);
[trainData, valData, testData] = btHopPredictor.splitDataset(data, 0.80, 0.10);

[layers, modelInfo] = btHopPredictor.buildModel(cfg, data.Meta.NumFeatures, data.Meta.NumClasses);
[net, trainInfo] = btHopPredictor.trainModel(trainData, valData, layers, cfg);
metrics = btHopPredictor.evaluateModel(net, testData, cfg);

if ~isfolder(cfg.ModelDir)
    mkdir(cfg.ModelDir);
end

stamp = datestr(now, "yyyymmdd_HHMMSS");
modelPath = fullfile(cfg.ModelDir, "hopPredictor_" + string(stamp) + ".mat");
save(modelPath, "net", "cfg", "metrics", "modelInfo", "trainInfo", "-v7.3");

btHopPredictor.saveResults("train_" + string(stamp), cfg, metrics, modelInfo, trainInfo);

fprintf("Saved model: %s\n", modelPath);
disp(metrics)

