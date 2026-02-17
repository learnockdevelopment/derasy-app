import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../models/user.dart';

class UserStorageService {
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _authTokenKey = 'auth_token';

  static final GetStorage _storage = GetStorage();

  // Current User Methods
  static Future<void> saveCurrentUser(User user, String token) async {
    await _storage.write(_currentUserKey, jsonEncode(user.toJson()));
    await _storage.write(_authTokenKey, token);
    await _storage.write(_isLoggedInKey, true);
  }

  static User? getCurrentUser() {
    final userJson = _storage.read(_currentUserKey);
    if (userJson != null) {
      return User.fromJson(
          jsonDecode(userJson as String) as Map<String, dynamic>);
    }
    return null;
  }

  static String? getAuthToken() {
    return _storage.read(_authTokenKey);
  }

  static Future<void> clearCurrentUser() async {
    await _storage.remove(_currentUserKey);
    await _storage.remove(_authTokenKey);
    await _storage.write(_isLoggedInKey, false);
  }

  static bool isLoggedIn() {
    return _storage.read(_isLoggedInKey) ?? false;
  }

  // Utility Methods
  static Future<void> logout() async {
    await clearCurrentUser();
  }

  // Get user data as Map
  static Future<Map<String, dynamic>?> getUserData() async {
    final user = getCurrentUser();
    if (user != null) {
      return user.toJson();
    }
    return null;
  }

  // Clear all user data
  static Future<void> clearUserData() async {
    await clearCurrentUser();
  }

  // Role checks
  static bool isStudent() {
    final user = getCurrentUser();
    if (user == null) return false;
    final role = user.role.toLowerCase();
    return role == 'student';
  }

  static bool isParent() {
    final user = getCurrentUser();
    if (user == null) return false;
    final role = user.role.toLowerCase();
    return role == 'parent';
  }

  static bool isSchoolOwner() {
    final user = getCurrentUser();
    if (user == null) return false;
    final role = user.role.toLowerCase();
    return role == 'school_owner' || role == 'schoolowner';
  }

  static bool isSchoolModerator() {
    final user = getCurrentUser();
    if (user == null) return false;
    final role = user.role.toLowerCase();
    return role == 'school_moderator' || role == 'moderator';
  }

  static bool isSchoolAdmin() {
    final user = getCurrentUser();
    if (user == null) return false;
    final role = user.role.toLowerCase();
    return role == 'school_admin' || role == 'admin' || isSchoolOwner() || isSchoolModerator();
  }

  static bool isSales() {
    final user = getCurrentUser();
    if (user == null) return false;
    final role = user.role.toLowerCase();
    return role == 'sales';
  }

  static bool isAdminOrModerator() {
    return isSchoolAdmin() || isSchoolOwner() || isSchoolModerator();
  }
  // Biometric Login Support
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _storedEmailKey = 'stored_email';
  static const String _storedPasswordKey = 'stored_password';

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(_biometricEnabledKey, enabled);
    if (!enabled) {
      await clearBiometricCredentials();
    }
  }

  static bool isBiometricEnabled() {
    return _storage.read(_biometricEnabledKey) ?? false;
  }

  static Future<void> saveBiometricCredentials(String email, String password) async {
    await _storage.write(_storedEmailKey, email);
    await _storage.write(_storedPasswordKey, password);
    await setBiometricEnabled(true);
  }

  static Future<void> clearBiometricCredentials() async {
    await _storage.remove(_storedEmailKey);
    await _storage.remove(_storedPasswordKey);
  }

  static Map<String, String>? getBiometricCredentials() {
    final email = _storage.read(_storedEmailKey);
    final password = _storage.read(_storedPasswordKey);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}

