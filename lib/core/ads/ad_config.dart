import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Rewarded-ad economy + unit ids. Uses Google public TEST ids in debug so
/// development needs no AdMob account; real ids come from env in release.
class AdConfig {
  static const int pointsPerAd = 50;
  static const int maxAdsPerDay = 5;

  // Google-provided public rewarded test unit ids.
  static const String _testAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testIos = 'ca-app-pub-3940256099942544/1712485313';

  static String get rewardedUnitId {
    if (kDebugMode) return Platform.isIOS ? _testIos : _testAndroid;
    final key = Platform.isIOS ? 'ADMOB_REWARDED_IOS' : 'ADMOB_REWARDED_ANDROID';
    final v = dotenv.isInitialized ? dotenv.env[key] : null;
    return (v == null || v.isEmpty) ? (Platform.isIOS ? _testIos : _testAndroid) : v;
  }
}
