"""Design metadata assembly."""
from __future__ import annotations

import datetime as dt
import hashlib
from dataclasses import asdict, dataclass, field

from .prompt_engine.engine import PromptSpec
from .processing.image_processor import ProcessedImage

DIFFICULTIES = ["easy", "medium", "hard", "expert"]


def make_id(spec: PromptSpec) -> str:
    return hashlib.sha1(f"{spec.fingerprint}:{spec.seed}".encode()).hexdigest()[:16]


def make_title(spec: PromptSpec) -> str:
    style_word = spec.style.split()[0].title()
    title = f"{style_word} {spec.subcategory} {spec.category_name}"
    if spec.festival:
        title += f" for {spec.festival}"
    return title


def make_description(spec: PromptSpec) -> str:
    parts = [
        f"A {spec.style} {spec.subcategory.lower()} {spec.category_name.lower()} design",
        f"featuring a {spec.pattern} pattern in {spec.color_theme} tones",
    ]
    if spec.festival:
        parts.append(f"perfect for {spec.festival}")
    if spec.occasion:
        parts.append(f"and ideal for a {spec.occasion}")
    return ", ".join(parts) + "."


def difficulty_for(spec: PromptSpec) -> str:
    dense = any(w in spec.pattern for w in ("dense", "layered", "interlocking", "filigree"))
    royal = any(w in spec.style for w in ("royal", "intricate", "ornate", "luxurious"))
    if dense and royal:
        return "expert"
    if dense or royal:
        return "hard"
    if any(w in spec.style for w in ("simple", "minimal", "subtle")):
        return "easy"
    return "medium"


@dataclass
class DesignRecord:
    id: str
    title: str
    description: str
    category: str
    subcategory: str
    tags: list[str]
    festival: str | None
    difficulty: str
    style: str
    colors: list[str]
    dominant_color: str
    orientation: str
    width: int
    height: int
    hash: str
    phash: str
    image_url: str
    thumbnail_url: str
    created_at: str
    updated_at: str
    is_premium: int
    language: str = "en"
    prompt_fingerprint: str = ""
    extra: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        return asdict(self)


def build_record(
    spec: PromptSpec,
    processed: ProcessedImage,
    cdn_base: str,
    *,
    is_premium: bool,
    now: dt.datetime | None = None,
) -> DesignRecord:
    ts = (now or dt.datetime.now(dt.timezone.utc)).strftime("%Y-%m-%dT%H:%M:%SZ")
    design_id = processed.image_path.stem
    return DesignRecord(
        id=design_id,
        title=make_title(spec),
        description=make_description(spec),
        category=spec.category_id,
        subcategory=spec.subcategory,
        tags=spec.tags,
        festival=spec.festival,
        difficulty=difficulty_for(spec),
        style=spec.style,
        colors=processed.colors,
        dominant_color=processed.dominant_color,
        orientation=processed.orientation,
        width=processed.width,
        height=processed.height,
        hash=processed.sha256,
        phash=processed.phash,
        image_url=f"{cdn_base}/data/images/{design_id}.webp",
        thumbnail_url=f"{cdn_base}/data/thumbnails/512/{design_id}.webp",
        created_at=ts,
        updated_at=ts,
        is_premium=1 if is_premium else 0,
        prompt_fingerprint=spec.fingerprint,
    )
