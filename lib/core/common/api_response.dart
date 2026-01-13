import 'package:couple_note/core/errors/app_exception.dart';

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.metadata,
  });

  factory ApiResponse.success(T data, {Map<String, dynamic>? metadata}) {
    return ApiResponse(
      code: 0,
      message: 'Success',
      data: data,
      metadata: metadata,
    );
  }

  factory ApiResponse.failure(
    AppException e, {
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse(code: e.code, message: e.message, metadata: metadata);
  }

  bool get isSuccess => code == 0;
  bool get isFailure => code != 0;

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    'data': data,
    'metadata': metadata,
  };
}
