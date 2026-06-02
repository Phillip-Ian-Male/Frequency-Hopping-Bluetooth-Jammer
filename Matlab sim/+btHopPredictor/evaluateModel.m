function metrics = evaluateModel(net, testData, cfg)
%EVALUATEMODEL Evaluate top-k next-hop classification performance.

arguments
    net
    testData (1,1) struct
    cfg (1,1) struct
end

if isempty(testData.X)
    error("Test data is empty.");
end

env = btHopPredictor.resolveExecutionEnvironment(cfg.UseGPU);

YPred = classify(net, testData.X, ...
    "MiniBatchSize", cfg.MiniBatchSize, ...
    "SequenceLength", "longest", ...
    "ExecutionEnvironment", env);

truth = str2double(string(testData.Y));
pred = str2double(string(YPred));

hit = pred == truth;
absError = abs(pred - truth);
circularError = min(absError, 79 - absError);

metrics = struct;
metrics.NumObservations = numel(truth);
metrics.Accuracy = mean(hit);
metrics.MeanCircularChannelError = mean(circularError);
metrics.MedianCircularChannelError = median(circularError);
metrics.ExecutionEnvironment = env;

try
    scores = predict(net, testData.X, ...
        "MiniBatchSize", cfg.MiniBatchSize, ...
        "SequenceLength", "longest", ...
        "ExecutionEnvironment", env);
    scores = orientScores(scores, numel(truth));
    metrics.Top3Accuracy = topKAccuracy(scores, truth, 3);
    metrics.Top5Accuracy = topKAccuracy(scores, truth, 5);
catch ME
    warning("Could not compute top-k scores: %s", ME.message);
    metrics.Top3Accuracy = NaN;
    metrics.Top5Accuracy = NaN;
end
end

function scores = orientScores(scores, n)
if size(scores, 1) ~= n && size(scores, 2) == n
    scores = scores.';
end
end

function acc = topKAccuracy(scores, truth, k)
k = min(k, size(scores, 2));
[~, order] = sort(scores, 2, "descend");
topChannels = order(:, 1:k) - 1;
acc = mean(any(topChannels == truth, 2));
end

