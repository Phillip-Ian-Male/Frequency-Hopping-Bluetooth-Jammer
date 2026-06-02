# Bluetooth Classic Hop Predictor Simulation

This MATLAB package builds a simulation-only workflow for Bluetooth Classic
BR/EDR hop prediction. It uses MathWorks Bluetooth Toolbox objects as the
ground-truth hop source and trains a Deep Learning Toolbox sequence model to
predict the next channel index from simulated observations.

The package does not include live RF capture, SDR transmit control, or any
hardware jamming workflow. It is intended for academic simulation, algorithm
benchmarking, and embedded feasibility estimation.

## Requirements

- MATLAB with Bluetooth Toolbox. The hop generator uses `bluetoothFrequencyHop`
  and optional waveform previews use `bluetoothWaveformGenerator`.
- Deep Learning Toolbox for LSTM/GRU training.
- Parallel Computing Toolbox plus an NVIDIA GPU for the RTX 4070 training
  preset. CPU training works for the smoke preset.

MathWorks references used when building this package:

- `bluetoothFrequencyHop` generates BR/EDR channel indices for inquiry, paging,
  connection basic, and connection adaptive sequences:
  https://www.mathworks.com/help/bluetooth/ref/bluetoothfrequencyhop.html
- `nextHop` selects the next BR/EDR channel index from the hop object and clock:
  https://www.mathworks.com/help/bluetooth/ref/nexthop.html
- `bluetoothWaveformGenerator` generates BR/EDR PHY waveforms:
  https://www.mathworks.com/help/bluetooth/ref/bluetoothwaveformgenerator.html

## Quick Start

From this folder in MATLAB:

```matlab
startup
runDemo
```

For a fast validation run:

```matlab
startup
runSmokeTest
```

For a larger RTX 4070-oriented training run:

```matlab
startup
trainHopPredictor
evaluatePredictor
benchmarkInference
```

The training script saves `.mat` files under `models/`. Result summaries are
saved under `results/`.

## Model Modes

`cfg.FeatureMode = "sequenceOnly"` is the default and uses only simulated
observed hop indices plus relative timing features. This is the most honest
academic benchmark for a passive observer, but Bluetooth Classic hopping is
designed to be pseudo-random, so do not expect guaranteed long-horizon
prediction.

`cfg.FeatureMode = "oracleFeatures"` adds the simulated native clock bits and
lower address bits. This is useful as an upper-bound experiment because the
network learns to approximate the deterministic hop-selection kernel, but it is
not a fair passive-observer setting.

`cfg.SequenceType` can be `"Connection basic"` or `"Connection adaptive"`.
Adaptive mode uses `cfg.UsedChannelsMode` to simulate AFH channel maps.

## Main Files

- `runDemo.m` - small end-to-end demo.
- `scripts/trainHopPredictor.m` - RTX 4070-sized training configuration.
- `scripts/evaluatePredictor.m` - evaluates the latest saved model on a fresh
  simulated holdout set.
- `scripts/benchmarkInference.m` - measures MATLAB inference latency.
- `+btHopPredictor/generateHopTrace.m` - calls Bluetooth Toolbox `nextHop`.
- `+btHopPredictor/generateDataset.m` - builds windowed sequence-learning data.
- `+btHopPredictor/buildModel.m` - creates the LSTM/GRU classifier.
- `+btHopPredictor/estimateDeployment.m` - estimates Rock 5B vs Jetson Orin Nano
  feasibility.

## Embedded Interpretation

Bluetooth uses 625 us slots, or 1600 hop decisions per second. The MATLAB model
is a research model, not an embedded implementation. For deployment estimates,
run:

```matlab
cfg = btHopPredictor.defaultConfig("rtx4070");
est = btHopPredictor.estimateDeployment(cfg);
disp(est.Summary)
disp(est.Recommendation)
```

The short version: a deterministic hop-kernel implementation is light enough for
a Rock 5B if the required state is available. A heavy recurrent ML predictor,
especially one trained with the RTX 4070 preset, should be planned around a
Jetson Orin Nano or a smaller quantized model. See `DEPLOYMENT_ESTIMATE.md`.

