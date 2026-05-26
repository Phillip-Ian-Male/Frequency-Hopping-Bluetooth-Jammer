# Model Assumptions And Limitations

## Main Assumptions

The simulator intentionally models the frequency-decision layer, not the full RF system.

It assumes:

- One Bluetooth connection is present.
- Each packet occupies one hop slot.
- The jammer chooses one contiguous band per decision.
- A packet is disrupted if its hop bin falls inside that band.
- Jamming power, antenna gain, receiver distance, and channel fading are not simulated.
- Detection quality is represented by probability sliders rather than IQ samples.

These assumptions keep the simulation focused on the follower and estimation algorithms.

## Bluetooth Simplifications

The simulator uses 79 classic Bluetooth bins from 2.402 GHz to 2.480 GHz. It does not implement the actual Bluetooth clock, address-dependent hop selection kernel, packet types, retransmissions, whitening, error correction, or adaptive frequency hopping control procedures.

This is deliberate. The project question here is not whether the simulator can reproduce every Bluetooth baseband detail. The question is whether a narrow-band jammer can choose useful frequencies quickly enough under different observation and response-time conditions.

## RF Simplifications

The simulator does not model:

- Signal-to-noise ratio.
- Path loss.
- Directional antenna pattern.
- Amplifier compression.
- SDR tuning latency beyond the response-time slider.
- Spectral leakage.
- Partial overlap between adjacent channels.
- Co-channel Bluetooth interference.

Those effects matter for the final hardware, but including them here would make it harder to isolate the estimation algorithm.

## Jamming Bandwidth Simplification

The jammer bandwidth is rounded to integer one-MHz bins. This matches the Bluetooth channel-bin abstraction and keeps the result easy to interpret.

In hardware, a 10 MHz waveform will have filter shape, rolloff, tuning error, and spectral mask behavior. Those should be verified separately using SDR measurements and a spectrum analyzer.

## Response-Time Simplification

Response time is modeled as slot delay plus fractional overlap. It does not simulate internal pipeline stages separately.

For example, these are all combined into one response-time value:

- SDR receive capture time.
- Signal processing time.
- Algorithm decision time.
- SDR command latency.
- TX retuning time.
- Jamming waveform start time.

This keeps the simulator useful early in design. Later, measured timing from the embedded platform can be inserted as the response-time value.

## Why Pseudo-Random Hopping Is A Hard Limit

If the jammer cannot infer the Bluetooth hop sequence, previous detected bins do not predict future bins. In that case, a 10 MHz jammer over 79 bins should disrupt approximately:

```text
10 / 79 = 12.7%
```

This is far below the 36% target. Therefore, an algorithm meeting 36% in simulation must be exploiting some structure, such as:

- A reduced AFH active map.
- A clustered active region.
- Repeated transition behavior.
- Sequence information leakage.
- A response-time and detection path fast enough to act on relevant observations.

This is an important engineering conclusion, not a simulator failure.

## Interpreting A 36% Result

Meeting 36% in the simulator means the selected model assumptions allow the algorithm to disrupt at least 36% of modeled packets.

It does not automatically prove that the real jammer will disrupt 36% of measured Bluetooth packets. Hardware measurements must still verify:

- Effective RF power at the target.
- Actual occupied bandwidth.
- SDR retuning speed.
- Detection accuracy.
- Real Bluetooth behavior under AFH.
- Packet delivery ratio or packet disruption over the required test interval.

## Safety And Compliance Boundary

The simulator is intended for design analysis. It does not authorize over-the-air jamming or operation outside the applicable legal limits. The project power and bandwidth constraints should be verified using appropriate lab equipment and local regulations before any RF transmission tests.
