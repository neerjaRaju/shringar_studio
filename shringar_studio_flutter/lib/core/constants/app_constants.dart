/// App-wide constants. Update the GitHub owner once here if the org changes.
abstract final class AppConstants {

  static const appName = 'Shringar Studio';
  static const githubOwner = 'neerjaRaju';
  static const dataRepo = 'shringar_studio';
  static const updateJsonUrl = 'https://github.com/$githubOwner/$dataRepo/releases/latest/download/update.json';
  static const dbDownloadUrl = 'https://github.com/$githubOwner/$dataRepo/releases/latest/download/shringar.db';
  static const assetDbPath = 'assets/db/shringar.db';
  static const dbFileName = 'shringar.db';

  // Privacy policy (GitHub Pages — enable Pages on the repo, /docs folder).
  static const privacyPolicyUrl =
      'https://$githubOwner.github.io/shringar_studio/privacy_policy.html';
  static const supportEmail = 'satish@zrix.com';

  // ---- Paging ----
  static const pageSize = 30;

  // ---- AdMob (Google test IDs — replace with real IDs before release) ----
  static const admobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  static const appOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';

  /// Interstitial shown once per this many detail views.
  static const interstitialFrequency = 6;
}
