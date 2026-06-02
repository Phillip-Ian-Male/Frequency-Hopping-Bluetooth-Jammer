function usedChannels = makeUsedChannels(cfg)
%MAKEUSEDCHANNELS Create a simulated AFH used-channel set.

arguments
    cfg (1,1) struct
end

mode = "all";
if isfield(cfg, "UsedChannelsMode")
    mode = string(cfg.UsedChannelsMode);
end

switch lower(mode)
    case "all"
        usedChannels = 0:78;

    case "static"
        usedChannels = double(cfg.StaticUsedChannels);

    case "randomafh"
        minUsed = max(20, cfg.MinUsedChannels);
        maxUsed = min(79, cfg.MaxUsedChannels);
        n = randi([minUsed, maxUsed], 1, 1);
        usedChannels = sort(randperm(79, n) - 1);

    otherwise
        error("Unknown UsedChannelsMode: %s", mode);
end

usedChannels = unique(double(usedChannels(:).'));
if numel(usedChannels) < 20 || any(usedChannels < 0) || any(usedChannels > 78)
    error("UsedChannels must contain at least 20 unique channel indices in [0, 78].");
end
end

