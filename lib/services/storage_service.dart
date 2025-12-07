import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Firebase UID
  static Future<void> saveFirebaseUid(String uid) async {
    await _storage.write(key: 'firebase_uid', value: uid);
  }

  static Future<String?> getFirebaseUid() async {
    return await _storage.read(key: 'firebase_uid');
  }

  // User ID
  static Future<void> saveUserId(int userId) async {
    await _storage.write(key: 'user_id', value: userId.toString());
  }

  static Future<int?> getUserId() async {
    final value = await _storage.read(key: 'user_id');
    return value != null ? int.tryParse(value) : null;
  }

  // Profile update tracking
  static Future<void> saveLastProfileUpdate(DateTime date) async {
    await _storage.write(key: 'last_profile_update', value: date.toIso8601String());
  }

  static Future<DateTime?> getLastProfileUpdate() async {
    final value = await _storage.read(key: 'last_profile_update');
    return value != null ? DateTime.tryParse(value) : null;
  }

  static Future<bool> canUpdateProfile() async {
    final lastUpdate = await getLastProfileUpdate();
    if (lastUpdate == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inDays >= 7;
  }

  // New user flag (basé sur la base de données)
  static Future<void> setIsNewUser(bool isNew) async {
    await _storage.write(key: 'is_new_user_from_db', value: isNew.toString());
  }

  static Future<bool> isNewUserFromDb() async {
    final value = await _storage.read(key: 'is_new_user_from_db');
    return value == 'true';
  }

  static Future<void> setHasCompletedFirstLogin(bool completed) async {
    await _storage.write(key: 'has_completed_first_login', value: completed.toString());
    // Une fois complété, ce n'est plus un nouvel utilisateur
    if (completed) {
      await setIsNewUser(false);
    }
  }

  static Future<bool> hasCompletedFirstLogin() async {
    final value = await _storage.read(key: 'has_completed_first_login');
    return value == 'true';
  }

  // Clear all
  // Pending notification action (pour navigation après connexion)
  static Future<void> savePendingNotificationAction(String? actionType) async {
    if (actionType == null || actionType.isEmpty) {
      await _storage.delete(key: 'pending_notification_action');
    } else {
      await _storage.write(key: 'pending_notification_action', value: actionType);
    }
  }

  static Future<String?> getPendingNotificationAction() async {
    return await _storage.read(key: 'pending_notification_action');
  }

  static Future<void> clearPendingNotificationAction() async {
    await _storage.delete(key: 'pending_notification_action');
  }

  // Clear all
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

