# Hidden Stride With Jitter

## What It Is

The hidden stride with jitter model is a synthetic hop model used to test whether an estimator can discover repeated structure in a frequency-hopping sequence.

It is not intended to be a claim that Bluetooth Classic exposes such a simple hop pattern. It is included as a controlled engineering test case. If an algorithm cannot learn this simplified structure, it is unlikely to perform well against any real sequence leakage or repeated timing behavior.

## The Basic Idea

The model chooses a hidden starting bin and a hidden stride. Each new hop advances through the 79 Bluetooth bins by that stride:

```text
hop[t] = (phase + stride * t) mod 79
```

Where:

- `t` is the packet or hop-slot index.
- `phase` is the hidden starting position.
- `stride` is the hidden step size.
- `mod 79` wraps the result back into the Bluetooth channel range.

For example, if:

```text
phase = 8
stride = 17
```

Then the hop bins are:

```text
8, 25, 42, 59, 76, 14, 31, 48, ...
```

The sequence looks spread across the band, but it is predictable once the stride and phase are estimated.

## Why Use Modulo 79

The simulator represents the Bluetooth band as 79 one-MHz bins. A modulo operation keeps every generated hop inside that range.

Using a stride that is relatively prime to 79 allows the sequence to visit every bin before repeating. Since 79 is prime, any stride from 1 to 78 will eventually cycle through all bins.

## What Jitter Adds

Jitter randomly replaces some stride-generated hops with random bins.

In the simulator:

```text
if random() < jitter_probability:
    hop[t] = random bin from 0 to 78
else:
    hop[t] = stride-generated bin
```

This makes the estimator's job more realistic. Real measurements can be disrupted by missed detections, false detections, retransmissions, interference, adaptive channel changes, or timing uncertainty. Jitter acts as a simple way to represent those disturbances.

Low jitter means the structure is easy to learn. High jitter means the stride pattern becomes harder to distinguish from random hopping.

## Why It Is Called Hidden

The generator knows the phase and stride, but the algorithms do not. The algorithms only see detector observations, which may be missing or wrong depending on the detector settings.

That separation is important. The model tests whether an algorithm can infer the hidden parameters from observations rather than being handed the answer.

## How The Stride Estimator Uses It

The stride estimator compares observed bin changes against possible strides. If two observed packets are separated by `dt` slots, then a candidate stride predicts:

```text
predicted = previous_bin + stride * dt mod 79
```

If the predicted bin matches the observed bin, that stride receives a higher score. Over time, the correct stride should accumulate more score than incorrect strides.

Once a likely stride is found, the estimator predicts future bins using the latest known observation as an anchor.

## How The Hybrid Estimator Uses It

The hybrid estimator includes a phase/stride bank. Instead of only estimating stride from one observation to the next, it scores combinations of:

- Possible phase values.
- Possible stride values.

When that bank becomes confident enough, the hybrid estimator switches from active-map density behavior to stride prediction.

This is why the hidden-stride model is useful: it shows whether the hybrid can detect when sequence prediction is more useful than simply jamming the densest active region.

## What Results To Expect

With low jitter and good detection:

- The stride estimator should improve after it has seen enough observations.
- The hybrid estimator should also improve once its phase/stride confidence rises.
- Random, sweep, and active-map algorithms may be weaker because the sequence is spread across the full band.

With high jitter or poor detection:

- The correct stride is harder to identify.
- The Markov tracker and active-map density algorithms may become competitive.
- Results should move closer to the bandwidth-only baseline.

## Why This Matters For The Project

The project needs to know whether a smart follower/estimator can beat simple coverage. The hidden-stride model gives a clear positive-control case:

- If the estimator can exploit structure, it should perform well here.
- If the estimator performs no better than random here, the estimator implementation is probably weak.
- If the estimator performs well here but poorly in pseudo-random hopping, that is expected and informative.

This helps separate two questions:

1. Can the algorithm exploit predictable structure when it exists?
2. Does the real Bluetooth connection expose enough exploitable structure for the algorithm to matter?

The first question is answered by this simulation model. The second question must be answered later using real Bluetooth measurements.

## Where It Is Implemented

The hop generator is implemented in `index.html` inside `generateHops(params)`. The relevant branch is selected when:

```javascript
params.hopModel === "stride"
```

The estimator that directly targets this model is implemented in `makeStrideEstimator()`. The hybrid version is implemented in `makeHybridEstimator()` and `makePhaseBank()`.
