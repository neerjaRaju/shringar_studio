import random

from builder.prompt_engine.engine import PromptEngine


def engine(seed: int = 42) -> PromptEngine:
    return PromptEngine(random.Random(seed))


def test_combination_space_exceeds_millions():
    assert engine().combination_space() > 1_000_000_000


def test_generate_fills_all_template_slots():
    spec = engine().generate()
    assert spec.prompt
    for part in (spec.style, spec.pattern, spec.body_part, spec.background,
                 spec.lighting, spec.camera, spec.color_theme):
        assert part in spec.prompt


def test_category_targeting():
    spec = engine().generate(category_id="mehndi")
    assert spec.category_id == "mehndi"
    assert "mehndi" in spec.prompt.lower()


def test_fingerprint_stable_and_seed_independent():
    e1, e2 = engine(1), engine(1)
    s1, s2 = e1.generate(), e2.generate()
    assert s1.fingerprint == s2.fingerprint


def test_batch_dedup():
    seen: set[str] = set()
    specs = engine().generate_batch(50, seen)
    fps = [s.fingerprint for s in specs]
    assert len(fps) == len(set(fps)) == 50
    assert seen.issuperset(fps)


def test_tags_nonempty_and_lowercase():
    spec = engine().generate()
    assert spec.tags
    assert all(t == t.lower() for t in spec.tags)


def test_generate_per_category_one_each():
    e = engine()
    seen: set[str] = set()
    specs = e.generate_per_category(1, seen)
    assert len(specs) == len(e.categories)
    covered = {s.category_id for s in specs}
    assert covered == {c["id"] for c in e.categories}
    # all unique fingerprints
    assert len({s.fingerprint for s in specs}) == len(specs)


def test_generate_per_category_multiple():
    e = engine()
    seen: set[str] = set()
    specs = e.generate_per_category(3, seen)
    assert len(specs) == 3 * len(e.categories)
    from collections import Counter
    counts = Counter(s.category_id for s in specs)
    assert all(n == 3 for n in counts.values())


def test_component_counts_meet_spec():
    c = engine().c
    assert len(c["style_adjectives"]) * len(c["style_bases"]) >= 1000
    assert len(c["pattern_adjectives"]) * len(c["pattern_bases"]) >= 2000
    assert len(c["color_modifiers"]) * len(c["color_themes"]) >= 500
    assert len(c["occasion_modifiers"]) * len(c["occasion_bases"]) >= 500
    assert len(c["quality_adjectives"]) * len(c["quality_suffixes"]) >= 500
    assert len(c["fashion_adjectives"]) * len(c["fashion_bases"]) >= 1000
