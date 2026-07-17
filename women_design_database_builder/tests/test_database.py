import datetime as dt
import pathlib
import random

from builder.database import DesignDatabase
from builder.metadata import DesignRecord
from builder.prompt_engine.engine import PromptEngine


def _record(i: int) -> DesignRecord:
    ts = dt.datetime(2026, 1, 1, tzinfo=dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return DesignRecord(
        id=f"id{i:04d}",
        title=f"Royal Bridal Mehndi {i}",
        description="A royal arabic bridal mehndi design featuring dense vine pattern.",
        category="mehndi",
        subcategory="Bridal",
        tags=["mehndi", "bridal", "royal", "arabic"],
        festival="Diwali" if i % 2 == 0 else None,
        difficulty="hard",
        style="royal arabic",
        colors=["#5a1f0a", "#c58b52"],
        dominant_color="#5a1f0a",
        orientation="portrait",
        width=1024,
        height=1536,
        hash=f"{i:064d}",
        phash=f"{i:016x}",
        image_url=f"https://cdn.example/img{i}.webp",
        thumbnail_url=f"https://cdn.example/th{i}.webp",
        created_at=ts,
        updated_at=ts,
        is_premium=i % 5 == 0,
        prompt_fingerprint=f"fp{i}",
    )


def _db(tmp_path: pathlib.Path) -> DesignDatabase:
    db = DesignDatabase(tmp_path / "t.db")
    for i in range(10):
        db.insert(_record(i))
    return db


def test_insert_and_count(tmp_path):
    db = _db(tmp_path)
    assert db.count() == 10


def test_fts_search(tmp_path):
    db = _db(tmp_path)
    assert len(db.search("mehndi")) == 10
    assert len(db.search("bridal AND royal")) == 10
    assert db.search("nonexistentterm") == []


def test_festival_search(tmp_path):
    db = _db(tmp_path)
    assert len(db.search("festival:Diwali")) == 5


def test_fingerprints_and_hashes(tmp_path):
    db = _db(tmp_path)
    assert len(db.fingerprints()) == 10
    assert len(db.hashes_and_phashes()) == 10


def test_upsert_categories(tmp_path):
    db = _db(tmp_path)
    engine = PromptEngine(random.Random(0))
    db.upsert_categories(engine.categories)
    n = db.conn.execute("SELECT COUNT(*) FROM categories").fetchone()[0]
    assert n == len(engine.categories) >= 47


def test_reinsert_replaces_not_duplicates(tmp_path):
    db = _db(tmp_path)
    db.insert(_record(3))
    assert db.count() == 10
    assert len(db.search("mehndi")) == 10
