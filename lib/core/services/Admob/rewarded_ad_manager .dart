import 'dart:async';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:couple_note/core/services/Admob/ad_helper.dart';

class RewardedAdManager {
  RewardedAdManager._internal();
  static final RewardedAdManager _instance = RewardedAdManager._internal();
  factory RewardedAdManager() => _instance;

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  int _numRewardedLoadAttempts = 0;

  static const int maxFailedLoadAttempts = 3;

  bool get isAdLoaded => _isAdLoaded;

  void loadAd() {
    if (_isAdLoaded || _rewardedAd != null) return;

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('✅ Rewarded ad loaded');
          _rewardedAd = ad;
          _isAdLoaded = true;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('❌ Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isAdLoaded = false;
          _numRewardedLoadAttempts++;

          if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
            Future.delayed(const Duration(seconds: 2), loadAd);
          }
        },
      ),
    );
  }

  void showAd({
    required FutureOr<void> Function() onUserEarnedReward,
    VoidCallback? onAdDismissed,
  }) {
    if (_rewardedAd == null) {
      print('⚠️ Rewarded ad not ready, reloading...');
      loadAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('📱 Rewarded ad showed fullscreen');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('👋 Rewarded ad dismissed');
        ad.dispose();
        _reset();

        onAdDismissed?.call();
        loadAd(); // preload lần sau
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Failed to show rewarded ad: $error');
        ad.dispose();
        _reset();
        loadAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        print('🎁 User earned reward: ${reward.amount} ${reward.type}');
        await onUserEarnedReward();
      },
    );

    _rewardedAd = null;
  }

  void _reset() {
    _rewardedAd = null;
    _isAdLoaded = false;
  }

  // ===== Dispose (optional) =====
  void dispose() {
    _rewardedAd?.dispose();
    _reset();
  }
}
