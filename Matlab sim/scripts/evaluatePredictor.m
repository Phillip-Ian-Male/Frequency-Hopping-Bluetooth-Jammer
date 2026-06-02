%EVALUATEPREDICTOR Evaluate the newest saved hop-predictor model.

modelFiles = dir(fullfile("models", "hopPredictor_*.mat"));
if isempty(modelFiles)
    error("No saved models found. Run trainHopPredictor first.");
end

[~, newestIdx] = max([modelFiles.datenum]);
modelPath = fullfile(modelFiles(newestIdx).folder, modelFiles(newestIdx).name);
loaded = load(modelPath, "net", "cfg");

cfg = loaded.cfg;
cfg.RngSeed = cfg.RngSeed + 10000;
cfg.NumSequences = max(64, ceil(cfg.NumSequences * 0.10));
cfg.HopsPerSequence = min(cfg.HopsPerSequence, 512);
cfg.TrainingPlots = "none";

fprintf("Loaded model: %s\n", modelPath);
fprintf("Generating fresh simulated evaluation set...\n");

data = btHopPredictor.generateDataset(cfg);
[~, ~, testData] = btHopPredictor.splitDataset(data, 0.0, 0.0);
metrics = btHopPredictor.evaluateModel(loaded.net, testData, cfg);

disp(metrics)
btHopPredictor.saveResults("eval_" + string(datestr(now, "yyyymmdd_HHMMSS")), cfg, metrics);

