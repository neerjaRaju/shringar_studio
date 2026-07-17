"""Configuration loader."""
from __future__ import annotations

import pathlib
from dataclasses import dataclass, field
from typing import Any

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent


@dataclass(frozen=True)
class Config:
    raw: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def load(cls, path: pathlib.Path | None = None) -> "Config":
        cfg_path = path or ROOT / "config.yaml"
        with open(cfg_path, "r", encoding="utf-8") as fh:
            return cls(raw=yaml.safe_load(fh))

    def get(self, *keys: str, default: Any = None) -> Any:
        node: Any = self.raw
        for key in keys:
            if not isinstance(node, dict) or key not in node:
                return default
            node = node[key]
        return node

    # Convenience accessors -------------------------------------------------
    @property
    def cdn_base(self) -> str:
        return self.get("github", "cdn_base", default="").rstrip("/")

    @property
    def db_path(self) -> pathlib.Path:
        return ROOT / self.get("database", "path", default="data/db/shringar.db")

    @property
    def images_dir(self) -> pathlib.Path:
        return ROOT / "data" / "images"

    @property
    def thumbs_dir(self) -> pathlib.Path:
        return ROOT / "data" / "thumbnails"

    @property
    def exports_dir(self) -> pathlib.Path:
        return ROOT / "data" / "exports"
