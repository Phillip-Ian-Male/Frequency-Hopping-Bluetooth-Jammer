# Simulation Design

## Purpose

The simulator was built to compare follower and estimation jamming algorithms before committing to an embedded implementation. It focuses on the decision problem faced by the jammer:

- A single Bluetooth connection hops across 79 one-MHz bins.
- The jammer can cover only a contiguous subset of those bins at any instant.
- Detection information arrives with uncertainty.
- The jammer has a configurable response time before its chosen band can affect the target packet.

The result of each algorithm is measured as disrupted packets and disruption percentage, with 36% used as the project target.

## System Abstraction

The simulated Bluetooth range is represented as integer bins:

- Bin 0 maps to 2.402 GHz.
- Bin 78 maps to 2.480 GHz.
- Each bin is treated as 1 MHz wide.
- Each hop slot is 625 us, matching the 1600 hops/s Bluetooth timing requirement.

The jammer bandwidth is also represented in bins. A 10 MHz jammer therefore covers 10 adjacent bins. This makes the frequency decision discrete and directly comparable to the 79-bin Bluetooth model.

## Why A Contiguous Jam Window

The project requirement says the system can jam only part of the 80 MHz Bluetooth bandwidth, with the default maximum set to 10 MHz. The simulator assumes this available bandwidth is one contiguous RF window because that is the natural model for a narrow-band SDR transmitter centered at a chosen frequency.

This is stricter than allowing the jammer to place ten independent one-MHz notches anywhere in the band. It makes the simulation closer to the likely hardware behavior and prevents the algorithms from receiving an unrealistic advantage.

## Hop Models

Four hop models are included so the algorithms can be tested under different levels of exploitable structure.

`Classic pseudo-random`

Models a connection where the jammer sees no useful future-bin structure. The generator repeatedly shuffles all 79 bins. This is the sanity-check case: previous observations should not make accurate prediction possible.

`AFH clustered active map`

Models adaptive frequency hopping where the connection is using a smaller cluster of active channels. This is included because a narrow-band jammer can perform much better if the actual active map is narrower than the full 79-bin range.

`AFH scattered active map`

Models adaptive frequency hopping with active bins spread throughout the band. This tests whether density-based algorithms can learn useful channel preference without relying on one compact cluster.

`Hidden stride with jitter`

Models a hop stream with a repeated stride pattern plus random disturbance. This is not intended to claim Bluetooth exposes such a simple sequence. It is included as an estimator stress test: if sequence leakage or repeated structure exists, stride-like algorithms should discover it.

## Detector Model

The detector produces one observation per packet slot:

- With the configured detection probability, the detector reports the current hop bin.
- With the configured wrong-bin probability, the reported bin is replaced by a random incorrect bin.
- If detection fails, the algorithm receives no observation for that slot.

This separates RF detection quality from algorithm quality. It also lets the response-time and estimator choices be tested under weaker receive conditions.

## Response-Time Model

The response-time slider is converted into slot delay:

```text
slot_offset = floor(response_time_us / 625)
fractional_phase = response_time_us / 625 - slot_offset
slot_overlap = 1 - fractional_phase
```

If the response time is exactly 1250 us, the jammer acts two slots later with full overlap. If the response time is 1500 us, the jammer acts two slots later but only overlaps 60% of that packet slot.

This gives a simple engineering approximation for late transmit timing without simulating waveform-level timing.

## Packet Disruption Metric

A packet is counted as disrupted when the actual hop bin lies inside the algorithm's selected jam window. If the response time has fractional-slot delay, the packet contributes partial disruption according to the overlap factor.

For example:

- Full overlap and correct band: 1 disrupted packet.
- 50% overlap and correct band: 0.5 disrupted packets.
- Wrong band: 0 disrupted packets.

The table rounds the disrupted packet count for readability, but the percentage uses the fractional result.

## Why A Browser Simulator

The simulator is a single `index.html` file with no external dependencies. This was chosen so it can be opened on any project machine without installing Python packages, Node packages, plotting libraries, or a local server.

The implementation keeps the model deterministic through a seed value, which makes experiments repeatable when comparing algorithms or report figures.

## Data Flow

Each run follows this sequence:

1. Generate the hop stream from the selected hop model.
2. Generate detector observations from the hop stream.
3. Run every algorithm at the selected response time.
4. Run every algorithm over a response-time sweep.
5. Render the summary metrics, table, response-time chart, and jam-band snapshot.

All algorithms receive the same hop stream and detector observations for the selected run. This makes the comparison fair for a given seed.
