# Shringar Studio

India's largest **offline** Women's Design Library — built to scale to 300,000+ designs with **zero monthly infrastructure cost**, hosted entirely on GitHub. Single repository containing both halves of the system:

| Folder | What it is |
| --- | --- |
| `women_design_database_builder/` | Python pipeline: dynamic prompt engine → free image generation (Pollinations) → WebP + thumbnails → SQLite (FTS5) → daily GitHub Action that publishes `shringar.db` + `update.json` as Releases. |
| `shringar_studio_flutter/` | Android Flutter app (Material 3, Riverpod, GoRouter, offline SQLite, AdMob). Ships a seed database and pulls incremental updates from this repo's Releases. |

## How the zero-cost backend works

The daily Action (`.github/workflows/daily-build.yml`) generates 2 new designs, commits them under `women_design_database_builder/data/`, and attaches `shringar.db` + `update.json` to a **GitHub Release** on this repo. The app checks `github.com/neerjaRaju/shringar_studio/releases/latest`, and images are served free via jsDelivr from `cdn.jsdelivr.net/gh/neerjaRaju/shringar_studio@main/women_design_database_builder/data/images/…`. No backend, no Firebase, no monthly cost.

## Upload to GitHub

The repo is already `git init`-ed and committed with `origin` set to
`https://github.com/neerjaRaju/shringar_studio.git`. To push:

```bash
cd ~/Downloads/shringar_studio
git push -u origin main
```

You'll be asked to authenticate (browser or Personal Access Token). If the
GitHub repo doesn't exist yet, create an empty one named `shringar_studio`
under `neerjaRaju` first (no README/gitignore), then push.

Prefer the CLI? `bash push_to_github.sh` creates the repo (via `gh`) and pushes.

## After pushing

1. **Actions** → enable workflows. Run *Daily Database Build → Run workflow* once to publish the first Release.
2. **App** → `cd shringar_studio_flutter && flutter pub get`, then `flutter build apk --release --split-per-abi`. Tag `app-v1.0.0` to have CI attach APKs to a release.
3. Before publishing the app: replace the AdMob **test** IDs (`shringar_studio_flutter/lib/core/constants/app_constants.dart` + `AndroidManifest.xml`) with your real ones, and add a release signing key.

## Workflows (run from repo root, scoped to each subfolder)

- `.github/workflows/daily-build.yml` — daily data build + Release.
- `.github/workflows/flutter-ci.yml` — format, analyze, test, build split-ABI APKs.

## Current seed

10 real designs across 9 categories are already generated and committed (images, 512/256/128 thumbnails, SQLite DB, `designs.json`, `update.json`). The database also ships inside the app at `shringar_studio_flutter/assets/db/shringar.db`. Everything grows automatically from there.
