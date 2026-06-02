"""Bluetooth-Classic-like frequency hopping model.

This is a simulation model, not a hardware radio implementation. It keeps the
important engineering dimensions used by Bluetooth Classic: 79 one-MHz
channels, 625 us hop slots, a master clock, and a deterministic address/clock
dependent hop sequence.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import List, Tuple


BLUETOOTH_CLASSIC_CHANNELS = 79
BLUETOOTH_SLOT_US = 625
BLUETOOTH_FIRST_CHANNEL_MHZ = 2402
BLUETOOTH_CHANNEL_WIDTH_MHZ = 1
BLUETOOTH_CLOCK_BITS = 28


def _mix32(value: int) -> int:
    """Small deterministic integer mixer used for seed salting."""

    value &= 0xFFFFFFFF
    value ^= value >> 16
    value = (value * 0x7FEB352D) & 0xFFFFFFFF
    value ^= value >> 15
    value = (value * 0x846CA68B) & 0xFFFFFFFF
    value ^= value >> 16
    return value & 0xFFFFFFFF


def _fold_to_bits(value: int, bits: int) -> int:
    return _mix32(value) & ((1 << bits) - 1)


@dataclass(frozen=True)
class BluetoothModelConfig:
    """Configuration for the Bluetooth-like hopping source."""

    channel_count: int = BLUETOOTH_CLASSIC_CHANNELS
    first_channel_mhz: int = BLUETOOTH_FIRST_CHANNEL_MHZ
    channel_width_mhz: int = BLUETOOTH_CHANNEL_WIDTH_MHZ
    slot_us: int = BLUETOOTH_SLOT_US
    rng_bits: int = 16
    initial_seed: int = 0xACE1
    master_clock: int = 0
    master_address: int = 0x9E8B33

    def __post_init__(self) -> None:
        if self.channel_count <= 0:
            raise ValueError("channel_count must be positive")
        if self.channel_width_mhz <= 0:
            raise ValueError("channel_width_mhz must be positive")
        if self.slot_us <= 0:
            raise ValueError("slot_us must be positive")
        if not 8 <= self.rng_bits <= 31:
            raise ValueError("rng_bits must be between 8 and 31")
        if self.initial_seed < 0:
            raise ValueError("initial_seed must be non-negative")
        if not 0 <= self.master_clock < (1 << BLUETOOTH_CLOCK_BITS):
            raise ValueError("master_clock must fit in 28 bits")
        if self.master_address < 0:
            raise ValueError("master_address must be non-negative")

    @property
    def last_channel_mhz(self) -> int:
        return self.first_channel_mhz + (self.channel_count - 1) * self.channel_width_mhz

    @property
    def seed_mask(self) -> int:
        return (1 << self.rng_bits) - 1

    def channel_frequency_mhz(self, channel: int) -> int:
        if not 0 <= channel < self.channel_count:
            raise ValueError(f"channel must be between 0 and {self.channel_count - 1}")
        return self.first_channel_mhz + channel * self.channel_width_mhz


class EmbeddedLcg:
    """A tiny full-period embedded-style PRNG with inspectable state."""

    _A = 1103515245
    _C = 12345

    def __init__(self, bits: int, seed: int) -> None:
        self.bits = bits
        self.mask = (1 << bits) - 1
        self.state = seed & self.mask

    def clone(self) -> "EmbeddedLcg":
        clone = EmbeddedLcg(self.bits, self.state)
        return clone

    def next_word(self) -> int:
        self.state = (self._A * self.state + self._C) & self.mask
        return self.state

    def randbelow(self, upper: int) -> int:
        if upper <= 0:
            raise ValueError("upper must be positive")
        return (self.next_word() * upper) >> self.bits


@dataclass(frozen=True)
class HopEvent:
    """One Bluetooth packet/hop slot."""

    slot: int
    clock: int
    channel: int
    frequency_mhz: int
    epoch: int
    epoch_index: int


@dataclass(frozen=True)
class GeneratorState:
    """Serializable internal state for exact prediction in the simulator."""

    slot: int
    clock: int
    rng_state: int
    epoch: int
    epoch_index: int
    epoch_channels: Tuple[int, ...]


class BluetoothClassicLikeHopGenerator:
    """Deterministic 79-channel hop generator.

    Each 79-slot epoch is a seeded Fisher-Yates permutation of all channels.
    That gives full-band coverage while keeping a recoverable internal state for
    estimator experiments.
    """

    def __init__(self, config: BluetoothModelConfig | None = None) -> None:
        self.config = config or BluetoothModelConfig()
        seed_salt = _fold_to_bits(
            self.config.master_address ^ self.config.master_clock,
            self.config.rng_bits,
        )
        derived_seed = (self.config.initial_seed & self.config.seed_mask) ^ seed_salt
        self._rng = EmbeddedLcg(self.config.rng_bits, derived_seed)
        self._slot = 0
        self._clock = self.config.master_clock
        self._epoch = 0
        self._epoch_index = 0
        self._epoch_channels = self._build_epoch()

    @property
    def slot(self) -> int:
        return self._slot

    @property
    def clock(self) -> int:
        return self._clock

    def export_state(self) -> GeneratorState:
        return GeneratorState(
            slot=self._slot,
            clock=self._clock,
            rng_state=self._rng.state,
            epoch=self._epoch,
            epoch_index=self._epoch_index,
            epoch_channels=tuple(self._epoch_channels),
        )

    def clone(self) -> "BluetoothClassicLikeHopGenerator":
        clone = self.__class__.__new__(self.__class__)
        clone.config = self.config
        clone._rng = self._rng.clone()
        clone._slot = self._slot
        clone._clock = self._clock
        clone._epoch = self._epoch
        clone._epoch_index = self._epoch_index
        clone._epoch_channels = list(self._epoch_channels)
        return clone

    def next_hop(self) -> HopEvent:
        if self._epoch_index >= self.config.channel_count:
            self._epoch += 1
            self._epoch_index = 0
            self._epoch_channels = self._build_epoch()

        channel = self._epoch_channels[self._epoch_index]
        event = HopEvent(
            slot=self._slot,
            clock=self._clock,
            channel=channel,
            frequency_mhz=self.config.channel_frequency_mhz(channel),
            epoch=self._epoch,
            epoch_index=self._epoch_index,
        )

        self._slot += 1
        self._clock = (self._clock + 1) & ((1 << BLUETOOTH_CLOCK_BITS) - 1)
        self._epoch_index += 1
        return event

    def advance(self, slots: int) -> None:
        if slots < 0:
            raise ValueError("slots must be non-negative")
        for _ in range(slots):
            self.next_hop()

    def peek_channels(self, slots: int) -> Tuple[int, ...]:
        clone = self.clone()
        return tuple(clone.next_hop().channel for _ in range(slots))

    def _build_epoch(self) -> List[int]:
        channels = list(range(self.config.channel_count))
        for index in range(self.config.channel_count - 1, 0, -1):
            swap_index = self._rng.randbelow(index + 1)
            channels[index], channels[swap_index] = channels[swap_index], channels[index]
        return channels
