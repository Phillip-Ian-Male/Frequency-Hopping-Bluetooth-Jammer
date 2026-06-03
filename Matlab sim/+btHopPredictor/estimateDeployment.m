function est = estimateDeployment(cfg, numFeatures)
%ESTIMATEDEPLOYMENT Estimate Rock 5B and Jetson Orin Nano feasibility.

arguments
    cfg (1,1) struct
    numFeatures = []
end

if isempty(numFeatures)
    numFeatures = estimateFeatureCount(cfg);
end
validateattributes(numFeatures, {'double', 'single'}, {'scalar', 'integer', 'positive'}, mfilename, 'numFeatures');
numFeatures = double(numFeatures);

cost = btHopPredictor.estimateModelCost(cfg, numFeatures, 79);

names = [
    "Rock 5B CPU only"
    "Rock 5B RKNN/NPU optimistic"
    "Jetson Orin Nano TensorRT"
];

officialTOPS = [NaN; 6; 67];

% Conservative effective rates for small recurrent networks after overhead,
% memory traffic, framework cost, and imperfect accelerator utilization.
effectiveGOPS = [25; 120; 1200];
fixedOverheadUs = [120; 100; 40];

latencyUs = cost.MACsPerPrediction ./ (effectiveGOPS * 1e9) * 1e6 + fixedOverheadUs;
slotBudgetUs = 625;
budgetUtilization = latencyUs / slotBudgetUs * 100;
headroom = slotBudgetUs ./ latencyUs;

Summary = table(names, officialTOPS, effectiveGOPS, latencyUs, budgetUtilization, headroom, ...
    VariableNames = ["Target", "OfficialTOPS", "AssumedEffectiveGOPS", "EstimatedLatencyUs", "SlotBudgetPercent", "SlotHeadroom"]);

if latencyUs(1) < 300
    recommendation = "Rock 5B is plausible for this model, but benchmark exported code on-device.";
elseif latencyUs(3) < 300
    recommendation = "Jetson Orin Nano is recommended for this recurrent ML model; Rock 5B should be reserved for smaller quantized models or deterministic hop-kernel code.";
elseif latencyUs(3) < 625
    recommendation = "Jetson Orin Nano may fit the 625 us slot, but the model should be reduced to leave RF and scheduling margin.";
else
    recommendation = "This model is too large for a comfortable 625 us embedded loop; reduce window length, hidden units, or recurrent layers.";
end

est = struct;
est.Cost = cost;
est.Summary = Summary;
est.Recommendation = recommendation;
est.Assumptions = [
    "625 us Bluetooth Classic slot budget"
    "1600 predictions per second"
    "MATLAB training model must be exported and benchmarked before deployment"
    "Rock 5B NPU support for recurrent networks depends on successful RKNN conversion"
    "Jetson estimate assumes TensorRT/CUDA deployment, not interpreted MATLAB"
];
end

function n = estimateFeatureCount(cfg)
n = 79 + 1;
if isfield(cfg, "IncludeDeltas") && cfg.IncludeDeltas
    n = n + 1;
end
if isfield(cfg, "IncludeClockPhase") && cfg.IncludeClockPhase
    n = n + 2 * numel(cfg.ClockModuloFeatures);
end
if isfield(cfg, "FeatureMode") && strcmpi(string(cfg.FeatureMode), "oracleFeatures")
    n = n + 28 + 24;
end
end
