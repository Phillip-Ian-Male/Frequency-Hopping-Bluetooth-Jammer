"""Jammer algorithm interfaces and baseline implementations."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional, Tuple


@dataclass(frozen=True)
class JamWindow:
    """A contiguous jamming window over the simulated Bluetooth channel bins."""

    start_channel: int
    bandwidth_bins: int
    channel_count: int = 79

    def __post_init__(self) -> None:
        if self.bandwidth_bins <= 0:
            raise ValueError("bandwidth_bins must be positive")
        if self.channel_count <= 0:
            raise ValueError("channel_count must be positive")
        if self.bandwidth_bins > self.channel_count:
            raise ValueError("bandwidth_bins cannot exceed channel_count")
        max_start = self.channel_count - self.bandwidth_bins
        if not 0 <= self.start_channel <= max_start:
            raise ValueError(f"start_channel must be between 0 and {max_start}")

    @property
    def stop_channel_exclusive(self) -> int:
        return self.start_channel + self.bandwidth_bins

    @property
    def end_channel(self) -> int:
        return self.stop_channel_exclusive - 1

    def contains(self, channel: int) -> bool:
        return self.start_channel <= channel < self.stop_channel_exclusive

    @classmethod
    def clamped(cls, start_channel: int, bandwidth_bins: int, channel_count: int = 79) -> "JamWindow":
        max_start = max(0, channel_count - bandwidth_bins)
        start = min(max(0, start_channel), max_start)
        return cls(start, bandwidth_bins, channel_count)


@dataclass(frozen=True)
class JammerRuntimeConfig:
    channel_count: int
    bandwidth_bins: int
    response_slots: int
    slot_us: int

    @property
    def response_time_us(self) -> int:
        return self.response_slots * self.slot_us


@dataclass(frozen=True)
class JammerObservation:
    """What the jammer-side algorithm is allowed to see for one slot."""

    slot: int
    observed_channel: Optional[int]


@dataclass(frozen=True)
class JammerSnapshot:
    """Decision-time context passed into a jammer algorithm."""

    slot: int
    decision_index: int
    runtime: JammerRuntimeConfig
    current_window: Optional[JamWindow]
    observations: Tuple[JammerObservation, ...]


class JammerAlgorithm:
    """Base class for algorithms that choose jammer frequency windows."""

    name = "base"

    def reset(self, runtime: JammerRuntimeConfig) -> None:
        self.runtime = runtime

    def observe(self, observation: JammerObservation) -> None:
        pass

    def choose_window(self, snapshot: JammerSnapshot) -> JamWindow:
        raise NotImplementedError


class SweepJammer(JammerAlgorithm):
    """Weak baseline that repeatedly sweeps a contiguous window across the band."""

    name = "linear-sweep"

    def __init__(self, step_bins: int | None = None) -> None:
        self.step_bins = step_bins
        self._starts: Tuple[int, ...] = ()
        self._position = 0

    def reset(self, runtime: JammerRuntimeConfig) -> None:
        super().reset(runtime)
        step = self.step_bins or runtime.bandwidth_bins
        if step <= 0:
            raise ValueError("step_bins must be positive")

        max_start = runtime.channel_count - runtime.bandwidth_bins
        starts = list(range(0, max_start + 1, step))
        if starts[-1] != max_start:
            starts.append(max_start)
        self._starts = tuple(starts)
        self._position = 0

    def choose_window(self, snapshot: JammerSnapshot) -> JamWindow:
        if not self._starts:
            self.reset(snapshot.runtime)
        start = self._starts[self._position]
        self._position = (self._position + 1) % len(self._starts)
        return JamWindow(start, snapshot.runtime.bandwidth_bins, snapshot.runtime.channel_count)
