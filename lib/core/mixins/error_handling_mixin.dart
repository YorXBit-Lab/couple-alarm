import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/errors/app_exception.dart';
import 'package:couple_note/core/errors/exception_handler.dart';
import 'package:flutter/material.dart';
import '../utils/error_logger.dart';

mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  void handleError(dynamic error, [StackTrace? stackTrace]) {
    final exception = ExceptionHandler.handle(error, stackTrace);
    ErrorLogger.log(exception);

    if (mounted) {
      _showErrorDialog(exception);
    }
  }

  void _showErrorDialog(AppException exception) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(exception.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void showSnackBarError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<ApiResponse<R>> safeCall<R>(Future<R> Function() call) async {
    try {
      final result = await call();
      return ApiResponse.success(result);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }
}
