import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  
  // Token management
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  // User data
  static Future<void> saveUserData({
    required String userId,
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_userIdKey, userId),
      prefs.setString(_userEmailKey, email),
      prefs.setString(_userNameKey, name),
    ]);
  }
  
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_userIdKey),
      'email': prefs.getString(_userEmailKey),
      'name': prefs.getString(_userNameKey),
    };
  }
  
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_userIdKey),
      prefs.remove(_userEmailKey),
      prefs.remove(_userNameKey),
    ]);
  }
  
  // Clear all data
  static Future<void> clearAll() async {
    await removeToken();
    await clearUserData();
  }
}

