import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get r2Endpoint => dotenv.env['R2_ENDPOINT'] ?? '';
  static String get r2AccessKey => dotenv.env['R2_ACCESS_KEY'] ?? '';
  static String get r2SecretKey => dotenv.env['R2_SECRET_KEY'] ?? '';
  static String get r2BucketName =>
      dotenv.env['R2_BUCKET_NAME'] ?? 'couple-note';
  static String get r2PublicUrl => dotenv.env['R2_PUBLIC_URL'] ?? '';

  static bool get isR2Configured {
    return r2Endpoint.isNotEmpty &&
        r2AccessKey.isNotEmpty &&
        r2SecretKey.isNotEmpty;
  }

  static void validateConfig() {
    assert(r2Endpoint.isNotEmpty, 'R2_ENDPOINT is not configured');
    assert(r2AccessKey.isNotEmpty, 'R2_ACCESS_KEY is not configured');
    assert(r2SecretKey.isNotEmpty, 'R2_SECRET_KEY is not configured');

    if (!isR2Configured) {
      throw Exception(
        'R2 Storage is not properly configured. Check your .env file.',
      );
    }
  }
}
