import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_session_manager.dart';

class CustomAuthService {
  final UserRepository _userRepository;
  final FirebaseFirestore _firestore;
  final AuthSessionManager _sessionManager = AuthSessionManager();
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth
      .FirebaseAuth
      .instance; // ✅ ADD: Missing Firebase Auth instance
  // Keep a local reference to the current user
  User? _currentUser;

  CustomAuthService({
    required UserRepository userRepository,
    FirebaseFirestore? firestore,
  }) : _userRepository = userRepository,
       _firestore = firestore ?? FirebaseFirestore.instance;

  // Get the current authenticated user
  User? get currentUser => _currentUser;

  // Check for persisted authentication on startup
  Future<User?> checkPersistedAuth() async {
    try {
      if (_currentUser != null) {
        return _currentUser;
      }

      // Check if we have a valid session from the session manager
      final persistedUser = await _sessionManager.checkAndValidateSession();
      if (persistedUser != null) {
        print(
          "CustomAuthService: Retrieved valid persisted user session. ID: ${persistedUser.id}, Role: ${persistedUser.role}",
        );
        _currentUser = persistedUser;
        return _currentUser;
      }

      return null;
    } catch (e) {
      print("Error checking persisted auth: $e");
      return null;
    }
  }

  // Custom sign-in method with improved error handling
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('אימייל וסיסמה נדרשים');
      }

      // Step 1: Check if user exists in Firestore
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));

        if (querySnapshot.docs.isEmpty) {
          throw Exception('משתמש לא נמצא');
        }

        final doc = querySnapshot.docs.first;
        if (doc.data().isEmpty) {
          throw Exception('נתוני המשתמש ריקים');
        }

        // Step 2: Verify password using Firebase REST API directly
        final apiKey = await _getFirebaseApiKey();
        final response = await http
            .post(
              Uri.parse(
                'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
              ),
              body: json.encode({
                'email': email,
                'password': password,
                'returnSecureToken': true,
              }),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 15));

        final responseData = json.decode(response.body);

        if (response.statusCode != 200) {
          final error = responseData['error'];
          if (error != null) {
            final errorMessage = error['message'];
            if (errorMessage == 'INVALID_PASSWORD') {
              throw Exception('סיסמה שגויה');
            } else if (errorMessage == 'EMAIL_NOT_FOUND') {
              throw Exception('משתמש לא נמצא');
            } else {
              throw Exception('שגיאת אימות: $errorMessage');
            }
          }
          throw Exception('שגיאת אימות');
        }

        // Step 3: Authentication successful, create user from Firestore data
        final userData = Map<String, dynamic>.from(doc.data());
        userData['id'] = doc.id;

        final user = User.fromMap(userData);

        // Store user data in memory
        _currentUser = user;

        // Save authentication session with timestamp for 1-hour persistence using the session manager
        await _sessionManager.saveSession(user);
        print(
          "CustomAuthService: Authentication session saved for 1-hour persistence",
        );

        return user;
      } catch (firestoreError) {
        if (firestoreError is Exception) {
          throw firestoreError;
        }
        throw Exception('שגיאה בקבלת נתוני משתמש: $firestoreError');
      }
    } catch (e) {
      print('Authentication error details: $e');

      if (e is Exception) {
        throw e;
      }

      throw Exception('האימות נכשל: $e');
    }
  }

  // Optimized register method with improved error handling
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      // Input validation
      if (name.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          phoneNumber.isEmpty) {
        throw Exception('כל השדות נדרשים');
      }

      if (password.length < 6) {
        throw Exception('הסיסמה חייבת להכיל לפחות 6 תווים');
      }

      // Step 1: Check if user already exists in Firestore (quick check)
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (existingUsers.docs.isNotEmpty) {
        throw Exception('כתובת האימייל כבר בשימוש');
      }

      // Step 2: Create user in Firebase Auth using REST API
      final apiKey = await _getFirebaseApiKey();

      // Set a timeout for the registration request
      final response = await http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
            ),
            body: json.encode({
              'email': email,
              'password': password,
              'returnSecureToken': true,
            }),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        final error = responseData['error'];
        if (error != null) {
          final errorMessage = error['message'];
          if (errorMessage == 'EMAIL_EXISTS') {
            throw Exception('כתובת האימייל כבר בשימוש');
          } else if (errorMessage == 'WEAK_PASSWORD') {
            throw Exception('הסיסמה חלשה מדי');
          } else {
            throw Exception('שגיאת רישום: $errorMessage');
          }
        }
        throw Exception('שגיאת רישום');
      }

      // Step 3: Get the user ID from the response
      final userId = responseData['localId'];
      if (userId == null || userId.isEmpty) {
        throw Exception('שגיאה ביצירת משתמש: מזהה משתמש חסר');
      }

      // Step 4: Create user in Firestore with the specified role
      final user = User(
        id: userId,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        role: role, // Use the provided role
        createdAt: DateTime.now(),
      );

      // Set a timeout for the Firestore operation
      _currentUser = await _userRepository.createUser(user);

      // Save authentication session with timestamp for 1-hour persistence using the session manager
      await _sessionManager.saveSession(_currentUser!);
      print(
        "CustomAuthService: Authentication session saved for 1-hour persistence after registration",
      );

      // Return the created user
      return _currentUser;
    } catch (e) {
      print('Registration error details: $e');

      // If this is a timeout error, provide a more helpful message
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'ההרשמה לקחה יותר מדי זמן. המשתמש עשוי להיות רשום, אנא נסה להתחבר עם האימייל והסיסמה שיצרת',
        );
      }

      if (e is Exception) {
        throw e;
      }

      throw Exception('ההרשמה נכשלה: $e');
    }
  }

  // Create user method for staff to create accounts with any role
  Future<User?> createUserByStaff({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // Create Firebase Auth account
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Create comprehensive User object
      final user = User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        createdAt: DateTime.now(),
        // ✅ ADD: All additional fields
        idNumber: additionalInfo?['idNumber']?.isNotEmpty == true
            ? additionalInfo!['idNumber']
            : null,
        bio: additionalInfo?['bio']?.isNotEmpty == true
            ? additionalInfo!['bio']
            : null,
        address: additionalInfo?['address']?.isNotEmpty == true
            ? additionalInfo!['address']
            : null,
        city: additionalInfo?['city']?.isNotEmpty == true
            ? additionalInfo!['city']
            : null,
        postalCode: additionalInfo?['postalCode']?.isNotEmpty == true
            ? additionalInfo!['postalCode']
            : null,
        emergencyContact:
            additionalInfo?['emergencyContact']?.isNotEmpty == true
            ? additionalInfo!['emergencyContact']
            : null,
        emergencyContactPhone:
            additionalInfo?['emergencyContactPhone']?.isNotEmpty == true
            ? additionalInfo!['emergencyContactPhone']
            : null,
        emergencyContactRelation:
            additionalInfo?['emergencyContactRelation']?.isNotEmpty == true
            ? additionalInfo!['emergencyContactRelation']
            : null,
        healthFund: additionalInfo?['healthFund']?.isNotEmpty == true
            ? additionalInfo!['healthFund']
            : null,
        medicalFileNumber:
            additionalInfo?['medicalFileNumber']?.isNotEmpty == true
            ? additionalInfo!['medicalFileNumber']
            : null,
        medicalInfo: additionalInfo?['medicalInfo']?.isNotEmpty == true
            ? additionalInfo!['medicalInfo']
            : null,
        nationalInsurance:
            additionalInfo?['nationalInsurance']?.isNotEmpty == true
            ? additionalInfo!['nationalInsurance']
            : null,
        therapistContact:
            additionalInfo?['therapistContact']?.isNotEmpty == true
            ? additionalInfo!['therapistContact']
            : null,
        specialization: additionalInfo?['specialization']?.isNotEmpty == true
            ? additionalInfo!['specialization']
            : null,
      );

      // ✅ CRITICAL: Save to Firestore with proper error handling
      await _firestore.collection('users').doc(user.id).set(user.toMap());

      // ✅ ADD: Verify the document was saved
      final savedDoc = await _firestore.collection('users').doc(user.id).get();
      if (!savedDoc.exists) {
        throw Exception('Failed to save user to Firestore');
      }

      print('✅ User successfully created and saved: ${user.id}');
      return user;
    } catch (e) {
      print('❌ Error creating user: $e');
      // Clean up Firebase Auth user if Firestore save failed
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.currentUser!.delete();
      }
      throw e;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw Exception('כתובת אימייל נדרשת');
      }

      // Use Firebase REST API to send password reset email
      final apiKey = await _getFirebaseApiKey();
      final response = await http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey',
            ),
            body: json.encode({
              'requestType': 'PASSWORD_RESET',
              'email': email,
            }),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        final error = responseData['error'];
        if (error != null) {
          final errorMessage = error['message'];
          if (errorMessage == 'EMAIL_NOT_FOUND') {
            throw Exception('משתמש לא נמצא');
          } else {
            throw Exception('שגיאת איפוס סיסמה: $errorMessage');
          }
        }
        throw Exception('שגיאת איפוס סיסמה');
      }
    } catch (e) {
      print('Password reset error: $e');
      throw Exception('איפוס הסיסמה נכשל: $e');
    }
  }

  Future<void> signOut() async {
    try {
      // Clear local user data
      _currentUser = null;

      // Clear the persisted session using the session manager
      await _sessionManager.clearSession();
      print("CustomAuthService: Persisted session cleared on sign out");

      // Also sign out from Firebase Auth to be thorough
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('היציאה נכשלה: $e');
    }
  }

  // Helper method to get Firebase API key
  Future<String> _getFirebaseApiKey() async {
    try {
      // Try to get the API key from FirebaseOptions
      final apiKey = firebase_auth.FirebaseAuth.instance.app.options.apiKey;
      if (apiKey.isNotEmpty) {
        return apiKey;
      }
    } catch (e) {
      print('Error getting API key from FirebaseOptions: $e');
    }

    // Return the actual API key from firebase_options.dart
    return 'AIzaSyASzs-5cYh6v7aP6OrCFpJVFXbTWXeP8lw';
  }

  // Helper method to show auth error dialog
  static void showAuthErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שגיאת אימות'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }

  // Helper method to show registration success dialog with auto-navigation
  static void showRegistrationSuccessDialog(
    BuildContext context,
    String message,
    VoidCallback onComplete,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('הרשמה הושלמה בהצלחה'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onComplete();
            },
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }
}
