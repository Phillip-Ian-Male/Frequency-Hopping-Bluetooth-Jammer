# Bluetooth Follower / Estimation Jammer Simulator

Open `index.html` in a browser to run the original follower/estimation simulator.

Open `active-map-learning.html` to run the second feasibility simulator that focuses on active-channel-map learning and heavier learning agents.

Open `ble-jamming-sequence.html` to run the BLE version of the second simulator, using 37 BLE data channels and CSA #1 / CSA #2 style channel selection.

Open `exact-hop-prediction.html` to run the theoretical upper-bound simulator for active pretraining and exact future-hop prediction.

Open `posterior-approximation.html` to compare practical real-time approximations to posterior majority voting, including a Jetson Nano-class particle tracker.

Open `speech-packet-loss-player.html` to play `Blood Meridian - The Judge on War.mp3` through a real-time Bluetooth-style packet-loss simulator from 0% to 100%.

The simulator models one Bluetooth connection over 79 one-MHz hop bins from 2.402 GHz to 2.480 GHz. The jammer can cover an adjustable contiguous bandwidth, with the default maximum set to 10 MHz. The target line is 36% disrupted packets.

## Adjustable Inputs

- Hop model: pseudo-random, AFH clustered, AFH scattered, or hidden stride with jitter.
- Max bandwidth and used jamming bandwidth.
- System response time in microseconds.
- Detector probability and wrong-bin report probability.
- Packet count and random seed.

## Implemented Algorithms

- Random Window
- Linear Sweep
- Last-Bin Follower
- Stride Estimator
- Markov Tracker
- Active-Map Density
- Hybrid Estimator

## Important Assumption

If the hop sequence is effectively pseudo-random to the jammer, previous detected bins do not provide useful future-bin information. In that case, a 10 MHz jammer over 79 bins should sit near the bandwidth fraction rather than 36%. The AFH and stride models are included to test when a practical estimator can exploit active-channel clustering, repeated transitions, or sequence leakage.

## Design Notes

- [Simulation design](docs/simulation-design.md)
- [Algorithm engineering decisions](docs/algorithm-decisions.md)
- [Model assumptions and limitations](docs/assumptions-limitations.md)
- [Experiment guide](docs/experiment-guide.md)
- [Hidden stride with jitter model](docs/hidden-stride-with-jitter.md)
- [Active-map learning feasibility simulator](docs/active-map-learning-simulation.md)
- [BLE jamming sequence simulator](docs/ble-jamming-sequence-simulation.md)
- [Exact-hop prediction pretraining simulator](docs/exact-hop-prediction-simulation.md)
- [Posterior approximation real-time simulator](docs/posterior-approximation-simulation.md)
