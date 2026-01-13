// core/utils/result.dart
abstract class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.error(String message) = Error<T>;

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get data => isSuccess ? (this as Success<T>).data : null;
  String? get error => isError ? (this as Error<T>).message : null;

  // Utility methods
  R fold<R>(R Function(T data) onSuccess, R Function(String error) onError) {
    if (isSuccess) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onError((this as Error<T>).message);
    }
  }

  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess) {
      try {
        return Result.success(mapper((this as Success<T>).data));
      } catch (e) {
        return Result.error(e.toString());
      }
    } else {
      return Result.error((this as Error<T>).message);
    }
  }

  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) mapper) async {
    if (isSuccess) {
      try {
        final result = await mapper((this as Success<T>).data);
        return Result.success(result);
      } catch (e) {
        return Result.error(e.toString());
      }
    } else {
      return Result.error((this as Error<T>).message);
    }
  }
}

class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

class Error<T> extends Result<T> {
  final String message;

  const Error(this.message);

  @override
  String toString() => 'Error(message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

// Extension methods for easier usage
extension ResultExtensions<T> on Result<T> {
  /// Execute a function only if the result is successful
  void onSuccess(void Function(T data) callback) {
    if (isSuccess) {
      callback((this as Success<T>).data);
    }
  }

  /// Execute a function only if the result is an error
  void onError(void Function(String error) callback) {
    if (isError) {
      callback((this as Error<T>).message);
    }
  }

  /// Get the data or return a default value
  T getOrDefault(T defaultValue) {
    return isSuccess ? (this as Success<T>).data : defaultValue;
  }

  /// Get the data or throw an exception
  T getOrThrow() {
    if (isSuccess) {
      return (this as Success<T>).data;
    } else {
      throw Exception((this as Error<T>).message);
    }
  }
}

// Usage examples:
/*
// Creating results
final successResult = Result.success("Hello World");
final errorResult = Result.error("Something went wrong");

// Checking results
if (result.isSuccess) {
  print("Success: ${result.data}");
} else {
  print("Error: ${result.error}");
}

// Using fold
final message = result.fold(
  (data) => "Success: $data",
  (error) => "Error: $error",
);

// Using map
final mappedResult = result.map((data) => data.length);

// Using extensions
result.onSuccess((data) => print("Got: $data"));
result.onError((error) => print("Failed: $error"));

final dataOrDefault = result.getOrDefault("default value");
*/
