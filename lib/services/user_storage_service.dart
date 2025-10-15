import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';

class UserStorageService {
  static const String _currentUserKey = 'current_user';
  static const String _savedUsersKey = 'saved_users';
  static const String _isLoggedInKey = 'is_logged_in';

  static final GetStorage _storage = GetStorage();

  // Current User Methods
  static Future<void> saveCurrentUser(UserModel user) async {
    await _storage.write(_currentUserKey, jsonEncode(user.toJson()));
    await _storage.write(_isLoggedInKey, true);
    await _addToSavedUsers(user);
  }

  static UserModel? getCurrentUser() {
    final userJson = _storage.read(_currentUserKey);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson as String) as Map<String, dynamic>);
    }
    return null;
  }

  static Future<void> clearCurrentUser() async {
    await _storage.remove(_currentUserKey);
    await _storage.write(_isLoggedInKey, false);
  }

  static bool isLoggedIn() {
    return _storage.read(_isLoggedInKey) ?? false;
  }

  // Saved Users Methods
  static Future<void> _addToSavedUsers(UserModel user) async {
    final savedUsers = getSavedUsers();

    // Check if user already exists
    final existingIndex = savedUsers.indexWhere((u) => u.email == user.email);

    if (existingIndex != -1) {
      // Update existing user
      savedUsers[existingIndex] = user;
    } else {
      // Add new user
      savedUsers.add(user);
    }

    await _storage.write(
        _savedUsersKey, jsonEncode(savedUsers.map((u) => u.toJson()).toList()));
  }

  static List<UserModel> getSavedUsers() {
    final usersJson = _storage.read(_savedUsersKey);
    if (usersJson != null) {
      final List<dynamic> usersList = jsonDecode(usersJson as String) as List<dynamic>;
      return usersList.map((userJson) => UserModel.fromJson(userJson as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<void> removeSavedUser(String email) async {
    final savedUsers = getSavedUsers();
    savedUsers.removeWhere((user) => user.email == email);
    await _storage.write(
        _savedUsersKey, jsonEncode(savedUsers.map((u) => u.toJson()).toList()));
  }

  static Future<void> clearAllSavedUsers() async {
    await _storage.remove(_savedUsersKey);
  }

  // Utility Methods
  static Future<void> logout() async {
    await clearCurrentUser();
  }

  static Future<void> switchUser(UserModel user) async {
    await saveCurrentUser(user);
  }
}
