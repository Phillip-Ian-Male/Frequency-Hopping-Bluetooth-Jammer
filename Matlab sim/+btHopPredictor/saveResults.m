function resultPath = saveResults(tag, cfg, metrics, modelInfo, trainInfo)
%SAVERESULTS Save run metadata and metrics under cfg.ResultDir.

arguments
    tag (1,1) string
    cfg (1,1) struct
    metrics (1,1) struct
    modelInfo (1,1) struct = struct
    trainInfo (1,1) struct = struct
end

if ~isfolder(cfg.ResultDir)
    mkdir(cfg.ResultDir);
end

safeTag = regexprep(char(tag), "[^A-Za-z0-9_=-]", "_");
resultPath = fullfile(cfg.ResultDir, safeTag + ".mat");
save(resultPath, "cfg", "metrics", "modelInfo", "trainInfo");
fprintf("Saved results: %s\n", resultPath);
end

