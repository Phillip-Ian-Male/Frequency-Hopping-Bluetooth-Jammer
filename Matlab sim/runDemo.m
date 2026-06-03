function runDemo
%RUNDEMO Run a small end-to-end hop-prediction simulation.

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
addpath(fullfile(rootDir, "scripts"));

cfg = btHopPredictor.defaultConfig("smoke");
cfg.FeatureMode = "sequenceOnly";
cfg.TrainingPlots = "none";

btHopPredictor.assertToolboxes(cfg);

fprintf("Generating simulated Bluetooth Classic hop dataset...\n");
data = btHopPredictor.generateDataset(cfg);
[trainData, valData, testData] = btHopPredictor.splitDataset(data, 0.70, 0.15);

fprintf("Building and training model...\n");
[layers, modelInfo] = btHopPredictor.buildModel(cfg, data.Meta.NumFeatures, data.Meta.NumClasses);
[net, trainInfo] = btHopPredictor.trainModel(trainData, valData, layers, cfg);

fprintf("Evaluating holdout set...\n");
metrics = btHopPredictor.evaluateModel(net, testData, cfg);
disp(metrics)

est = btHopPredictor.estimateDeployment(cfg, data.Meta.NumFeatures);
disp(est.Summary)
fprintf("%s\n", est.Recommendation);

btHopPredictor.saveResults("demo", cfg, metrics, modelInfo, trainInfo);
end
