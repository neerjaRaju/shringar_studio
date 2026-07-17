"""Duplicate & similarity detection.

Two layers:
1. exact  — sha256 of the stored WebP file
2. near   — perceptual dHash with Hamming-distance threshold
Prompt-level dedup (semantic fingerprints) happens in the prompt engine.
"""
from __future__ import annotations

from .processing.image_processor import hamming


class DuplicateIndex:
    def __init__(self, threshold: int = 6) -> None:
        self.threshold = threshold
        self._sha: set[str] = set()
        self._phashes: list[str] = []

    @classmethod
    def from_rows(cls, rows: list[tuple[str, str]], threshold: int = 6) -> "DuplicateIndex":
        idx = cls(threshold)
        for sha, phash in rows:
            idx.add(sha, phash)
        return idx

    def add(self, sha256: str, phash: str) -> None:
        self._sha.add(sha256)
        self._phashes.append(phash)

    def is_duplicate(self, sha256: str, phash: str) -> bool:
        if sha256 in self._sha:
            return True
        return any(hamming(phash, existing) <= self.threshold for existing in self._phashes)
