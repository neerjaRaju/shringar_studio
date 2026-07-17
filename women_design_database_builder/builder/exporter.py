"""JSON exports: full designs.json + incremental update.json."""
from __future__ import annotations

import datetime as dt
import json
import pathlib

from .database import DesignDatabase


def export_full(db: DesignDatabase, path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "generated_at": _now(),
        "count": db.count(),
        "designs": db.all_records(),
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=1), encoding="utf-8")


def export_update(
    db: DesignDatabase,
    path: pathlib.Path,
    new_ids: list[str],
    *,
    owner: str,
    repo: str,
    version: str | None = None,
) -> dict:
    """update.json consumed by the Flutter app's incremental updater."""
    path.parent.mkdir(parents=True, exist_ok=True)
    version = version or dt.datetime.now(dt.timezone.utc).strftime("%Y.%m.%d.%H%M")
    all_records = {r["id"]: r for r in db.all_records()}
    payload = {
        "version": version,
        "generated_at": _now(),
        "total_designs": db.count(),
        "db_asset": "shringar.db",
        "db_url": f"https://github.com/{owner}/{repo}/releases/latest/download/shringar.db",
        "new_design_ids": new_ids,
        "new_designs": [all_records[i] for i in new_ids if i in all_records],
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=1), encoding="utf-8")
    return payload


def _now() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
