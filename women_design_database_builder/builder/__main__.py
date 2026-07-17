"""CLI entry point.

Usage:
    python -m builder --count 2            # daily incremental run
    python -m builder --count 30 --seed 7  # reproducible seed batch
    python -m builder --stats              # print DB stats
"""
from __future__ import annotations

import argparse
import json
import logging
import sys

from .config import Config
from .pipeline import run


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    parser = argparse.ArgumentParser(prog="builder", description="Shringar Studio database builder")
    parser.add_argument("--count", type=int, default=None, help="number of images to generate")
    parser.add_argument("--per-category", type=int, default=None,
                        help="generate this many images for EVERY category (overrides --count)")
    parser.add_argument("--seed", type=int, default=None, help="RNG seed for reproducibility")
    parser.add_argument("--stats", action="store_true", help="print database stats and exit")
    args = parser.parse_args(argv)

    cfg = Config.load()

    if args.stats:
        from .database import DesignDatabase

        db = DesignDatabase(cfg.db_path)
        stats = {
            "total": db.count(),
            "by_category": {
                r["category"]: r["n"]
                for r in db.conn.execute(
                    "SELECT category, COUNT(*) n FROM designs GROUP BY category ORDER BY n DESC"
                )
            },
        }
        print(json.dumps(stats, indent=2))
        db.close()
        return 0

    count = args.count or cfg.get("generation", "daily_count", default=2)
    new_ids = run(count, cfg, seed=args.seed, per_category=args.per_category)
    print(json.dumps({"new": new_ids}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
