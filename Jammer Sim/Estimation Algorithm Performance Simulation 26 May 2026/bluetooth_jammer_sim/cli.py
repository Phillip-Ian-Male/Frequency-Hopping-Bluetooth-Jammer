"""Command line entry point for the Bluetooth jammer simulator."""

from __future__ import annotations

import argparse
from dataclasses import replace
from typing import Sequence

from .bluetooth import BluetoothClassicLikeHopGenerator, BluetoothModelConfig
from .jammer import SweepJammer
from .simulation import BluetoothJammerSimulation, SimulationConfig
from .state_recovery import recover_initial_seed


def _int_auto(value: str) -> int:
    return int(value, 0)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run a Bluetooth-like frequency hopping jammer simulation.",
    )
    parser.add_argument("--slots", type=int, default=10_000, help="Bluetooth packet slots to simulate.")
    parser.add_argument("--seed", type=_int_auto, default=0xACE1, help="Initial hop PRNG seed.")
    parser.add_argument("--rng-bits", type=int, default=16, help="Hop PRNG state width.")
    parser.add_argument("--address", type=_int_auto, default=0x9E8B33, help="Simulated master address salt.")
    parser.add_argument("--master-clock", type=_int_auto, default=0, help="Initial 28-bit master clock.")
    parser.add_argument("--jammer-bandwidth", type=int, default=10, help="Jammer bandwidth in 1 MHz bins.")
    parser.add_argument(
        "--response-slots",
        type=int,
        default=10,
        help="How many Bluetooth hops pass before the jammer can retune.",
    )
    parser.add_argument("--sweep-step", type=int, default=None, help="Sweep step in bins; default is bandwidth.")
    parser.add_argument("--detect-probability", type=float, default=1.0, help="Probability of detecting each hop.")
    parser.add_argument(
        "--false-detection-probability",
        type=float,
        default=0.0,
        help="Probability that a detected hop is reported as the wrong bin.",
    )
    parser.add_argument("--detector-seed", type=_int_auto, default=1, help="Detector randomness seed.")
    parser.add_argument(
        "--recover-state-samples",
        type=int,
        default=0,
        help="Use the first N clean observations to recover the simulated hop seed.",
    )
    parser.add_argument("--show-first", type=int, default=0, help="Print the first N packet records.")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    bluetooth_config = BluetoothModelConfig(
        rng_bits=args.rng_bits,
        initial_seed=args.seed,
        master_clock=args.master_clock,
        master_address=args.address,
    )
    sim_config = SimulationConfig(
        slot_count=args.slots,
        bluetooth=bluetooth_config,
        jammer_bandwidth_bins=args.jammer_bandwidth,
        jammer_response_slots=args.response_slots,
        detection_probability=args.detect_probability,
        false_detection_probability=args.false_detection_probability,
        detector_seed=args.detector_seed,
    )
    result = BluetoothJammerSimulation(sim_config, SweepJammer(step_bins=args.sweep_step)).run()

    print("Bluetooth jammer simulation")
    print(f"  channels: {bluetooth_config.channel_count} bins, {bluetooth_config.first_channel_mhz}-{bluetooth_config.last_channel_mhz} MHz")
    print(f"  hop slot: {bluetooth_config.slot_us} us")
    print(f"  jammer: {args.jammer_bandwidth} MHz sweep, retunes every {args.response_slots} slots ({args.response_slots * bluetooth_config.slot_us} us)")
    print(f"  packets: {result.total_packets}")
    print(f"  jammed: {result.jammed_packets}")
    print(f"  packet loss: {result.packet_loss_percent:.2f}%")
    print(f"  jammer decisions: {len(result.decisions)}")

    if args.show_first > 0:
        print()
        print("first packets:")
        for packet in result.packets[: args.show_first]:
            observed = "-" if packet.observed_channel is None else str(packet.observed_channel)
            print(
                f"  slot={packet.slot:5d} ch={packet.channel:2d} "
                f"jam={packet.jam_window.start_channel:2d}-{packet.jam_window.end_channel:2d} "
                f"hit={int(packet.jammed)} obs={observed}"
            )

    if args.recover_state_samples > 0:
        observations = [
            (packet.slot, packet.observed_channel)
            for packet in result.packets
            if packet.observed_channel is not None
        ][: args.recover_state_samples]
        recovery = recover_initial_seed(bluetooth_config, observations)
        print()
        print("state recovery:")
        print(f"  observations used: {recovery.observations_used}")
        print(f"  searched seeds: {recovery.searched_seeds}")
        print(f"  candidates found: {len(recovery.candidates)}")
        if not recovery.exhausted:
            print("  search stopped after reaching the candidate limit")
        if recovery.unique:
            recovered_seed = recovery.recovered_seed
            assert recovered_seed is not None
            print(f"  recovered seed: 0x{recovered_seed:X}")
            predictor_config = replace(bluetooth_config, initial_seed=recovered_seed)
            predictor = BluetoothClassicLikeHopGenerator(predictor_config)
            predictor.advance(observations[-1][0] + 1)
            predicted = predictor.peek_channels(12)
            print("  next predicted channels:", " ".join(str(channel) for channel in predicted))
        else:
            preview = " ".join(f"0x{seed:X}" for seed in recovery.candidates[:8])
            print(f"  candidate preview: {preview}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
