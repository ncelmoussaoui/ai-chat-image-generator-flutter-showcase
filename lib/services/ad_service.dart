import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/constants.dart';

/// Service to handle Google Mobile Ads (AdMob)
class AdService {
  AdService._();

  static bool _showAds = true; // Can be toggled for premium users
  static InterstitialAd? _interstitialAd;
  static int _interstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  /// Banner Ad Unit IDs (Fetched from AppConstants)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return AppConstants.androidBannerAdId;
    } else if (Platform.isIOS) {
      return AppConstants.iosBannerAdId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Interstitial Ad Unit IDs (Fetched from AppConstants)
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return AppConstants.androidInterstitialAdId;
    } else if (Platform.isIOS) {
      return AppConstants.iosInterstitialAdId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Initialize AdMob
  static Future<void> init() async {
    if (!_showAds) return;
    await MobileAds.instance.initialize();
    loadInterstitialAd();
  }

  /// Load Interstitial Ad
  static void loadInterstitialAd() {
    if (!_showAds) return;
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  /// Show Interstitial Ad if loaded
  static void showInterstitialAd() {
    if (!_showAds || _interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd(); // Load next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  /// Toggle ads (e.g., for in-app purchases)
  static void setAdsEnabled(bool enabled) {
    _showAds = enabled;
  }

  static bool get adsEnabled => _showAds;
}
