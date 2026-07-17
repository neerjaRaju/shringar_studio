# Shringar Studio (Flutter)

India's largest **offline** Women's Design Library — Mehndi, Blouse, Rangoli, Hairstyles, Makeup, Jewellery, festival & wedding decoration and 40+ more categories (target 300,000+ designs).

Zero infrastructure cost: the app ships with a seed SQLite database, streams images from a jsDelivr CDN, and pulls incremental updates from **GitHub Releases** of the companion [`women_design_database_builder`](https://github.com/neerjaRaju/women_design_database_builder) repo. No backend, no Firebase, no subscriptions.

## Stack

Flutter (Material 3) · Riverpod (DI + state) · GoRouter · sqflite (FTS5 search) · cached_network_image · photo_view · dynamic_color (Material You) · google_mobile_ads.

## Architecture (Clean Architecture + Repository pattern)

```
lib/
  core/
    constants/     app + AdMob + GitHub URLs
    database/      AppDatabase (asset seed + user data + hot-swap updater)
    network/       UpdateService (GitHub Releases incremental updater)
    theme/         Material 3 + Material You theme
    ads/           AdManager (banner/interstitial/rewarded/native/app-open)
  domain/          entities + repository interfaces (pure Dart)
  data/
    sources/       LocalDesignSource (SQL/FTS5), UserDataSource
    repositories/  DesignRepositoryImpl
  presentation/
    providers/     Riverpod graph (core, design, user, settings)
    router/        GoRouter
    screens/       home, categories, search, detail, favorites,
                   downloads, collections, premium, settings, slideshow
    widgets/       design card/grid, banner ad, empty state
```

Dependencies flow inward: `presentation → domain ← data`. Everything is null-safe; the domain layer has no Flutter imports (SOLID / dependency inversion).

## Features

Home (Design of the Day, Trending/Newest/Recently-Added carousels, festival chips, quick actions) · FTS5 search with voice input and category/festival/color filters · detail page with pinch-zoom, share, download, set-wallpaper, favorite, color palette, tags and related designs · favorites · offline downloads · collections/albums · recently & most viewed · dark/light/system themes with Material You dynamic colors · slideshow/wallpaper mode · random design · premium section unlocked per-design via rewarded ads.

Performance: infinite-scroll masonry grid, pagination, memory + disk image cache, shimmer placeholders, DB indexes and FTS5.

## Monetization

AdMob banner, interstitial (every 6th detail view), rewarded (premium unlock), native and app-open. Premium content is unlocked **only** by watching a rewarded ad — there are no subscriptions. The IDs in `lib/core/constants/app_constants.dart` and `AndroidManifest.xml` are Google's **test** IDs; replace them before release.

## Incremental updates

`UpdateService` fetches `update.json` from the builder repo's latest release. If the version differs from the stored one, it downloads the new `shringar.db` (validated by SQLite header), hot-swaps it into place, and records the version. New images resolve lazily via the CDN URLs already stored in each row, so no bulk image download is needed. Fully offline-tolerant — a failed check leaves the local DB untouched.

## Getting started

```bash
flutter pub get
flutter run                     # debug
flutter test                    # unit + widget tests
flutter build apk --release --split-per-abi
```

The seed database lives at `assets/db/shringar.db` and is copied to app storage on first launch. Regenerate/extend it from the builder repo (`python -m builder --count N`) and drop the new `shringar.db` here.

Before publishing:
1. Set your real AdMob app ID + ad unit IDs.
2. Configure a release signing key in `android/app/build.gradle`.
3. Confirm `AppConstants.githubOwner` points at your data repo.

## Testing

`test/design_entity_test.dart` covers entity parsing/serialization; `test/repository_test.dart` exercises the repository and FTS5 queries against an in-memory database mirroring the builder schema. CI (`.github/workflows/flutter-ci.yml`) runs format, analyze, test, and builds split-ABI release APKs, attaching them to tagged releases.
