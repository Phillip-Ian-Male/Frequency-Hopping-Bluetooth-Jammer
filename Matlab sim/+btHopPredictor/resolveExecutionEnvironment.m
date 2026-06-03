function env = resolveExecutionEnvironment(useGPU)
%RESOLVEEXECUTIONENVIRONMENT Return "gpu", "cpu", or "auto" for DL calls.

mode = lower(string(useGPU));

if any(mode == ["false", "cpu", "off", "0"])
    env = "cpu";
    return
end

if any(mode == ["auto", "automatic"])
    if hasGPU()
        env = "gpu";
    else
        env = "cpu";
    end
    return
end

if any(mode == ["true", "gpu", "on", "1"])
    if hasGPU()
        env = "gpu";
    else
        env = "cpu";
    end
    return
end

env = "auto";
end

function tf = hasGPU()
tf = false;
try
    if exist("gpuDeviceCount", "file") == 2 && gpuDeviceCount() > 0
        gpuDevice(1);
        tf = true;
    end
catch
    tf = false;
end
end
