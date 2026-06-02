%RUNSMOKETEST Fast package validation for MATLAB.

cfg = btHopPredictor.defaultConfig("smoke");
cfg.TrainingPlots = "none";

btHopPredictor.assertToolboxes(cfg);

data = btHopPredictor.generateDataset(cfg);
[trainData, valData, testData] = btHopPredictor.splitDataset(data, 0.70, 0.15);

[layers, modelInfo] = btHopPredictor.buildModel(cfg, data.Meta.NumFeatures, data.Meta.NumClasses);
[net, trainInfo] = btHopPredictor.trainModel(trainData, valData, layers, cfg);
metrics = btHopPredictor.evaluateModel(net, testData, cfg);

disp(metrics)
disp(modelInfo.Cost)
btHopPredictor.saveResults("smoke", cfg, metrics, modelInfo, trainInfo);

