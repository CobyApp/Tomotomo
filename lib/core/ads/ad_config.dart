import 'dart:io';

import 'package:flutter/foundation.dart';

/// Rewarded-ad economy and unit ids.
///
/// The real ids arrive as compile-time `--dart-define` values from CI, not from a
/// bundled `.env`. An asset ships inside the app and is trivially extractable
/// from an IPA or AAB, so it is the wrong place for anything that is meant to be
/// configuration — and the previous `.env` template still documented Gemini and
/// Supabase keys the app has not used since it went fully on-device, one paste
/// away from publishing a real key.
///
/// Falling back to Google's public test unit ids keeps development working with
/// no AdMob account. In a release build that fallback means real ads never
/// serve, so [usingTestAdUnits] reports it instead of failing silently.
class AdConfig {
  static const int pointsPerAd = 50;
  static const int maxAdsPerDay = 5;

  /// Google-provided public rewarded TEST unit ids.
  static const String _testAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testIos = 'ca-app-pub-3940256099942544/1712485313';

  static const String _definedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
  );
  static const String _definedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
  );

  static String get _defined => Platform.isIOS ? _definedIos : _definedAndroid;

  static String get rewardedUnitId {
    if (kDebugMode || _defined.isEmpty) {
      return Platform.isIOS ? _testIos : _testAndroid;
    }
    return _defined;
  }

  /// True when the app is serving Google's test ads, which earn nothing. Expected
  /// in debug; in a release build it means the `--dart-define` was not passed.
  static bool get usingTestAdUnits => kDebugMode || _defined.isEmpty;
}
