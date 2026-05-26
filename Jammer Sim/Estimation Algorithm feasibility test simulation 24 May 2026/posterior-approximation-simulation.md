# Posterior Approximation Real-Time Simulator

## Purpose

`posterior-approximation.html` compares the three practical approximations closest to Posterior Majority Vote:

- Top-K Phase/Stride Bank.
- Beam Posterior Tracker.
- Jetson Particle Posterior.

The simulator is intentionally closer to `active-map-learning.html` than to the exact-hop upper-bound simulator. It assumes the learner must operate in real time with response delay, noisy detections, limited pretraining, and bounded compute.

## Key Question

Posterior Majority Vote keeps the full belief distribution over hidden hop generators. That is the optimal finite-model predictor, but it is too large for a practical embedded implementation.

This simulator asks:

```text
How close can bounded posterior approximations get under realistic timing and observation limits?
```

## Approximations Included

`Top-K Phase/Stride Bank`

The embedded-friendly approximation. It keeps a bounded bank of phase, stride, and low-order curvature hypotheses. Each hypothesis predicts the target slot and contributes a weighted vote.

This is the closest version that could plausibly be reduced to ESP32-class code if the candidate set is small enough.

`Beam Posterior Tracker`

A larger weighted beam. It keeps more candidate generators and periodically diversifies them through mutation. This is intended for a Pi-class processor or similar heavier companion computer.

`Jetson Particle Posterior`

The highest-compute practical option. It uses a larger particle set, resampling, elite retention, and mutation. This is the closest implemented approximation to full Posterior Majority Vote, and it is the recommended candidate when a Jetson Nano is permitted.

## Baselines

`Active-Map Density`

Learns frequency usage but not sequence state. It shows whether the posterior methods are adding value beyond active-map learning.

`Random Window`

Coverage-only baseline.

## Real-Time Treatment

The simulator models Classic Bluetooth-style 625 us slots. Response time is converted to a future-slot prediction horizon. The algorithms are not allowed to use the target packet observation before making the target packet decision.

The learner can receive:

- Pretraining observations before deployment.
- Noisy packet detections during deployment.
- Wrong-bin reports according to the configured error rate.

## Interpreting Results

If the Jetson Particle Posterior wins, the scenario needs heavier compute but may be practical with a Jetson Nano-class platform.

If Top-K Phase/Stride Bank is close to Jetson performance, the embedded implementation path is more promising.

If Active-Map Density is competitive, the sequence model is probably not adding much exploitable order information.

If all algorithms fail on the pseudo-random full-band model, that is expected. There is no future-hop information to recover.

## Recommended Starting Point

Use:

- Sequence model: structured phase/stride.
- Jamming bandwidth: 1 MHz for exact-hop stress testing.
- Response time: expected measured platform timing.
- Detection probability: realistic receiver estimate.
- Pretrain packets: 1600 or more.
- Jetson particles: 256 for quick interactive runs, then 1024 or more for slower sensitivity checks.

Then test:

- AFH remapped sequence.
- Slow parameter drift.
- Higher jitter.
- Lower detection probability.
- Wider bandwidth from 1 MHz up to the allowed 10 MHz.

The most important comparison is the gap between Top-K, Beam, and Jetson. That gap tells you whether extra compute is buying real prediction quality.
