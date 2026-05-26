# BLE Jamming Sequence Simulator

## Purpose

`ble-jamming-sequence.html` is a BLE-specific copy of the active-map learning feasibility simulator.

It changes the radio model from Classic Bluetooth-style 79 one-MHz bins to Bluetooth Low Energy data channels:

- 37 data channels.
- 2 MHz channel spacing.
- First data channel center at 2.402 GHz.
- Configurable BLE connection interval.
- CSA #1, CSA #2-style, or random-over-used channel selection.

This simulator is useful for testing whether the active-channel-map learning idea becomes more plausible on BLE hardware such as CC2541/HM-10, TI CC26xx, Nordic nRF52, or ESP32 BLE links.

## Why BLE Is A Separate Simulator

BLE is not just Classic Bluetooth with fewer channels. It uses a different channel plan and different connection timing.

Classic Bluetooth audio normally uses 79 one-MHz channels and 625 us slot timing. BLE uses 37 two-MHz data channels and hops once per connection event. The minimum BLE connection interval is 7.5 ms, which gives much more time for an estimator to make a decision.

That timing difference makes BLE a better controlled test platform for early algorithm work, but BLE results should not be used as direct proof for a Classic Bluetooth audio jammer.

## Bandwidth Conversion

The UI still asks for jammer bandwidth in MHz. Internally, this is converted to BLE channel coverage:

```text
jammed_ble_channels = ceil(jammer_bandwidth_mhz / 2)
```

So a 10 MHz jammer covers 5 BLE data channels.

For a uniform active map, the rough feasibility condition is:

```text
5 / used_ble_channels >= 0.36
used_ble_channels <= 13.8
```

That means a 10 MHz contiguous jammer can meet 36% by active-map learning only if the used BLE channel map is small enough or concentrated enough.

## Channel Selection Modes

`BLE CSA #1`

Uses the simple BLE Channel Selection Algorithm #1 structure:

```text
unmapped = (last_unmapped + hop_increment) mod 37
```

If the unmapped channel is unused, it is remapped into the used-channel table. This is the most useful mode for testing older BLE 4.x-style behavior.

`BLE CSA #2 style`

Uses a CSA #2-style pseudo-random event counter and channel identifier model. It uses permutation and multiply-add-modulo operations to produce an unmapped channel, then remaps unused channels into the used-channel table.

This is closer to modern BLE behavior, but the simulator intentionally keeps it lightweight rather than implementing every Bluetooth Core detail.

`Random over used channels`

Selects a random channel from the current used-channel map. This is a baseline for active-map-only learning.

## Active Map Layouts

The same active-map layouts from the second testbench are available:

- Clustered AFH map.
- Scattered AFH map.
- Dual-cluster AFH map.
- Slow drifting cluster.

Clustered maps are much more favorable for a contiguous jammer. Scattered maps are harder because the same number of used channels may be spread across the whole BLE band.

## Response-Time Model

For BLE, response time determines how many future connection events the algorithm must predict.

If response time is less than the connection interval, the simulator assumes the jammer can prepare for the next connection event. If response time exceeds one connection interval, the algorithm predicts further ahead.

This is different from the Classic Bluetooth slot simulator, where fractional overlap inside a 625 us slot was more important.

## Algorithms

The BLE simulator keeps the same learning agents as the active-map feasibility simulator:

- Oracle Active-Map Bound.
- Random Window.
- Embedded EMA Map.
- Bayesian Channel Map.
- Two-Rate Change Learner.
- UCB Window Bandit.
- Jetson Particle Ensemble.

The oracle bound is still the most important line in the table. If the oracle active-map bound is below 36%, then active-map learning alone cannot meet the requirement in that BLE scenario.

## Engineering Interpretation

BLE can be more favorable than Classic Bluetooth for early experiments because:

- There are fewer data channels.
- Connection intervals are usually much longer than 625 us.
- Older BLE devices may use simpler channel selection behavior.
- You can more easily control both endpoints in a lab setup.

But BLE is not the same as Bluetooth audio. Use this simulator to develop and compare estimators, then validate any final claim against the actual Bluetooth mode required by the project.
