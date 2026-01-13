import 'dart:developer' as developer;
import 'package:couple_note/core/errors/app_exception.dart';
import 'package:flutter/foundation.dart';

class ErrorLogger {
  static void log(AppException exception) {
    if (kDebugMode) {
      developer.log(
        exception.message,
        name: 'AppException',
        error: exception.originalError,
        stackTrace: exception.stackTrace,
      );
    }
  }

  static void logInfo(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      developer.log(message, name: 'AppInfo');
    }
  }

  static void logWarning(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      developer.log(message, name: 'AppWarning');
    }
  }

  // Uncomment and implement when using crash reporting services
  // static void _logToRemoteService(AppException exception) {
  //   FirebaseCrashlytics.instance.recordError(
  //     exception.originalError ?? exception.message,
  //     exception.stackTrace,
  //     fatal: false,
  //   );
  // }
}
