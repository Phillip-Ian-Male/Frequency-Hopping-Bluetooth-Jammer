# Active-Map Learning Feasibility Simulator

## Purpose

`active-map-learning.html` is a second simulator focused on a narrower engineering question:

Can a bandwidth-limited jammer meet the 36% packet disruption requirement by learning the active Bluetooth channel map, using algorithms that are plausible on embedded hardware or on a heavier platform such as a Jetson Nano?

The first simulator compares general follower and estimation algorithms. This second simulator separates feasibility from learning quality.

## Key Feasibility Idea

With 79 Bluetooth bins and a 10 MHz contiguous jammer window, full-band random coverage gives only:

```text
10 / 79 = 12.7%
```

To reach 36% using active-map learning, the active map must concentrate enough traffic inside one 10 MHz window.

For a uniform clustered active map, the rough active-bin requirement is:

```text
10 / active_bins >= 0.36
active_bins <= 27.7
```

So with 10 MHz bandwidth, a uniformly used clustered active map must be about 27 active bins or fewer for 36% to be possible by active-map learning alone. If traffic is skewed toward a smaller region, more active bins may still be feasible. If active bins are scattered across the full band, even 20 active bins may fail because the jammer window is contiguous.

## The Oracle Active-Map Bound

The simulator includes an `Oracle Active-Map Bound`.

This is not an implementable algorithm. It knows the true active-channel probability map and chooses the best contiguous jammer window, but it does not know the exact next hop.

It answers:

```text
If active-map learning were perfect, could this scenario reach 36%?
```

Interpretation:

- If the oracle bound is below 36%, no active-map-only learner can meet the requirement in that scenario.
- If the oracle bound is above 36% and real learners fail, the problem is learning quality, observation quality, or adaptation speed.
- If a learner approaches the oracle bound, the algorithm is probably close to the best possible active-map strategy for that scenario.

## Active Map Models

`Clustered AFH map`

Active bins form one contiguous region. This is the most favorable case for a contiguous narrow-band jammer.

`Scattered AFH map`

Active bins are randomly spread across the 79-bin band. This is much harder because a 10 MHz contiguous jammer may only cover a small fraction of active channels.

`Dual-cluster AFH map`

Active bins form two separated clusters. This tests whether algorithms can choose the better cluster rather than averaging across both.

`Slow drifting cluster`

The active region moves between map-change intervals. This tests whether an algorithm can adapt rather than overfitting old observations.

## Learners Included

`Random Window`

Coverage baseline. It should usually sit near the bandwidth fraction unless the active map is very small.

`Embedded EMA Map`

Maintains decaying channel counts and jams the densest contiguous window. This is the simplest realistic embedded candidate.

`Bayesian Channel Map`

Uses a smoothed channel posterior. It is still lightweight, but less jumpy than raw decaying counts.

`Two-Rate Change Learner`

Maintains fast and slow memories. It increases the fast-memory influence when the active map appears to change.

`UCB Window Bandit`

Learns which jamming windows produce hits. This is computationally feasible, but it assumes the system has some form of hit or disruption feedback. If the real system cannot observe whether a packet was disrupted, this algorithm is less realistic.

`Jetson Particle Ensemble`

Maintains many cluster hypotheses and combines them with density learning. This is the computationally hungry learner. It is included to test whether a heavier model meaningfully improves the result before considering a more capable processing platform.

## Response Time Treatment

The simulator keeps the same slot timing model as the first simulator:

- Bluetooth hops every 625 us.
- Response time is converted into slot delay plus fractional overlap.
- The algorithm predicts the jamming window for a future slot.
- The current observation is only available after the current packet.

This prevents zero-delay settings from cheating by using the same packet's observation to jam that same packet.

## What Counts As A Candidate

A candidate algorithm should:

- Reach or exceed 36% overall, or reach it consistently after a learning period.
- Stay close to the oracle active-map bound.
- Remain stable under realistic detection probability and wrong-bin settings.
- Still perform when response time is set to the expected embedded timing.
- Have a compute class that matches the intended hardware.

If only the Jetson particle ensemble works, the result suggests that the embedded platform may be too weak for the chosen model. If even the particle ensemble fails while the oracle succeeds, the model or learner needs improvement. If the oracle fails, active-map learning is not enough.

## Engineering Interpretation

This simulator is designed to make negative results useful.

Important conclusions:

- A better learner cannot overcome a poor active-map bound.
- Contiguous bandwidth matters as much as total bandwidth.
- AFH clustering is the main path by which 10 MHz can plausibly reach 36%.
- Scattered active channels are a serious problem for a single contiguous jammer.
- A heavy learner is only worth considering if it closes a real gap between embedded learners and the oracle bound.

## Recommended Use

Start with:

- Map model: clustered AFH map.
- Active bins: 20 to 28.
- Used bandwidth: 10 MHz.
- Response time: expected measured system response.
- Detection probability: realistic receiver estimate.

Then test:

- More active bins.
- Scattered and dual-cluster maps.
- Dynamic map changes.
- Lower detection probability.
- Higher wrong-bin reports.
- Higher response time.

Document the oracle bound together with the best learner. The bound is the evidence for whether the requirement is physically plausible under that scenario.
