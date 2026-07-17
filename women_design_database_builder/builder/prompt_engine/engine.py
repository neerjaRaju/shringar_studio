"""Dynamic prompt engine.

Never stores fixed prompts. Prompts are assembled at generation time from the
template:

    {STYLE} {CATEGORY} {PATTERN} {BODY_PART} {BACKGROUND}
    {LIGHTING} {CAMERA} {QUALITY} {COLOR} {EXTRA_DETAILS}

Component lists are expanded combinatorially (adjective x base) so the
effective vocabulary is:

    styles      30 adj x 40 base  = 1200+
    patterns    40 adj x 55 base  = 2200+
    colors      20 mod x 26 theme =  520+
    occasions   20 mod x 25 base  =  500+
    quality     24 x 24           =  576+
    fashion     30 adj x 34 base  = 1020+

Combined with categories, subcategories, backgrounds, lighting, camera angles,
body positions and festivals, the space exceeds 10^12 unique prompts.
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import random
from dataclasses import dataclass, field

COMPONENTS_DIR = pathlib.Path(__file__).resolve().parent / "components"

TEMPLATE = (
    "{STYLE} {CATEGORY}, {PATTERN} pattern, {BODY_PART}, {COLOR} color palette, "
    "{BACKGROUND}, {LIGHTING}, {CAMERA}, {EXTRA_DETAILS}, {QUALITY}"
)


@dataclass(frozen=True)
class PromptSpec:
    """A fully-resolved prompt plus the structured components that built it."""

    prompt: str
    category_id: str
    category_name: str
    subcategory: str
    style: str
    pattern: str
    body_part: str
    background: str
    lighting: str
    camera: str
    color_theme: str
    quality: str
    extra_details: str
    festival: str | None
    occasion: str | None
    seed: int
    tags: list[str] = field(default_factory=list)

    @property
    def fingerprint(self) -> str:
        """Stable hash of the semantic combination — used for dedup."""
        key = "|".join(
            [
                self.category_id,
                self.subcategory,
                self.style,
                self.pattern,
                self.body_part,
                self.color_theme,
                self.festival or "",
                self.occasion or "",
            ]
        ).lower()
        return hashlib.sha1(key.encode("utf-8")).hexdigest()


class PromptEngine:
    def __init__(self, rng: random.Random | None = None) -> None:
        self.rng = rng or random.Random()
        with open(COMPONENTS_DIR / "components.json", encoding="utf-8") as fh:
            self.c = json.load(fh)
        with open(COMPONENTS_DIR / "categories.json", encoding="utf-8") as fh:
            self.categories = json.load(fh)["categories"]

    # -- component expansion -------------------------------------------------
    def _style(self) -> str:
        return f"{self.rng.choice(self.c['style_adjectives'])} {self.rng.choice(self.c['style_bases'])}"

    def _pattern(self) -> str:
        return f"{self.rng.choice(self.c['pattern_adjectives'])} {self.rng.choice(self.c['pattern_bases'])}"

    def _color(self) -> str:
        return f"{self.rng.choice(self.c['color_modifiers'])} {self.rng.choice(self.c['color_themes'])}"

    def _occasion(self) -> str:
        return f"{self.rng.choice(self.c['occasion_modifiers'])} {self.rng.choice(self.c['occasion_bases'])}"

    def _quality(self) -> str:
        adjs = self.rng.sample(self.c["quality_adjectives"], 3)
        suffix = self.rng.choice(self.c["quality_suffixes"])
        return ", ".join(adjs + [suffix])

    def _fashion_detail(self) -> str:
        return f"{self.rng.choice(self.c['fashion_adjectives'])} {self.rng.choice(self.c['fashion_bases'])}"

    # -- public API -----------------------------------------------------------
    def combination_space(self) -> int:
        c = self.c
        n = (
            len(c["style_adjectives"]) * len(c["style_bases"])
            * len(c["pattern_adjectives"]) * len(c["pattern_bases"])
            * len(c["color_modifiers"]) * len(c["color_themes"])
            * len(c["backgrounds"]) * len(c["lighting"]) * len(c["camera_angles"])
        )
        subcats = sum(len(cat["subcategories"]) for cat in self.categories)
        return n * subcats

    def generate(self, category_id: str | None = None, festival: str | None = None) -> PromptSpec:
        cat = (
            next(c for c in self.categories if c["id"] == category_id)
            if category_id
            else self.rng.choice(self.categories)
        )
        subcategory = self.rng.choice(cat["subcategories"])
        style = self._style()
        pattern = self._pattern()
        body_part = self.rng.choice(cat["body_parts"])
        background = self.rng.choice(self.c["backgrounds"])
        lighting = self.rng.choice(self.c["lighting"])
        camera = self.rng.choice(self.c["camera_angles"])
        color_theme = self._color()
        quality = self._quality()
        position = self.rng.choice(self.c["body_positions"])

        fest = festival
        if fest is None and self.rng.random() < 0.35:
            fest = self.rng.choice(self.c["festivals"])
        occasion = self._occasion() if self.rng.random() < 0.5 else None

        extras = [position, self._fashion_detail()]
        if fest:
            extras.append(f"for {fest} festival")
        if occasion:
            extras.append(f"suitable for a {occasion}")
        extra_details = ", ".join(extras)

        subject = f"{subcategory} {cat['subject']}"
        prompt = TEMPLATE.format(
            STYLE=style,
            CATEGORY=subject,
            PATTERN=pattern,
            BODY_PART=body_part,
            BACKGROUND=background,
            LIGHTING=lighting,
            CAMERA=camera,
            QUALITY=quality,
            COLOR=color_theme,
            EXTRA_DETAILS=extra_details,
        )

        tags = sorted(
            {
                cat["name"].lower(),
                subcategory.lower(),
                *style.split(),
                *pattern.split()[:2],
                *(fest.lower().split() if fest else []),
            }
            - {"of", "and", "the", "a"}
        )

        return PromptSpec(
            prompt=prompt,
            category_id=cat["id"],
            category_name=cat["name"],
            subcategory=subcategory,
            style=style,
            pattern=pattern,
            body_part=body_part,
            background=background,
            lighting=lighting,
            camera=camera,
            color_theme=color_theme,
            quality=quality,
            extra_details=extra_details,
            festival=fest,
            occasion=occasion,
            seed=self.rng.randint(1, 2**31 - 1),
            tags=tags,
        )

    def generate_batch(self, count: int, seen_fingerprints: set[str]) -> list[PromptSpec]:
        """Generate `count` specs whose fingerprints are not in `seen_fingerprints`."""
        out: list[PromptSpec] = []
        attempts = 0
        while len(out) < count and attempts < count * 50:
            spec = self.generate()
            attempts += 1
            if spec.fingerprint in seen_fingerprints:
                continue
            seen_fingerprints.add(spec.fingerprint)
            out.append(spec)
        return out
