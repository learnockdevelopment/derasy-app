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

  // Check if current user is admin (administrator only)
  static bool isStudent() {
    final user = getCurrentUser();
    if (user == null) return false;
    return user.role.toLowerCase() == 'student';
  }

  // Check if current user is moderator
  static bool isParent() {
    final user = getCurrentUser();
    if (user == null) return false;
    return user.role.toLowerCase() == 'parent';
  }

  // Check if current user is admin or moderator
  static bool isAdminOrModerator() {
    return isStudent() || isParent();
  }
}
