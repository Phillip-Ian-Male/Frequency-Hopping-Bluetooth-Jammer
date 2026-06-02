"""Simulation loop for Bluetooth-like packets and retune-limited jammers."""

from __future__ import annotations

import random
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

from .bluetooth import BluetoothClassicLikeHopGenerator, BluetoothModelConfig, HopEvent
from .jammer import (
    JamWindow,
    JammerAlgorithm,
    JammerObservation,
    JammerRuntimeConfig,
    JammerSnapshot,
)


@dataclass(frozen=True)
class SimulationConfig:
    slot_count: int = 10_000
    bluetooth: BluetoothModelConfig = field(default_factory=BluetoothModelConfig)
    jammer_bandwidth_bins: int = 10
    jammer_response_slots: int = 10
    detection_probability: float = 1.0
    false_detection_probability: float = 0.0
    detector_seed: int = 1

    def __post_init__(self) -> None:
        if self.slot_count <= 0:
            raise ValueError("slot_count must be positive")
        if self.jammer_bandwidth_bins <= 0:
            raise ValueError("jammer_bandwidth_bins must be positive")
        if self.jammer_bandwidth_bins > self.bluetooth.channel_count:
            raise ValueError("jammer_bandwidth_bins cannot exceed Bluetooth channel count")
        if self.jammer_response_slots <= 0:
            raise ValueError("jammer_response_slots must be positive")
        if not 0.0 <= self.detection_probability <= 1.0:
            raise ValueError("detection_probability must be between 0 and 1")
        if not 0.0 <= self.false_detection_probability <= 1.0:
            raise ValueError("false_detection_probability must be between 0 and 1")


@dataclass(frozen=True)
class PacketRecord:
    slot: int
    clock: int
    channel: int
    frequency_mhz: int
    jam_window: JamWindow
    jammed: bool
    observed_channel: Optional[int]
    detected: bool
    false_detection: bool


@dataclass(frozen=True)
class JamDecisionRecord:
    slot: int
    decision_index: int
    window: JamWindow


@dataclass(frozen=True)
class SimulationResult:
    config: SimulationConfig
    packets: Tuple[PacketRecord, ...]
    decisions: Tuple[JamDecisionRecord, ...]

    @property
    def total_packets(self) -> int:
        return len(self.packets)

    @property
    def jammed_packets(self) -> int:
        return sum(1 for packet in self.packets if packet.jammed)

    @property
    def packet_loss_rate(self) -> float:
        if not self.packets:
            return 0.0
        return self.jammed_packets / len(self.packets)

    @property
    def packet_loss_percent(self) -> float:
        return self.packet_loss_rate * 100.0

    def jammed_by_channel(self) -> Dict[int, int]:
        counts = {channel: 0 for channel in range(self.config.bluetooth.channel_count)}
        for packet in self.packets:
            if packet.jammed:
                counts[packet.channel] += 1
        return counts

    def summary(self) -> Dict[str, float | int]:
        return {
            "total_packets": self.total_packets,
            "jammed_packets": self.jammed_packets,
            "packet_loss_percent": self.packet_loss_percent,
            "jammer_decisions": len(self.decisions),
            "jammer_bandwidth_bins": self.config.jammer_bandwidth_bins,
            "jammer_response_slots": self.config.jammer_response_slots,
        }


class BluetoothJammerSimulation:
    """Runs a target link against a jammer algorithm."""

    def __init__(self, config: SimulationConfig, jammer: JammerAlgorithm) -> None:
        self.config = config
        self.jammer = jammer

    def run(self) -> SimulationResult:
        target = BluetoothClassicLikeHopGenerator(self.config.bluetooth)
        detector_rng = random.Random(self.config.detector_seed)
        runtime = JammerRuntimeConfig(
            channel_count=self.config.bluetooth.channel_count,
            bandwidth_bins=self.config.jammer_bandwidth_bins,
            response_slots=self.config.jammer_response_slots,
            slot_us=self.config.bluetooth.slot_us,
        )
        self.jammer.reset(runtime)

        observations_since_decision: List[JammerObservation] = []
        packets: List[PacketRecord] = []
        decisions: List[JamDecisionRecord] = []
        current_window: Optional[JamWindow] = None

        for slot in range(self.config.slot_count):
            if slot % self.config.jammer_response_slots == 0:
                snapshot = JammerSnapshot(
                    slot=slot,
                    decision_index=len(decisions),
                    runtime=runtime,
                    current_window=current_window,
                    observations=tuple(observations_since_decision),
                )
                observations_since_decision.clear()
                current_window = self.jammer.choose_window(snapshot)
                decisions.append(
                    JamDecisionRecord(
                        slot=slot,
                        decision_index=len(decisions),
                        window=current_window,
                    )
                )

            hop = target.next_hop()
            assert current_window is not None
            observed_channel, detected, false_detection = self._detect_channel(hop, detector_rng)
            observation = JammerObservation(slot=slot, observed_channel=observed_channel)
            observations_since_decision.append(observation)
            self.jammer.observe(observation)

            packets.append(
                PacketRecord(
                    slot=slot,
                    clock=hop.clock,
                    channel=hop.channel,
                    frequency_mhz=hop.frequency_mhz,
                    jam_window=current_window,
                    jammed=current_window.contains(hop.channel),
                    observed_channel=observed_channel,
                    detected=detected,
                    false_detection=false_detection,
                )
            )

        return SimulationResult(
            config=self.config,
            packets=tuple(packets),
            decisions=tuple(decisions),
        )

    def _detect_channel(
        self,
        hop: HopEvent,
        detector_rng: random.Random,
    ) -> tuple[Optional[int], bool, bool]:
        detected = detector_rng.random() < self.config.detection_probability
        if not detected:
            return None, False, False

        false_detection = detector_rng.random() < self.config.false_detection_probability
        if not false_detection:
            return hop.channel, True, False

        channel = detector_rng.randrange(self.config.bluetooth.channel_count - 1)
        if channel >= hop.channel:
            channel += 1
        return channel, True, True
