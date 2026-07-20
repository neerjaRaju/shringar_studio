# Play Store Release Checklist — Shringar Studio

Work top to bottom. Items marked ⚠️ **must** be done before a production release.

## 1. ⚠️ Replace AdMob test IDs with your real ones
Test IDs are Google's public ones — using them in production violates AdMob policy.
- `shringar_studio_flutter/lib/core/constants/app_constants.dart` → all `admob*` / `*AdUnitId` fields.
- `shringar_studio_flutter/android/app/src/main/AndroidManifest.xml` → the
  `com.google.android.gms.ads.APPLICATION_ID` meta-data value.
Create the ad units in your AdMob account (banner, interstitial, rewarded, native, app-open).

## 2. ⚠️ Enable GitHub Pages (makes the privacy-policy URL work)
Repo → Settings → Pages → Source: `Deploy from a branch` → Branch `main`, folder `/docs` → Save.
After ~1 min the policy is live at:
`https://neerjaRaju.github.io/shringar_studio/privacy_policy.html`
(This is the URL already wired into the app and the store listing.)

## 3. ⚠️ Create a release signing key
```bash
keytool -genkey -v -keystore ~/shringar-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```
Create `shringar_studio_flutter/android/key.properties` (already git-ignored):
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/shringar-upload.jks
```
Then wire it in `android/app/build.gradle.kts` — add before `android {`:
```kotlin
import java.util.Properties
import java.io.FileInputStream
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```
and inside `android { }`:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")   // replace the debug one
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

## 4. Set version and build the app bundle
- Bump `version:` in `shringar_studio_flutter/pubspec.yaml` (e.g. `1.0.0+1`).
```bash
cd shringar_studio_flutter
flutter pub get
flutter build appbundle --release        # produces build/app/outputs/bundle/release/app-release.aab
```
(You can also `flutter build apk --release --split-per-abi` for sideloading tests.)

## 5. Create the app in Play Console
- Play Console → Create app → name `Shringar Studio`, Free, App.
- **Store listing:** paste text + upload graphics from `STORE_LISTING.md` / `brand/play_store/`.
- **Privacy policy:** paste the Pages URL from step 2.
- **App content:**
  - Data safety → fill per `STORE_LISTING.md` (Advertising ID collected+shared for ads).
  - Content rating → complete questionnaire (comes out Everyone / PEGI 3).
  - Ads → "Contains ads: Yes".
  - Target audience → 18+ or 13+ (not child-directed).
  - News app → No.
- Upload the `.aab` to the **Internal testing** track first, add your email as a tester, install, verify ads + consent.
- Promote to Production when happy.

## 6. Pre-launch verification (already in code)
- ✅ UMP/GDPR consent gathered before ads (EEA) — `consent_manager.dart`.
- ✅ Family-safe request configuration (max content rating PG, not child-directed).
- ✅ `AD_ID` permission declared.
- ✅ App-open ad shown only on resume, never over cold-start splash.
- ✅ Interstitial rate-limited (every 6th detail view); premium unlock via rewarded only.
- ✅ Privacy policy linked in-app (Settings → Privacy Policy) + Ad privacy choices.

## 7. Nice-to-have before production
- Replace placeholder screenshots with real device captures.
- Add a short promo video (optional).
- Test on a physical device with a fresh install to confirm the consent form and ads render.
