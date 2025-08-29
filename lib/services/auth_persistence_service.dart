import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user.dart';

class AuthPersistenceService {
  static const String _authTimestampKey = 'auth_timestamp';
  static const String _userDataKey = 'user_data';
  static const int _sessionDurationMinutes = 60; // 1 hour persistence
  
  // Save authentication timestamp and user data
  Future<void> saveAuthSession(User user) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Save current timestamp
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_authTimestampKey, timestamp);
      
      // Save user data
      await prefs.setString(_userDataKey, jsonEncode(user.toMap()));
      
      print('AuthPersistenceService: Saved auth session with timestamp $timestamp for user ${user.id}');
    } catch (e) {
      print('AuthPersistenceService: Error saving auth session: $e');
    }
  }
  
  // Check if session is still valid (within 1 hour)
  Future<bool> isSessionValid() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? timestamp = prefs.getInt(_authTimestampKey);
      
      if (timestamp == null) {
        print('AuthPersistenceService: No saved timestamp found');
        return false;
      }
      
      final DateTime authTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(authTime);
      
      final bool isValid = difference.inMinutes < _sessionDurationMinutes;
      print('AuthPersistenceService: Session ${isValid ? 'is' : 'is not'} valid. Time elapsed: ${difference.inMinutes} minutes');
      
      return isValid;
    } catch (e) {
      print('AuthPersistenceService: Error checking session validity: $e');
      return false;
    }
  }
  
  // Get cached user data if session is valid
  Future<User?> getValidSessionUser() async {
    try {
      if (!await isSessionValid()) {
        print('AuthPersistenceService: Session not valid, returning null user');
        return null;
      }
      
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString(_userDataKey);
      
      if (userData == null) {
        print('AuthPersistenceService: No user data found despite valid timestamp');
        return null;
      }
      
      final Map<String, dynamic> userMap = jsonDecode(userData);
      final User user = User.fromMap(userMap);
      print('AuthPersistenceService: Retrieved valid session user: ${user.id}');
      
      // Update timestamp to extend session
      await prefs.setInt(_authTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('AuthPersistenceService: Updated timestamp to extend session');
      
      return user;
    } catch (e) {
      print('AuthPersistenceService: Error retrieving session user: $e');
      return null;
    }
  }
  
  // Clear session data
  Future<void> clearSession() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTimestampKey);
      await prefs.remove(_userDataKey);
      print('AuthPersistenceService: Session cleared');
    } catch (e) {
      print('AuthPersistenceService: Error clearing session: $e');
    }
  }
}
