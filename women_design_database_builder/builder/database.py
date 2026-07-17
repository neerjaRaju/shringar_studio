"""SQLite database with FTS5 full-text search."""
from __future__ import annotations

import json
import pathlib
import sqlite3

from .metadata import DesignRecord

SCHEMA = """
PRAGMA journal_mode = WAL;
PRAGMA user_version = 1;

CREATE TABLE IF NOT EXISTS designs (
    id              TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    category        TEXT NOT NULL,
    subcategory     TEXT NOT NULL,
    tags            TEXT NOT NULL,            -- JSON array
    festival        TEXT,
    difficulty      TEXT NOT NULL,
    style           TEXT NOT NULL,
    colors          TEXT NOT NULL,            -- JSON array of hex
    dominant_color  TEXT NOT NULL,
    orientation     TEXT NOT NULL,
    width           INTEGER NOT NULL,
    height          INTEGER NOT NULL,
    hash            TEXT NOT NULL UNIQUE,
    phash           TEXT NOT NULL,
    image_url       TEXT NOT NULL,
    thumbnail_url   TEXT NOT NULL,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    is_premium      INTEGER NOT NULL DEFAULT 0,
    language        TEXT NOT NULL DEFAULT 'en',
    prompt_fingerprint TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_designs_category   ON designs(category);
CREATE INDEX IF NOT EXISTS idx_designs_festival   ON designs(festival);
CREATE INDEX IF NOT EXISTS idx_designs_created    ON designs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_designs_premium    ON designs(is_premium);
CREATE INDEX IF NOT EXISTS idx_designs_dominant   ON designs(dominant_color);
CREATE INDEX IF NOT EXISTS idx_designs_fingerprint ON designs(prompt_fingerprint);

CREATE TABLE IF NOT EXISTS categories (
    id            TEXT PRIMARY KEY,
    name          TEXT NOT NULL,
    subcategories TEXT NOT NULL               -- JSON array
);

CREATE VIRTUAL TABLE IF NOT EXISTS designs_fts USING fts5(
    id UNINDEXED,
    title, description, category, subcategory, tags, festival, style,
    tokenize='porter unicode61'
);

CREATE TABLE IF NOT EXISTS meta (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
"""


class DesignDatabase:
    def __init__(self, path: pathlib.Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        self.conn = sqlite3.connect(path)
        self.conn.row_factory = sqlite3.Row
        self.conn.executescript(SCHEMA)

    # -- writes ---------------------------------------------------------------
    def upsert_categories(self, categories: list[dict]) -> None:
        self.conn.executemany(
            "INSERT OR REPLACE INTO categories (id, name, subcategories) VALUES (?,?,?)",
            [(c["id"], c["name"], json.dumps(c["subcategories"])) for c in categories],
        )
        self.conn.commit()

    def insert(self, rec: DesignRecord) -> None:
        d = rec.to_dict()
        self.conn.execute(
            """INSERT OR REPLACE INTO designs
               (id,title,description,category,subcategory,tags,festival,difficulty,style,
                colors,dominant_color,orientation,width,height,hash,phash,image_url,
                thumbnail_url,created_at,updated_at,is_premium,language,prompt_fingerprint)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                d["id"], d["title"], d["description"], d["category"], d["subcategory"],
                json.dumps(d["tags"]), d["festival"], d["difficulty"], d["style"],
                json.dumps(d["colors"]), d["dominant_color"], d["orientation"],
                d["width"], d["height"], d["hash"], d["phash"], d["image_url"],
                d["thumbnail_url"], d["created_at"], d["updated_at"], d["is_premium"],
                d["language"], d["prompt_fingerprint"],
            ),
        )
        self.conn.execute("DELETE FROM designs_fts WHERE id = ?", (d["id"],))
        self.conn.execute(
            """INSERT INTO designs_fts
               (id,title,description,category,subcategory,tags,festival,style)
               VALUES (?,?,?,?,?,?,?,?)""",
            (
                d["id"], d["title"], d["description"], d["category"], d["subcategory"],
                " ".join(d["tags"]), d["festival"] or "", d["style"],
            ),
        )
        self.conn.commit()

    def set_meta(self, key: str, value: str) -> None:
        self.conn.execute("INSERT OR REPLACE INTO meta (key,value) VALUES (?,?)", (key, value))
        self.conn.commit()

    # -- reads ----------------------------------------------------------------
    def count(self) -> int:
        return self.conn.execute("SELECT COUNT(*) FROM designs").fetchone()[0]

    def hashes_and_phashes(self) -> list[tuple[str, str]]:
        return [(r["hash"], r["phash"]) for r in self.conn.execute("SELECT hash, phash FROM designs")]

    def fingerprints(self) -> set[str]:
        return {r["prompt_fingerprint"] for r in self.conn.execute("SELECT prompt_fingerprint FROM designs")}

    def all_records(self) -> list[dict]:
        rows = self.conn.execute("SELECT * FROM designs ORDER BY created_at DESC").fetchall()
        out = []
        for r in rows:
            d = dict(r)
            d["tags"] = json.loads(d["tags"])
            d["colors"] = json.loads(d["colors"])
            out.append(d)
        return out

    def search(self, query: str, limit: int = 50) -> list[dict]:
        rows = self.conn.execute(
            """SELECT d.* FROM designs_fts f JOIN designs d ON d.id = f.id
               WHERE designs_fts MATCH ? ORDER BY rank LIMIT ?""",
            (query, limit),
        ).fetchall()
        return [dict(r) for r in rows]

    def close(self) -> None:
        self.conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        self.conn.close()
