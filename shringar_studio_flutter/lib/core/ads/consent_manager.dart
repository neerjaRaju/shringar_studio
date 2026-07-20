import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// GDPR / Google UMP (User Messaging Platform) consent.
///
/// AdMob policy requires a consent mechanism for users in the EEA/UK before
/// serving personalised ads. This gathers consent via the UMP SDK and only
/// then allows ad requests. Outside consent regions it's a no-op.
class ConsentManager {
  ConsentManager._();
  static final ConsentManager instance = ConsentManager._();

  /// Gathers consent (shows the form if required). Safe to call on startup.
  Future<void> gatherConsent() async {
    // For EEA form testing on a debug device, pass a ConsentDebugSettings here.
    final params = ConsentRequestParameters();

    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await _loadAndShowFormIfRequired();
          }
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        // On failure, proceed — non-personalised ads can still serve.
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  Future<void> _loadAndShowFormIfRequired() async {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  /// True once we're allowed to request ads (consent obtained or not required).
  Future<bool> canRequestAds() =>
      ConsentInformation.instance.canRequestAds();

  /// Whether to show a "Privacy options" entry (required if the user can
  /// change consent — e.g. an EEA user). Surface this in Settings.
  Future<bool> isPrivacyOptionsRequired() async =>
      (await ConsentInformation.instance.getPrivacyOptionsRequirementStatus()) ==
      PrivacyOptionsRequirementStatus.required;

  /// Re-open the consent form so users can change their choice.
  Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }
}
