import 'package:couple_note/core/config/app_constants.dart';

class AppException implements Exception {
  final String message;
  final int code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    required this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => '[$code] $message';
}

class ThrowException implements Exception {
  final ErrorCode errorCode;
  final Map<String, dynamic>? attributes;

  ThrowException(this.errorCode, {this.attributes});

  @override
  String toString() {
    if (attributes != null) {
      return _replaceAttributes(errorCode.message, attributes!);
    }
    return errorCode.message;
  }

  String _replaceAttributes(String message, Map<String, dynamic> attributes) {
    var result = message;
    for (var key in attributes.keys) {
      result = result.replaceAll('{$key}', attributes[key].toString());
    }
    return result;
  }
}
