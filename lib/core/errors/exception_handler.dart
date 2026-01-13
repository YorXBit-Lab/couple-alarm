import 'dart:async';
import 'dart:io';

import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/errors/app_exception.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExceptionHandler {
  static AppException handle(dynamic error, [StackTrace? stackTrace]) {
    if (error is ThrowException) {
      return AppException(
        error.toString(),
        code: error.errorCode.code,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is AppException) {
      return error;
    }

    if (error is FirebaseAuthException) {
      return _handleFirebaseAuth(error, stackTrace);
    }

    if (error is FirebaseException) {
      return _handleFirebaseError(error, stackTrace);
    }

    if (error is DioException) {
      return _handleDioError(error, stackTrace);
    }

    if (error is SocketException) {
      return _handleSocketError(error, stackTrace);
    }

    if (error is HttpException) {
      return _handleHttpError(error, stackTrace);
    }

    if (error is FormatException) {
      return _handleFormatError(error, stackTrace);
    }

    if (error is TimeoutException) {
      return _handleTimeoutError(error, stackTrace);
    }

    if (error is ArgumentError) {
      return _handleArgumentError(error, stackTrace);
    }

    if (error is StateError) {
      return _handleStateError(error, stackTrace);
    }

    if (error is RangeError) {
      return _handleRangeError(error, stackTrace);
    }

    if (error is TypeError) {
      return _handleTypeError(error, stackTrace);
    }

    if (error is NoSuchMethodError) {
      return _handleNoSuchMethodError(error, stackTrace);
    }

    if (error is UnsupportedError) {
      return _handleUnsupportedError(error, stackTrace);
    }

    if (error is ConcurrentModificationError) {
      return _handleConcurrentModificationError(error, stackTrace);
    }

    if (error is OutOfMemoryError) {
      return _handleOutOfMemoryError(error, stackTrace);
    }

    if (error is StackOverflowError) {
      return _handleStackOverflowError(error, stackTrace);
    }

    // Default fallback
    return AppException(
      'Unhandled exception: ${error.toString()}',
      code: ErrorCode.unknown.code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  // Firebase Auth Errors
  static AppException _handleFirebaseAuth(
    FirebaseAuthException e,
    StackTrace? stackTrace,
  ) {
    switch (e.code) {
      case 'user-not-found':
        return AppException(
          ErrorCode.userNotExited.message,
          code: ErrorCode.userNotExited.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'email-already-in-use':
        return AppException(
          'Email already in use',
          code: ErrorCode.userExited.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'wrong-password':
        return AppException(
          ErrorCode.invalidPassword.message,
          code: ErrorCode.invalidPassword.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'invalid-email':
        return AppException(
          'Invalid email format',
          code: ErrorCode.invalidKey.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'too-many-requests':
        return AppException(
          ErrorCode.rateLimited.message,
          code: ErrorCode.rateLimited.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'user-disabled':
        return AppException(
          ErrorCode.accountSuspended.message,
          code: ErrorCode.accountSuspended.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'user-token-expired':
        return AppException(
          ErrorCode.sessionExpired.message,
          code: ErrorCode.sessionExpired.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'email-not-verified':
        return AppException(
          ErrorCode.emailNotVerified.message,
          code: ErrorCode.emailNotVerified.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'account-exists-with-different-credential':
      case 'credential-already-in-use':
        return AppException(
          'Account already exists with different credential',
          code: ErrorCode.userExited.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'operation-not-allowed':
      case 'unauthorized':
        return AppException(
          ErrorCode.unauthorized.message,
          code: ErrorCode.unauthorized.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      default:
        return AppException(
          e.message ?? 'Authentication failed',
          code: ErrorCode.unknown.code,
          originalError: e,
          stackTrace: stackTrace,
        );
    }
  }

  // Firebase General Errors
  static AppException _handleFirebaseError(
    FirebaseException e,
    StackTrace? stackTrace,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return AppException(
          ErrorCode.unauthorized.message,
          code: ErrorCode.unauthorized.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'not-found':
        return AppException(
          ErrorCode.noteNotFound.message,
          code: ErrorCode.noteNotFound.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'quota-exceeded':
        return AppException(
          ErrorCode.storageQuotaExceeded.message,
          code: ErrorCode.storageQuotaExceeded.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'unavailable':
        return AppException(
          ErrorCode.serviceUnavailable.message,
          code: ErrorCode.serviceUnavailable.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'unauthenticated':
        return AppException(
          ErrorCode.unauthenticated.message,
          code: ErrorCode.unauthenticated.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'cancelled':
        return AppException(
          'Operation cancelled',
          code: ErrorCode.unknown.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'data-loss':
        return AppException(
          ErrorCode.dataCorrupted.message,
          code: ErrorCode.dataCorrupted.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      default:
        return AppException(
          e.message ?? 'Firebase error',
          code: ErrorCode.unknown.code,
          originalError: e,
          stackTrace: stackTrace,
        );
    }
  }

  // Network Errors (Dio)
  static AppException _handleDioError(DioException e, StackTrace? stackTrace) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          ErrorCode.connectionTimeout.message,
          code: ErrorCode.connectionTimeout.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null) {
          switch (statusCode) {
            case 401:
              return AppException(
                ErrorCode.unauthenticated.message,
                code: ErrorCode.unauthenticated.code,
                originalError: e,
                stackTrace: stackTrace,
              );
            case 403:
              return AppException(
                ErrorCode.unauthorized.message,
                code: ErrorCode.unauthorized.code,
                originalError: e,
                stackTrace: stackTrace,
              );
            case 404:
              return AppException(
                'Resource not found',
                code: ErrorCode.noteNotFound.code,
                originalError: e,
                stackTrace: stackTrace,
              );
            case 429:
              return AppException(
                ErrorCode.rateLimited.message,
                code: ErrorCode.rateLimited.code,
                originalError: e,
                stackTrace: stackTrace,
              );
            case 500:
            case 502:
            case 503:
            case 504:
              return AppException(
                ErrorCode.serverError.message,
                code: ErrorCode.serverError.code,
                originalError: e,
                stackTrace: stackTrace,
              );
            default:
              return AppException(
                'HTTP Error: $statusCode',
                code: ErrorCode.networkError.code,
                originalError: e,
                stackTrace: stackTrace,
              );
          }
        }
        return AppException(
          ErrorCode.networkError.message,
          code: ErrorCode.networkError.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.cancel:
        return AppException(
          'Request cancelled',
          code: ErrorCode.unknown.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.connectionError:
        return AppException(
          ErrorCode.noInternetConnection.message,
          code: ErrorCode.noInternetConnection.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      default:
        return AppException(
          ErrorCode.networkError.message,
          code: ErrorCode.networkError.code,
          originalError: e,
          stackTrace: stackTrace,
        );
    }
  }

  // Socket Errors
  static AppException _handleSocketError(
    SocketException e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      ErrorCode.noInternetConnection.message,
      code: ErrorCode.noInternetConnection.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // HTTP Errors
  static AppException _handleHttpError(
    HttpException e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      ErrorCode.networkError.message,
      code: ErrorCode.networkError.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // Format Errors
  static AppException _handleFormatError(
    FormatException e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      'Invalid data format: ${e.message}',
      code: ErrorCode.invalidFormat.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // Timeout Errors
  static AppException _handleTimeoutError(
    TimeoutException e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      ErrorCode.connectionTimeout.message,
      code: ErrorCode.connectionTimeout.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // Argument Errors
  static AppException _handleArgumentError(
    ArgumentError e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      'Invalid argument: ${e.message}',
      code: ErrorCode.validationFailed.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // State Errors
  static AppException _handleStateError(StateError e, StackTrace? stackTrace) {
    return AppException(
      'Invalid state: ${e.message}',
      code: ErrorCode.unknown.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // Range Errors
  static AppException _handleRangeError(RangeError e, StackTrace? stackTrace) {
    return AppException(
      'Range error: ${e.message}',
      code: ErrorCode.validationFailed.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // Type Errors
  static AppException _handleTypeError(TypeError e, StackTrace? stackTrace) {
    return AppException(
      'Type error: ${e.toString()}',
      code: ErrorCode.unknown.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // NoSuchMethod Errors
  static AppException _handleNoSuchMethodError(
    NoSuchMethodError e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      'Method not found: ${e.toString()}',
      code: ErrorCode.unknown.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // Unsupported Errors
  static AppException _handleUnsupportedError(
    UnsupportedError e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      'Unsupported operation: ${e.message}',
      code: ErrorCode.platformNotSupported.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // Concurrent Modification Errors
  static AppException _handleConcurrentModificationError(
    ConcurrentModificationError e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      'Concurrent modification error',
      code: ErrorCode.unknown.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // Out of Memory Errors
  static AppException _handleOutOfMemoryError(
    OutOfMemoryError e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      'Out of memory error',
      code: ErrorCode.unknown.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  // Stack Overflow Errors
  static AppException _handleStackOverflowError(
    StackOverflowError e,
    StackTrace? stackTrace,
  ) {
    return AppException(
      'Stack overflow error',
      code: ErrorCode.unknown.code,
      originalError: e,
      stackTrace: stackTrace,
    );
  }
}
