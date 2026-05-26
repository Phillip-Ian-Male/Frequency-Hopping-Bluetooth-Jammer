# Algorithm Engineering Decisions

## Selection Strategy

The simulator includes both simple baselines and smarter estimators. The baselines are important because they expose whether a more complex algorithm is genuinely adding value or merely benefiting from the jammer bandwidth.

The implemented algorithms are intentionally diverse:

- Coverage baselines.
- Low-latency followers.
- Sequence estimators.
- Transition-learning estimators.
- Active-map density estimators.
- A hybrid estimator that switches between learned models.

## Random Window

The random window selects a random contiguous jamming band for each decision.

Engineering purpose:

- Establishes a lower baseline.
- Shows the approximate effect of bandwidth alone.
- Helps identify when a smart algorithm is not outperforming chance.

Expected behavior:

- In a full 79-bin pseudo-random model with 10 MHz coverage, it should sit near 10/79, or about 12.7%.
- It can vary with seed and packet count, but should not approach 36% unless the active hop space is much smaller than 79 bins.

## Linear Sweep

The linear sweep walks the jamming window across the band.

Engineering purpose:

- Represents a simple hardware-friendly strategy.
- Provides a deterministic baseline that is easy to implement on embedded hardware.
- Tests whether sweeping alone can exploit clustered active channels.

Expected behavior:

- It can be useful when the connection remains inside a compact active region for long periods.
- It is usually weak against pseudo-random hopping because the sweep is not synchronized to the hop sequence.

## Last-Bin Follower

The last-bin follower centers the jam window on the most recently detected bin.

Engineering purpose:

- Models the simplest follower algorithm.
- Requires almost no memory or computation.
- Useful for testing how damaging response delay is.

Expected behavior:

- Works only if consecutive or delayed hops are correlated.
- Performs poorly when the next hop is independent of the previous hop.
- Becomes less useful as response time increases.

## Stride Estimator

The stride estimator scores possible modular stride values between observed bins. It predicts future bins using the strongest stride hypothesis.

Engineering purpose:

- Tests whether repeated hop structure can be exploited.
- Represents a lightweight sequence estimator that could be optimized for embedded use.
- Gives a clear contrast against active-map algorithms.

Expected behavior:

- Strong in the hidden-stride model.
- Weak in the pseudo-random model.
- Sensitive to missed detections and wrong-bin observations, but can recover when enough observations are available.

## Markov Tracker

The Markov tracker learns transition counts from one observed bin to the next. It predicts the next likely region by selecting the contiguous window with the highest learned transition weight.

Engineering purpose:

- Tests whether repeated transitions exist without assuming a fixed stride.
- More flexible than the stride estimator.
- Still simple enough to reason about and potentially port to embedded code.

Expected behavior:

- Can perform well when the hop model has repeated transitions or a restricted active map.
- Needs observation history before it becomes useful.
- Can overfit false detections if detector quality is poor.

## Active-Map Density

The active-map density estimator learns which channels are used most often. It ignores transition order and chooses the contiguous jam window with the highest accumulated channel density.

Engineering purpose:

- Models an AFH-aware jammer that tries to learn the active channel map.
- Very useful when Bluetooth avoids many channels or concentrates activity in a smaller portion of the band.
- Computationally simple: maintain one score per bin.

Expected behavior:

- Strong in clustered AFH cases.
- Moderate in scattered AFH cases.
- Weak in full-band pseudo-random hopping because all bins become similarly likely.

## Hybrid Estimator

The hybrid estimator combines active-map density with a phase/stride bank. It uses the active-map model by default, then switches to stride prediction when the stride bank has enough confidence.

Engineering purpose:

- Avoids committing to one model too early.
- Performs well in AFH-like cases while still being able to exploit repeated sequence structure.
- Represents the kind of decision logic that could be used in the final embedded algorithm selection.

Expected behavior:

- Good general-purpose performance across structured models.
- Slightly more computationally expensive than the single-model algorithms.
- Still cannot defeat a truly pseudo-random full-band hop stream.

## Complexity Notes

The simplest algorithms are constant-time per packet. Density and Markov algorithms are still small enough for embedded exploration because there are only 79 bins.

The hybrid phase/stride bank is more expensive because it scores combinations of phase and stride. This is acceptable in the browser simulator, but an embedded implementation should profile it carefully or reduce the hypothesis set.

## Why No Neural Network Or Heavy Optimizer

The project needs algorithms that can plausibly run on an embedded platform with tight timing. A neural network or large optimizer would make the simulator look sophisticated while hiding the key engineering tradeoff: fast, explainable decisions inside a 625 us hop slot.

The chosen algorithms are transparent, tunable, and easier to port into C, C++, or embedded Python if needed.
