import 'package:couple_note/core/services/fcm_service.dart';
import 'package:couple_note/domain/repositories/user_repository.dart';

class FCMTokenManager {
  final UserRepository _userRepository;
  static bool _isTokenRefreshListenerSetup = false;

  FCMTokenManager(this._userRepository);

  Future<void> updateFCMTokenOnAuth(String userId) async {
    try {
      String? fcmToken = await FCMService.getFCMToken();
      print('🔑 Lấy FCM token: $fcmToken');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        final currentUser = await _userRepository.getUserById(userId);

        if (currentUser.data?.fcmToken != fcmToken)
          await _userRepository.updateUserFCMToken(userId, fcmToken);

        // Setup token refresh listener (chỉ setup một lần)
        _setupTokenRefreshListener(userId);
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật FCM token: $e');
    }
  }

  void _setupTokenRefreshListener(String userId) {
    if (_isTokenRefreshListenerSetup) return;

    FCMService.onTokenRefresh((newToken) async {
      try {
        await _userRepository.updateUserFCMToken(userId, newToken);
      } catch (e) {
        print('❌ Lỗi khi tự động cập nhật FCM token: $e');
      }
    });

    _isTokenRefreshListenerSetup = true;
  }

  Future<void> clearFCMTokenOnSignOut(String userId) async {
    try {
      await FCMService.deleteToken();

      await _userRepository.updateUserFCMToken(userId, '');
    } catch (e) {
      print('❌ Lỗi khi xóa FCM token: $e');
    }
  }
}
