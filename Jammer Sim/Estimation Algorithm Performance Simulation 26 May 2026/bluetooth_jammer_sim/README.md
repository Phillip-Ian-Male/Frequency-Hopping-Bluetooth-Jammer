# Bluetooth Jammer Simulation Package

This package is a simulation-only platform for testing frequency-hopping jammer algorithms. It does not control radio hardware or transmit RF energy.

## Model

- Bluetooth Classic style channel plan: 79 bins from 2402 MHz to 2480 MHz.
- One packet/hop slot defaults to 625 us.
- The simulated Bluetooth link uses a deterministic, embedded-style PRNG.
- Each 79-slot epoch is a seeded permutation of all 79 bins, so the link covers the full band.
- The jammer covers one contiguous window. The default is 10 bins, representing 10 MHz.
- The jammer can only retune every `response_slots` Bluetooth hops. The default is 10, meaning it is 10x slower than the Bluetooth hop rate.
- The default jammer is `SweepJammer`, a deliberately weak baseline that sweeps across the band.

## Run

From the repository root:

```powershell
python -m bluetooth_jammer_sim.cli --slots 10000 --recover-state-samples 24 --show-first 12
```

If Python is not on PATH, run the same module with whichever Python launcher is installed on the machine.

Useful options:

```powershell
python -m bluetooth_jammer_sim.cli --slots 50000 --jammer-bandwidth 10 --response-slots 10
python -m bluetooth_jammer_sim.cli --rng-bits 12 --seed 0xA53 --recover-state-samples 20
python -m bluetooth_jammer_sim.cli --detect-probability 0.85 --false-detection-probability 0.02
```

## Insert A New Algorithm

Create a class that inherits from `JammerAlgorithm` and returns a `JamWindow` when the simulator asks for a decision:

```python
from bluetooth_jammer_sim.jammer import JamWindow, JammerAlgorithm


class MyAlgorithm(JammerAlgorithm):
    name = "my-algorithm"

    def reset(self, runtime):
        super().reset(runtime)
        self.history = []

    def observe(self, observation):
        if observation.observed_channel is not None:
            self.history.append((observation.slot, observation.observed_channel))

    def choose_window(self, snapshot):
        # Replace this with the real algorithm.
        return JamWindow(0, snapshot.runtime.bandwidth_bins, snapshot.runtime.channel_count)
```

Then pass it into the simulation:

```python
from bluetooth_jammer_sim import BluetoothJammerSimulation, SimulationConfig

result = BluetoothJammerSimulation(SimulationConfig(), MyAlgorithm()).run()
print(result.packet_loss_percent)
```

## State Recovery

`recover_initial_seed` brute-forces the simulator's default PRNG seed from observed `(slot, channel)` pairs. This is included so estimator code can be tested against a target whose internal state is recoverable and whose future hops can be predicted exactly after recovery.
