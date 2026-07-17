import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_constants.dart';

/// Central AdMob controller: banner, interstitial, rewarded, native, app-open.
/// Premium content is unlocked ONLY through rewarded ads (no subscriptions).
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  AppOpenAd? _appOpen;
  int _detailViews = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitial();
    _loadRewarded();
    _loadAppOpen();
  }

  // ---- Banner ----------------------------------------------------------------
  BannerAd createBanner({
    AdSize size = AdSize.banner,
    BannerAdListener? listener,
  }) =>
      BannerAd(
        size: size,
        adUnitId: AppConstants.bannerAdUnitId,
        listener: listener ?? const BannerAdListener(),
        request: const AdRequest(),
      )..load();

  // ---- Interstitial ----------------------------------------------------------
  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Show an interstitial roughly once every N detail views.
  void maybeShowInterstitial() {
    _detailViews++;
    if (_detailViews % AppConstants.interstitialFrequency != 0) return;
    final ad = _interstitial;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
    _interstitial = null;
  }

  // ---- Rewarded (premium unlock) ---------------------------------------------
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// Returns true if the user earned the reward (unlocks the premium design).
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      if (kDebugMode) return true; // allow testing without a loaded ad
      return false;
    }
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    _rewarded = null;
    return completer.future;
  }

  // ---- App-open --------------------------------------------------------------
  void _loadAppOpen() {
    AppOpenAd.load(
      adUnitId: AppConstants.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpen = ad,
        onAdFailedToLoad: (_) => _appOpen = null,
      ),
    );
  }

  void showAppOpenIfAvailable() {
    final ad = _appOpen;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadAppOpen();
      },
    );
    ad.show();
    _appOpen = null;
  }
}
