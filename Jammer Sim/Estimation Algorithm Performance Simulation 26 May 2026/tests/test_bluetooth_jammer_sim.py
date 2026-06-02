import unittest
from dataclasses import replace

from bluetooth_jammer_sim.bluetooth import BluetoothClassicLikeHopGenerator, BluetoothModelConfig
from bluetooth_jammer_sim.jammer import SweepJammer
from bluetooth_jammer_sim.simulation import BluetoothJammerSimulation, SimulationConfig
from bluetooth_jammer_sim.state_recovery import recover_initial_seed


class BluetoothJammerSimulationTests(unittest.TestCase):
    def test_hop_epoch_uses_all_79_bins(self):
        config = BluetoothModelConfig(rng_bits=12, initial_seed=0xA53)
        generator = BluetoothClassicLikeHopGenerator(config)

        channels = [generator.next_hop().channel for _ in range(config.channel_count)]

        self.assertEqual(set(range(config.channel_count)), set(channels))

    def test_seed_recovery_predicts_same_future(self):
        config = BluetoothModelConfig(rng_bits=12, initial_seed=0xA53)
        source = BluetoothClassicLikeHopGenerator(config)
        observations = [(slot, source.next_hop().channel) for slot in range(24)]

        recovery = recover_initial_seed(config, observations, max_candidates=4)

        self.assertTrue(recovery.unique)
        recovered_config = replace(config, initial_seed=recovery.recovered_seed)
        actual = BluetoothClassicLikeHopGenerator(config)
        predicted = BluetoothClassicLikeHopGenerator(recovered_config)
        self.assertEqual(actual.peek_channels(120), predicted.peek_channels(120))

    def test_sweep_jammer_is_weak_against_full_band_hopping(self):
        bluetooth = BluetoothModelConfig(rng_bits=12, initial_seed=0xA53)
        config = SimulationConfig(slot_count=7900, bluetooth=bluetooth, jammer_response_slots=10)

        result = BluetoothJammerSimulation(config, SweepJammer()).run()

        self.assertGreater(result.packet_loss_rate, 0.05)
        self.assertLess(result.packet_loss_rate, 0.22)

    def test_response_slots_control_decision_count(self):
        config = SimulationConfig(slot_count=25, jammer_response_slots=10)

        result = BluetoothJammerSimulation(config, SweepJammer()).run()

        self.assertEqual(3, len(result.decisions))


if __name__ == "__main__":
    unittest.main()
