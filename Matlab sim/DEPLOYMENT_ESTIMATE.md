# Embedded Deployment Estimate

The target timing budget is one Bluetooth Classic slot:

- Slot period: 625 us
- Hop decisions: 1600 per second
- Practical algorithm budget: below 250 to 350 us if RF detection, buffering,
  scheduling, and OS jitter also need time

## Hardware Baseline

Rock 5B uses the Rockchip RK3588. Radxa lists an RK3588 NPU with support for
INT4/INT8/INT16/FP16/BF16/TF32 acceleration and up to 6 TOPS:
https://docs.radxa.com/en/rock5/rock5b/getting-started/introduction

NVIDIA lists Jetson Orin Nano series modules at up to 67 TOPS with 7 W to 25 W
power options:
https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-orin/

## Practical Conclusion

If the final algorithm is the deterministic Bluetooth hop-selection calculation
with known simulated state, the Rock 5B is enough. That is a small integer
algorithm and does not need a neural accelerator.

If the final algorithm is a recurrent ML predictor similar to the RTX 4070
preset in this package, the Jetson Orin Nano is the safer target. The Rock 5B
can run small quantized models, but its NPU tooling is less friendly for
sequence models and MATLAB-exported networks. Running a large LSTM on the Rock
5B CPU is unlikely to leave enough latency margin inside 625 us.

Recommended development path:

1. Train and evaluate in MATLAB on the RTX 4070.
2. Shrink the model until top-k accuracy and latency are acceptable.
3. Export to ONNX.
4. Use TensorRT on Jetson Orin Nano for the real-time prototype.
5. Only target Rock 5B if the final network is converted successfully to RKNN or
   replaced by a compact deterministic or table-assisted predictor.

## Reading the Estimator

`btHopPredictor.estimateDeployment` reports:

- MACs per prediction
- GMAC/s needed at 1600 predictions per second
- estimated latency for conservative board profiles
- a recommendation string

These are sizing estimates, not substitutes for on-device timing. Always run
`benchmarkInference.m` in MATLAB first, then benchmark the exported model on the
actual embedded runtime.

