import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {
  static const bool _isProduction = kReleaseMode;

  static String get appId {
    if (_isProduction) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-7162950416810945~1808613549';
      }
      return 'ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy';
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544~3347511713';
      }
      return 'ca-app-pub-3940256099942544~1458002511';
    }
  }

  static String get bannerAdUnitId {
    if (_isProduction) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2451812568230831/1189010507';
      }
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      }
      return 'ca-app-pub-3940256099942544/2934735716';
    }
  }

  static String get interstitialAdUnitId {
    if (_isProduction) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2451812568230831/2118948799';
      }
      return 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      }
      return 'ca-app-pub-3940256099942544/4411468910';
    }
  }

  static String get rewardedAdUnitId {
    if (_isProduction) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-2451812568230831/5160019760';
      }
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917';
      }
      return 'ca-app-pub-3940256099942544/1712485313';
    }
  }
}
