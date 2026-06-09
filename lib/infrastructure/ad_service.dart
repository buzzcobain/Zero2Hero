import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class AdServiceInterface {
  Future<void> initialize();
  Future<void> loadInterstitialAd();
  Future<void> showInterstitialAd(VoidCallback onDismissed);
  Future<void> loadRewardedInterstitialAd();
  Future<void> showRewardedInterstitialAd(VoidCallback onEarnedReward, VoidCallback onDismissed);
  Widget getBannerAdWidget();
  void disposeBanner();
}

class AdmobService implements AdServiceInterface {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  @override
  Widget getBannerAdWidget() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  @override
  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  @override
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
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

  @override
  Future<void> showInterstitialAd(VoidCallback onDismissed) async {
    if (_interstitialAd == null) {
      onDismissed();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onDismissed();
      },
    );
    await _interstitialAd!.show();
  }

  @override
  Future<void> loadRewardedInterstitialAd() async {
    await RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
        },
      ),
    );
  }

  @override
  Future<void> showRewardedInterstitialAd(
    VoidCallback onEarnedReward,
    VoidCallback onDismissed,
  ) async {
    if (_rewardedInterstitialAd == null) {
      onEarnedReward();
      onDismissed();
      return;
    }
    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        onDismissed();
      },
    );
    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (ad, reward) {
        onEarnedReward();
      },
    );
  }
}

class MockAdService implements AdServiceInterface {
  @override
  Future<void> initialize() async {}

  @override
  Widget getBannerAdWidget() {
    return Container(
      height: 50,
      color: Colors.blueGrey.shade800,
      alignment: Alignment.center,
      child: const Text(
        'Banner Ad Mock (Offline Mode)',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  @override
  void disposeBanner() {}

  @override
  Future<void> loadInterstitialAd() async {}

  @override
  Future<void> showInterstitialAd(VoidCallback onDismissed) async {
    onDismissed();
  }

  @override
  Future<void> loadRewardedInterstitialAd() async {}

  @override
  Future<void> showRewardedInterstitialAd(
    VoidCallback onEarnedReward,
    VoidCallback onDismissed,
  ) async {
    onEarnedReward();
    onDismissed();
  }
}
