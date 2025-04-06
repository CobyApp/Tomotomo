import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  int _messageCount = 0;
  static const int _adInterval = 5; // 5개 메시지마다 광고 표시

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
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void incrementMessageCount() {
    _messageCount++;
    if (_messageCount >= _adInterval) {
      _showInterstitialAd();
      _messageCount = 0;
    }
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );
    }
  }

  void showAdOnCharacterSelect() {
    _showInterstitialAd();
  }
} 