import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemChannel {
  static const MethodChannel _channel = MethodChannel('app.channel/plugin');

  static Future<bool> isUnlocked() async {
    try {
      final result = await _channel.invokeMethod<bool>('isUnlocked');
      return result ?? false;
    } catch (e) {
      debugPrint('IsUnlocked error : $e');
      return false;
    }
  }

  static Future<bool> wakeScreen() async {
    try {
      final result = await _channel.invokeMethod<bool>('wakeScreen');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> releaseScreen() async {
    try {
      final result = await _channel.invokeMethod<bool>('releaseScreen');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> exitApp() async {
    try {
      await _channel.invokeMethod('exitApp');
    } catch (e) {
      print('Error exiting app: $e');
    }
  }
}
