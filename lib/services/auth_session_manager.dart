import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
import '../config/service_locator.dart';

class AuthSessionManager {
  static const String _userKey = 'current_user';
  static const String _timestampKey = 'auth_timestamp';
  static const Duration _sessionDuration = Duration(hours: 1);
  
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  
  // Save user session with timestamp
  Future<void> saveSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save user data as JSON
      final userJson = jsonEncode(user.toMap());
      await prefs.setString(_userKey, userJson);
      
      // Save current timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_timestampKey, timestamp);
      
      print('AuthSessionManager: Session saved successfully. Expiration: ${DateTime.now().add(_sessionDuration)}');
    } catch (e) {
      print('AuthSessionManager: Error saving session: $e');
    }
  }
  
  // Check if session exists and is still valid (within 1 hour)
  Future<User?> checkAndValidateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have stored user data
      final userJson = prefs.getString(_userKey);
      if (userJson == null) {
        print('AuthSessionManager: No stored user session found');
        return null;
      }
      
      // Check if we have a timestamp
      final timestamp = prefs.getInt(_timestampKey);
      if (timestamp == null) {
        print('AuthSessionManager: No timestamp found for session');
        await clearSession(); // Clean up invalid session
        return null;
      }
      
      // Check if session is still valid (within 1 hour)
      final sessionTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final currentTime = DateTime.now();
      final sessionAge = currentTime.difference(sessionTime);
      
      if (sessionAge > _sessionDuration) {
        print('AuthSessionManager: Session expired. Age: ${sessionAge.inMinutes} minutes');
        await clearSession(); // Clean up expired session
        return null;
      }
      
      // Session is valid, parse user data
      try {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        
        // Add the user ID if it's not in the map
        if (!userData.containsKey('id')) {
          // Try to get user ID from a separate field if stored
          final userId = prefs.getString('user_id');
          if (userId != null && userId.isNotEmpty) {
            userData['id'] = userId;
          }
        }
        
        final user = User.fromMap(userData);
        
        // Verify user still exists in Firestore
        final firestoreUser = await _userRepository.getUserById(user.id);
        if (firestoreUser == null) {
          print('AuthSessionManager: User no longer exists in Firestore');
          await clearSession();
          return null;
        }
        
        print('AuthSessionManager: Valid session found. User: ${user.name}, Role: ${user.role}');
        return user;
      } catch (e) {
        print('AuthSessionManager: Error parsing user data: $e');
        await clearSession(); // Clean up invalid session
        return null;
      }
    } catch (e) {
      print('AuthSessionManager: Error checking session: $e');
      return null;
    }
  }
  
  // Clear the session
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_timestampKey);
      print('AuthSessionManager: Session cleared successfully');
    } catch (e) {
      print('AuthSessionManager: Error clearing session: $e');
    }
  }
  
  // Refresh the session timestamp to extend it for another hour
  Future<void> refreshSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have stored user data
      final userJson = prefs.getString(_userKey);
      if (userJson == null) {
        print('AuthSessionManager: No stored user session to refresh');
        return;
      }
      
      // Update the timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_timestampKey, timestamp);
      
      print('AuthSessionManager: Session refreshed successfully. New expiration: ${DateTime.now().add(_sessionDuration)}');
    } catch (e) {
      print('AuthSessionManager: Error refreshing session: $e');
    }
  }
}
