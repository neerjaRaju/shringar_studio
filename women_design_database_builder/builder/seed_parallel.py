"""Parallel seed generator — used for the initial local seed build only.

The daily GitHub Action uses the sequential `python -m builder --count 2`
pipeline. This helper fetches many images concurrently to bootstrap the first
database quickly, then runs the exact same processing / dedup / DB / export code.

Usage: python -m builder.seed_parallel --count 40 --seed 7 --workers 10
"""
from __future__ import annotations

import argparse
import logging
import random
from concurrent.futures import ThreadPoolExecutor, as_completed

from .config import Config
from .database import DesignDatabase
from .dedup import DuplicateIndex
from .exporter import export_full, export_update
from .generation.provider import SIZE_BY_ORIENTATION, get_provider
from .metadata import build_record, make_id
from .processing.image_processor import process_image
from .prompt_engine.engine import PromptEngine

log = logging.getLogger("seed")


def _fetch_one(provider, spec, cfg, rng):
    edge = rng.choice(cfg.get("generation", "sizes", default=[1024]))
    orientation = rng.choice(cfg.get("generation", "orientations", default=["square"]))
    width, height = SIZE_BY_ORIENTATION[orientation](edge)
    raw = provider.generate(spec.prompt, width, height, spec.seed)
    return spec, raw


def run(count: int, seed: int | None, workers: int) -> list[str]:
    cfg = Config.load()
    rng = random.Random(seed)
    engine = PromptEngine(rng)
    provider = get_provider(
        cfg.get("generation", "provider", default="pollinations"),
        timeout=cfg.get("generation", "timeout_seconds", default=120),
        retries=cfg.get("generation", "retries", default=3),
        backoff=cfg.get("generation", "retry_backoff_seconds", default=10),
    )
    db = DesignDatabase(cfg.db_path)
    db.upsert_categories(engine.categories)
    dup = DuplicateIndex.from_rows(
        db.hashes_and_phashes(),
        threshold=cfg.get("dedup", "phash_hamming_threshold", default=6),
    )
    seen = db.fingerprints()
    specs = engine.generate_batch(count, seen)
    log.info("seeding %d designs with %d workers", len(specs), workers)

    quality = cfg.get("processing", "quality", default=82)
    thumb_q = cfg.get("processing", "thumbnail_quality", default=75)
    thumb_sizes = tuple(cfg.get("processing", "thumbnail_sizes", default=[512, 256, 128]))
    premium_nth = cfg.get("premium", "every_nth", default=5)

    new_ids: list[str] = []
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futs = {pool.submit(_fetch_one, provider, s, cfg, random.Random(s.seed)): s for s in specs}
        for fut in as_completed(futs):
            try:
                spec, raw = fut.result()
                design_id = make_id(spec)
                processed = process_image(
                    raw, design_id, cfg.images_dir, cfg.thumbs_dir,
                    quality=quality, thumb_quality=thumb_q, thumb_sizes=thumb_sizes,
                )
                if dup.is_duplicate(processed.sha256, processed.phash):
                    processed.image_path.unlink(missing_ok=True)
                    for p in processed.thumbnail_paths.values():
                        p.unlink(missing_ok=True)
                    continue
                dup.add(processed.sha256, processed.phash)
                is_premium = (db.count() + len(new_ids) + 1) % premium_nth == 0
                db.insert(build_record(spec, processed, cfg.cdn_base, is_premium=is_premium))
                new_ids.append(design_id)
                log.info("ok %s (%d)", design_id, len(new_ids))
            except Exception:  # noqa: BLE001
                log.exception("one design failed; continuing")

    db.set_meta("total", str(db.count()))
    export_full(db, cfg.exports_dir / "designs.json")
    export_update(
        db, cfg.exports_dir / "update.json", new_ids,
        owner=cfg.get("github", "owner", default=""),
        repo=cfg.get("github", "repo", default=""),
    )
    total = db.count()
    db.close()
    log.info("seed done: %d new, %d total", len(new_ids), total)
    return new_ids


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=40)
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--workers", type=int, default=10)
    a = ap.parse_args()
    run(a.count, a.seed, a.workers)
