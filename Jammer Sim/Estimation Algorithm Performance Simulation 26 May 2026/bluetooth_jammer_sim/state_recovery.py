"""Recover the simulated hop generator seed from observed channels."""

from __future__ import annotations

from dataclasses import dataclass, replace
from typing import Iterable, Optional, Tuple

from .bluetooth import BluetoothClassicLikeHopGenerator, BluetoothModelConfig


@dataclass(frozen=True)
class SeedRecoveryResult:
    candidates: Tuple[int, ...]
    searched_seeds: int
    observations_used: int
    exhausted: bool

    @property
    def unique(self) -> bool:
        return len(self.candidates) == 1

    @property
    def recovered_seed(self) -> Optional[int]:
        if not self.unique:
            return None
        return self.candidates[0]


def recover_initial_seed(
    config: BluetoothModelConfig,
    observations: Iterable[tuple[int, int]],
    max_candidates: int = 16,
    max_rng_bits_without_limit: int = 20,
) -> SeedRecoveryResult:
    """Brute-force the initial PRNG seed against observed ``(slot, channel)`` pairs.

    The default simulator uses a 16-bit PRNG state so this is intentionally
    practical. If you raise ``rng_bits`` above 20, pass a reduced config or add a
    smarter estimator before searching the entire space.
    """

    observed = tuple(sorted({slot: channel for slot, channel in observations}.items()))
    if not observed:
        raise ValueError("at least one observed (slot, channel) pair is required")
    if max_candidates <= 0:
        raise ValueError("max_candidates must be positive")
    if config.rng_bits > max_rng_bits_without_limit:
        raise ValueError(
            "refusing exhaustive recovery above "
            f"{max_rng_bits_without_limit} bits without a custom estimator"
        )

    max_slot = observed[-1][0]
    if max_slot < 0:
        raise ValueError("observation slots must be non-negative")

    observed_by_slot = dict(observed)
    candidates = []
    seed_space = 1 << config.rng_bits

    searched = 0
    exhausted = True

    for seed in range(seed_space):
        searched += 1
        candidate_config = replace(config, initial_seed=seed)
        generator = BluetoothClassicLikeHopGenerator(candidate_config)
        matched = True
        for slot in range(max_slot + 1):
            hop = generator.next_hop()
            expected_channel = observed_by_slot.get(slot)
            if expected_channel is not None and hop.channel != expected_channel:
                matched = False
                break
        if matched:
            candidates.append(seed)
            if len(candidates) >= max_candidates:
                exhausted = False
                break

    return SeedRecoveryResult(
        candidates=tuple(candidates),
        searched_seeds=searched,
        observations_used=len(observed),
        exhausted=exhausted,
    )
