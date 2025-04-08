import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  int _messageCount = 0;
  static const int _adInterval = 10; // 10개 메시지마다 광고 표시

  String get _adUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-1120202923997022/4063774603'; // iOS용 광고 단위 ID
    } else {
      return 'ca-app-pub-1120202923997022/9124529597'; // Android용 광고 단위 ID
    }
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    debugPrint('Loading interstitial ad...');
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded successfully');
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load interstitial ad: ${error.message}');
          _interstitialAd = null;
          // 실패 시 재시도
          Future.delayed(const Duration(seconds: 1), _loadInterstitialAd);
        },
      ),
    );
  }

  void incrementMessageCount() {
    _messageCount++;
    debugPrint('Message count: $_messageCount');
    if (_messageCount >= _adInterval) {
      _showInterstitialAd();
      _messageCount = 0;
    }
  }

  void _showInterstitialAd() {
    debugPrint('Attempting to show interstitial ad...');
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Ad dismissed');
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Failed to show ad: ${error.message}');
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Ad showed successfully');
        },
      );
    } else {
      debugPrint('No ad available to show');
      _loadInterstitialAd();
    }
  }

  void showAdOnCharacterSelect() {
    debugPrint('Showing ad on character select');
    _showInterstitialAd();
  }
} 