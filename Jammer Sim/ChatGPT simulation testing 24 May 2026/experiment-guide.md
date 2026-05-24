# Experiment Guide

## Basic Workflow

1. Open `index.html` in a browser.
2. Choose a hop model.
3. Set max bandwidth and used bandwidth.
4. Set response time.
5. Set detector probability and wrong-bin probability.
6. Run the simulation.
7. Compare disrupted packets, disruption percentage, and the 36% goal badge.

Use the seed field to repeat a result exactly.

## Recommended First Tests

### Full-Band Pseudo-Random Case

Settings:

- Hop model: `Classic pseudo-random`
- Max bandwidth: 10 MHz
- Used bandwidth: 10 MHz
- Detection probability: 90%
- Wrong-bin reports: 2%

Expected result:

The best algorithms should remain well below 36%. This confirms that the simulator is not giving the estimator unrealistic predictive power.

### Clustered AFH Case

Settings:

- Hop model: `AFH clustered active map`
- Active bins: 20 to 30
- Max bandwidth: 10 MHz
- Used bandwidth: 10 MHz

Expected result:

Active-map and Markov-style algorithms should improve strongly because the jammer can learn where the connection is spending most of its time.

### Scattered AFH Case

Settings:

- Hop model: `AFH scattered active map`
- Active bins: 20 to 35
- Max bandwidth: 10 MHz
- Used bandwidth: 10 MHz

Expected result:

Density learning may help, but a contiguous jammer window is less effective when active bins are spread across the whole band.

### Response-Time Sensitivity

Keep the hop model fixed and move response time from 0 us to 6000 us.

Expected result:

Algorithms that rely on immediate following should degrade quickly. Algorithms that learn longer-term active regions should be less sensitive to response delay.

## Finding A Candidate Algorithm

A practical candidate should meet more than one condition:

- It reaches or exceeds 36% in the relevant hop model.
- It remains near 36% when response time increases.
- It remains stable when detection probability is reduced.
- It is not highly dependent on one seed.
- It is simple enough to run on the embedded platform.

The best-looking browser result should be treated as a shortlist, not the final answer.

## Suggested Parameter Sweeps

Use these sweeps to understand design margins:

- Response time: 0 us to 6000 us.
- Active bins: 20 to 79.
- Used bandwidth: 1 MHz to the configured maximum.
- Detection probability: 50% to 100%.
- Wrong-bin reports: 0% to 20%.
- Packet count: short runs for quick iteration, longer runs for confirmation.

## How To Read The Charts

The response-time chart shows disruption percentage for each algorithm across response-time values. The horizontal target line is 36%.

The jam-band snapshot shows a short section of the best algorithm's decisions:

- The shaded vertical band is the jammer window.
- The small point is the actual Bluetooth hop bin.
- Green points indicate the hop was inside the jam window.
- Red points indicate the hop was outside the jam window.

## Report-Writing Guidance

When documenting results, include:

- Hop model and active-bin count.
- Max and used bandwidth.
- Response time.
- Detection probability and wrong-bin probability.
- Packet count.
- Seed.
- Best algorithm.
- Disrupted packet count and percentage.
- Whether the result met 36%.

Also state why the chosen hop model is relevant to the real system. For example, a clustered AFH result is only meaningful if the real Bluetooth connection under test actually uses a reduced or clustered active channel map.
