import 'dart:convert';
import 'package:couple_note/data/models/user_model.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageKeys {
  static const String user = 'user_data';
  static const String pendingDeepLink = 'pending_deep_link';
  static const String partner = 'partner_data';
  static const String theme = 'theme_mode';
  static const String language = 'language_code';
  static const String notification = 'notification_enabled';
  static const String firstLaunch = 'first_launch';
  static const String coupleId = 'couple_id';
  static const String navNotification = 'nav_notification';
}

class LocalStorageService {
  final SharedPreferences _prefs;

  static const String _userKey = 'user_data';
  static const String _partnerKey = 'partner_data';

  static const String _themeKey = 'theme_mode';
  static const String _notificationKey = 'notification_enabled';
  static const String _autoSetReminderKey = 'auto_set_reminder';
  static const String _firstLaunchKey = 'first_launch';
  static const String _coupleIdKey = 'couple_id';
  static const String _partnerIdKey = 'partner_id';

  LocalStorageService(this._prefs);

  Future<void> saveUser(UserEntity user, String userKey) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      fcmToken: user.fcmToken,
      isAutoApproveReminder: user.isAutoApproveReminder ?? false,
    );

    await _prefs.setString(_userKey, jsonEncode(userModel.toJson()));
  }

  dynamic getObject(String userKey) {
    final userJson = _prefs.getString(userKey);
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  Future<void> saveCoupleId({required String? coupleId}) async {
    try {
      if (coupleId != null && coupleId.isNotEmpty) {
        await _prefs.setString(_coupleIdKey, coupleId);
      } else {
        await _prefs.remove(_coupleIdKey);
      }
    } catch (e) {
      throw LocalStorageException('Failed to save couple id: $e');
    }
  }

  String? getCoupleId() {
    try {
      return _prefs.getString(_coupleIdKey);
    } catch (e) {
      throw LocalStorageException('Failed to get couple ID: $e');
    }
  }

  String? getPartnerId() {
    try {
      return _prefs.getString(_partnerIdKey);
    } catch (e) {
      throw LocalStorageException('Failed to get partner ID: $e');
    }
  }

  Future<void> clearCoupleInfo() async {
    try {
      await _prefs.remove(_coupleIdKey);
    } catch (e) {
      throw LocalStorageException('Failed to clear couple info: $e');
    }
  }

  // Theme
  Future<void> setThemeMode(String themeMode) async {
    await _prefs.setString(_themeKey, themeMode);
  }

  String getThemeMode() {
    return _prefs.getString(_themeKey) ?? 'system';
  }

  // Language

  Future<void> setNotificationEnabled(bool enabled) async {
    await _prefs.setBool(_notificationKey, enabled);
  }

  Future<void> setAutoSetReminderEnabled(bool enabled) async {
    await _prefs.setBool(_autoSetReminderKey, enabled);
  }

  bool getNotificationEnabled() {
    return _prefs.getBool(_notificationKey) ?? true;
  }

  bool getAutoSetReminderEnabled() {
    return _prefs.getBool(_autoSetReminderKey) ?? true;
  }

  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await _prefs.setBool(_firstLaunchKey, isFirstLaunch);
  }

  bool isFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }

  Future<void> clearUserData() async {
    await clearUser();
    await clearCoupleInfo();
  }
}

class LocalStorageException implements Exception {
  final String message;

  const LocalStorageException(this.message);

  @override
  String toString() => 'LocalStorageException: $message';
}
