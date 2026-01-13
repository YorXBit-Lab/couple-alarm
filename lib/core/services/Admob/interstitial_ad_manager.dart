import 'package:couple_note/core/services/Admob/ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  bool get isAdLoaded => _isAdLoaded;

  void loadAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _numInterstitialLoadAttempts = 0;

          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          _isAdLoaded = false;

          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            Future.delayed(Duration(seconds: 2), () {
              loadAd();
            });
          }
        },
      ),
    );
  }

  void showAd({Function? onAdDismissed}) {
    if (_interstitialAd == null) {
      loadAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        print('📱 Interstitial ad showed fullscreen content');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('👋 Interstitial ad dismissed');
        ad.dispose();
        _isAdLoaded = false;

        if (onAdDismissed != null) {
          onAdDismissed();
        }

        // Load quảng cáo mới cho lần sau
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _isAdLoaded = false;

        loadAd();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _isAdLoaded = false;
  }
}
