import 'dart:io';
import 'package:couple_note/core/config/app_config.dart';
import 'package:minio/minio.dart';
import 'package:path/path.dart' as path;

class R2StorageService {
  late Minio _minio;
  late String _bucketName;
  late String _publicUrl;

  R2StorageService() {
    AppConfig.validateConfig();

    _bucketName = AppConfig.r2BucketName;
    _publicUrl = AppConfig.r2PublicUrl;

    _minio = Minio(
      endPoint: AppConfig.r2Endpoint,
      accessKey: AppConfig.r2AccessKey,
      secretKey: AppConfig.r2SecretKey,
      useSSL: true,
      region: 'auto',
    );
  }

  Future<String?> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final String ext = path.extension(imageFile.path);
      final String fileName =
          'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}$ext';

      final fileBytes = await imageFile.readAsBytes();

      await _minio.putObject(
        _bucketName,
        fileName,
        Stream.value(fileBytes),
        size: fileBytes.length,
        onProgress: (bytes) => print('Upload progress: $bytes bytes'),
      );

      return '$_publicUrl/$fileName';
    } catch (e) {
      print('Error uploading to R2: $e');
      return null;
    }
  }

  Future<bool> deleteAvatar(String avatarUrl) async {
    try {
      final uri = Uri.parse(avatarUrl);
      final objectName = uri.path.substring(1);

      await _minio.removeObject(_bucketName, objectName);
      return true;
    } catch (e) {
      print('Error deleting from R2: $e');
      return false;
    }
  }

  Future<String?> getPresignedUploadUrl({
    required String userId,
    required String fileName,
  }) async {
    try {
      final objectName = 'avatars/$userId/$fileName';
      final url = await _minio.presignedPutObject(
        _bucketName,
        objectName,
        expires: 3600,
      );
      return url;
    } catch (e) {
      print('Error getting presigned URL: $e');
      return null;
    }
  }
}
