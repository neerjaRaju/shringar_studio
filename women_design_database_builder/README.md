# women_design_database_builder

Automatic database builder for **Shringar Studio** — India's largest offline Women's Design Library (target 300,000+ designs across 47 categories: Mehndi, Blouse, Rangoli, Hairstyles, Makeup, Nail Art, Jewellery, festivals, decorations and more).

Zero infrastructure cost: images are generated with the free keyless [Pollinations](https://pollinations.ai) API, stored in this repo, served via jsDelivr CDN, and the SQLite database ships through GitHub Releases.

## How it works

```
PromptEngine ──> ImageProvider ──> ImageProcessor ──> DuplicateIndex ──> SQLite (FTS5) ──> exports
 (dynamic         (Pollinations,     (WebP, thumbs      (sha256 +          designs +        designs.json
  templates,       pluggable)         512/256/128,       dHash)            categories +     update.json
  10^12 combos)                       colors, hashes)                      FTS5 index
```

1. **Prompt engine** — no fixed prompts. The template `{STYLE} {CATEGORY} {PATTERN} {BODY_PART} {BACKGROUND} {LIGHTING} {CAMERA} {QUALITY} {COLOR} {EXTRA_DETAILS}` is filled from combinatorially-expanded component lists (1200+ styles, 2200+ patterns, 520+ color themes, 500+ occasions, 576+ quality modifiers, 1020+ fashion details, plus backgrounds, lighting, camera angles, body positions and 30 festivals). Semantic fingerprints prevent regenerating the same combination.
2. **Image generation** — pluggable providers (`pollinations` default, `huggingface` optional via `HF_TOKEN`). Sizes 1024/1536/2048 in square, portrait and landscape.
3. **Processing** — WebP conversion + compression, 512/256/128 thumbnails, sha256, perceptual dHash, dominant color + 5-color palette, orientation, dimensions.
4. **Dedup** — exact (sha256) and near-duplicate (Hamming distance on dHash) detection; duplicates are discarded.
5. **SQLite** — `designs` table with full metadata, `categories`, and a `designs_fts` FTS5 index (porter + unicode61) for tag/category/festival/color search.
6. **Exports** — `designs.json` (full) and `update.json` (incremental manifest consumed by the app).

## Daily automation

`.github/workflows/daily-build.yml` runs every day at 02:30 UTC:
tests → generate **2** new images → compress → thumbnails → metadata → SQLite → update.json → commit → push → GitHub Release with `shringar.db` + `update.json`.

Trigger manually with a custom count: *Actions → Daily Database Build → Run workflow*.

## Usage

```bash
pip install -r requirements.txt
python -m builder --count 2        # generate 2 designs
python -m builder --count 30 --seed 7
python -m builder --stats          # database stats
pytest tests/ -q
```

## Layout

```
builder/
  prompt_engine/    engine + component JSON database
  generation/       provider abstraction (pollinations, huggingface)
  processing/       WebP, thumbnails, hashes, colors
  dedup.py          sha256 + perceptual-hash duplicate index
  metadata.py       title/description/difficulty/tags/premium
  database.py       SQLite + FTS5
  exporter.py       designs.json / update.json
  pipeline.py       orchestrator
data/
  images/           full-size WebP (served via jsDelivr)
  thumbnails/       512/ 256/ 128/
  db/shringar.db    SQLite database (also attached to releases)
  exports/          designs.json, update.json
```

## Configuration

Edit `config.yaml` — GitHub owner/repo/CDN base, provider, daily count, sizes, compression quality, dedup threshold, premium ratio (every 5th design is premium, unlocked in-app via rewarded ads).

## Setup

1. Create the GitHub repo `neerjaRaju/women_design_database_builder` and push this folder.
2. Actions are enabled by default; the workflow needs no secrets for Pollinations. For Hugging Face set repo secret `HF_TOKEN` and `generation.provider: huggingface`.
3. The companion app repo is [`shringar_studio_flutter`](https://github.com/neerjaRaju/shringar_studio_flutter).

## Scaling note

jsDelivr caps repos at ~150 MB per tag path; once `data/images` grows past a few GB, shard images into yearly repos (e.g. `women_design_images_2027`) and update `cdn_base` — the schema already stores absolute URLs per design, so old rows keep working.
