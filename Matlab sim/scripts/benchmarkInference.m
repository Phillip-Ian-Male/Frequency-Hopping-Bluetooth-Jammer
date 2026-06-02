%BENCHMARKINFERENCE Measure MATLAB prediction latency for the newest model.

modelFiles = dir(fullfile("models", "hopPredictor_*.mat"));
if isempty(modelFiles)
    error("No saved models found. Run trainHopPredictor first.");
end

[~, newestIdx] = max([modelFiles.datenum]);
modelPath = fullfile(modelFiles(newestIdx).folder, modelFiles(newestIdx).name);
loaded = load(modelPath, "net", "cfg");

cfg = loaded.cfg;
cfg.NumSequences = 8;
cfg.HopsPerSequence = max(cfg.WindowLength + 64, 160);
cfg.WindowStride = 1;
cfg.TrainingPlots = "none";

data = btHopPredictor.generateDataset(cfg);
numTrials = min(1000, numel(data.X));
X = data.X(1:numTrials);

env = btHopPredictor.resolveExecutionEnvironment(cfg.UseGPU);
predict(loaded.net, X(1), "MiniBatchSize", 1, "SequenceLength", "longest", ...
    "ExecutionEnvironment", env);

tic
for k = 1:numTrials
    predict(loaded.net, X(k), "MiniBatchSize", 1, "SequenceLength", "longest", ...
        "ExecutionEnvironment", env);
end
elapsed = toc;

latencyUs = elapsed / numTrials * 1e6;
fprintf("Model: %s\n", modelPath);
fprintf("Execution environment: %s\n", env);
fprintf("Mean single-window prediction latency: %.1f us\n", latencyUs);
fprintf("625 us slot budget utilization: %.1f %%\n", latencyUs / 625 * 100);

