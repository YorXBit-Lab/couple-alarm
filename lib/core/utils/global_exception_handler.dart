import 'package:couple_note/core/errors/exception_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'error_logger.dart';

class GlobalExceptionHandler {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = ExceptionHandler.handle(
        details.exception,
        details.stack,
      );
      ErrorLogger.log(exception);

      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final exception = ExceptionHandler.handle(error, stack);
      ErrorLogger.log(exception);
      return true;
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (error is PlatformException) {
        final exception = ExceptionHandler.handle(error, stack);
        ErrorLogger.log(exception);
      }
      return true;
    };
  }
}
