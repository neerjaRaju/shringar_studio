"""End-to-end pipeline: prompts -> images -> processing -> dedup -> DB -> exports."""
from __future__ import annotations

import logging
import random

from .config import Config
from .database import DesignDatabase
from .dedup import DuplicateIndex
from .exporter import export_full, export_update
from .generation.provider import SIZE_BY_ORIENTATION, get_provider
from .metadata import build_record
from .prompt_engine.engine import PromptEngine

log = logging.getLogger("builder")


def run(
    count: int,
    cfg: Config | None = None,
    seed: int | None = None,
    per_category: int | None = None,
) -> list[str]:
    """Generate designs.

    * default: `count` designs across random categories.
    * `per_category=N`: N designs for EVERY category (count is ignored).
    """
    cfg = cfg or Config.load()
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
    dup_index = DuplicateIndex.from_rows(
        db.hashes_and_phashes(),
        threshold=cfg.get("dedup", "phash_hamming_threshold", default=6),
    )
    seen = db.fingerprints()

    sizes = cfg.get("generation", "sizes", default=[1024])
    premium_nth = cfg.get("premium", "every_nth", default=5)
    quality = cfg.get("processing", "quality", default=82)
    thumb_q = cfg.get("processing", "thumbnail_quality", default=75)
    thumb_sizes = tuple(cfg.get("processing", "thumbnail_sizes", default=[512, 256, 128]))

    new_ids: list[str] = []
    if per_category:
        specs = engine.generate_per_category(per_category, seen)
        log.info(
            "generating %d designs (%d per category x %d categories)",
            len(specs), per_category, len(engine.categories),
        )
    else:
        specs = engine.generate_batch(count, seen)
        log.info(
            "generating %d designs (space: %.2e combinations)",
            len(specs), engine.combination_space(),
        )

    from .processing.image_processor import process_image  # local import keeps CLI fast

    for i, spec in enumerate(specs, 1):
        try:
            edge = rng.choice(sizes)
            orientation = rng.choice(cfg.get("generation", "orientations", default=["square"]))
            width, height = SIZE_BY_ORIENTATION[orientation](edge)
            log.info("[%d/%d] %s | %dx%d", i, len(specs), spec.prompt[:110], width, height)

            raw = provider.generate(spec.prompt, width, height, spec.seed)

            from .metadata import make_id
            design_id = make_id(spec)
            processed = process_image(
                raw, design_id, cfg.images_dir, cfg.thumbs_dir,
                quality=quality, thumb_quality=thumb_q, thumb_sizes=thumb_sizes,
            )

            if dup_index.is_duplicate(processed.sha256, processed.phash):
                log.warning("duplicate detected, discarding %s", design_id)
                processed.image_path.unlink(missing_ok=True)
                for p in processed.thumbnail_paths.values():
                    p.unlink(missing_ok=True)
                continue

            dup_index.add(processed.sha256, processed.phash)
            is_premium = (db.count() + len(new_ids) + 1) % premium_nth == 0
            rec = build_record(spec, processed, cfg.cdn_base, is_premium=is_premium)
            db.insert(rec)
            new_ids.append(rec.id)
        except Exception:  # noqa: BLE001
            log.exception("design %d failed; continuing", i)

    db.set_meta("total", str(db.count()))
    export_full(db, cfg.exports_dir / "designs.json")
    export_update(
        db, cfg.exports_dir / "update.json", new_ids,
        owner=cfg.get("github", "owner", default=""),
        repo=cfg.get("github", "repo", default=""),
    )
    total = db.count()
    db.close()
    log.info("done: %d new, %d total", len(new_ids), total)
    return new_ids
