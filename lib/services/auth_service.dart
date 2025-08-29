import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
import '../services/auth_session_manager.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final UserRepository _userRepository;
  final AuthSessionManager _sessionManager = AuthSessionManager();
  final Uuid _uuid = const Uuid();
  User? _appUser;

  AuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    required UserRepository userRepository,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _userRepository = userRepository;

  User? get currentUser => _appUser;

/*************  ✨ Windsurf Command ⭐  *************/
  /// Retrieves the current authenticated user.
  ///
  /// This method first checks for a cached user in memory. If none is found,
  /// it attempts to retrieve a valid session from the session manager. If
  /// both checks fail, it queries Firebase Auth for the current user and
  /// fetches the user details from the repository if the Firebase user exists.
  ///
  /// Returns the `User` object if a user is found, otherwise returns `null`.
  ///
  /// Throws:
  ///   - Exception if there is an error fetching the user from the repository.

/*******  28b5b8e8-8b34-4a39-b353-93c661670cd6  *******/
  Future<User?> getCurrentUser() async {
    print("AuthService: getCurrentUser() called.");

    // If we have a cached user in memory, return it
    if (_appUser != null) {
      print(
          "AuthService: Returning cached _appUser. ID: ${_appUser!.id}, Role: ${_appUser!.role}");
      return _appUser;
    }

    // Check if we have a valid session from the session manager
    final persistedUser = await _sessionManager.checkAndValidateSession();
    if (persistedUser != null) {
      print(
          "AuthService: Retrieved valid persisted user session. ID: ${persistedUser.id}, Role: ${persistedUser.role}");
      _appUser = persistedUser;
      return _appUser;
    }

    // If no valid persisted session, check Firebase Auth
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      print("AuthService: Firebase user found. UID: ${firebaseUser.uid}");
      try {
        print(
            "AuthService: Attempting to fetch user from _userRepository.getUserById(${firebaseUser.uid})");
        _appUser = await _userRepository.getUserById(firebaseUser.uid);
        if (_appUser != null) {
          print(
              "AuthService: User fetched from repository. ID: ${_appUser!.id}, Name: ${_appUser!.name}, Email: ${_appUser!.email}, Role: ${_appUser!.role}");
          // Save the session for future app launches
          await _sessionManager.saveSession(_appUser!);
        } else {
          print(
              "AuthService: _userRepository.getUserById(${firebaseUser.uid}) returned null.");
        }
        return _appUser;
      } catch (e) {
        print(
            'AuthService: Error fetching app user from Firestore in getCurrentUser: $e');
        return null;
      }
    } else {
      print(
          "AuthService: No Firebase user found (_firebaseAuth.currentUser is null).");
    }
    return null;
  }

  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  Future<User> signIn({required String email, required String password}) async {
    print("AuthService: signIn() called for email: $email");
    try {
      // Attempt to sign in with Firebase Auth first
      firebase_auth.UserCredential userCredential;
      try {
        print(
            "AuthService: Attempting Firebase signInWithEmailAndPassword for $email");
        userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print(
            "AuthService: Firebase signInWithEmailAndPassword successful for $email. UID: ${userCredential.user?.uid}");
      } catch (authError) {
        print(
            "AuthService: Firebase signInWithEmailAndPassword failed for $email. Error: $authError");
        // Handle specific Pigeon error if necessary, otherwise rethrow
        if (authError.toString().contains(
            "type 'List<Object?>' is not a subtype of type 'Pigeon UserDetails?'")) {
          // This specific error might indicate a successful auth but an issue with a native plugin interaction.
          // We might still have a current Firebase user if a previous session was not fully cleared or due to other reasons.
          print(
              "AuthService: Caught Pigeon UserDetails error. Will check _firebaseAuth.currentUser.");
          if (_firebaseAuth.currentUser != null &&
              _firebaseAuth.currentUser!.email == email) {
            print(
                "AuthService: Firebase currentUser exists with matching email after Pigeon error. UID: ${_firebaseAuth.currentUser!.uid}");
            // Proceed as if auth was successful, user will be fetched from Firestore
          } else {
            print(
                "AuthService: No matching Firebase currentUser after Pigeon error. Rethrowing original authError.");
            throw _handleAuthException(
                authError is firebase_auth.FirebaseAuthException
                    ? authError
                    : firebase_auth.FirebaseAuthException(
                        code: 'unknown', message: authError.toString()));
          }
        } else if (authError is firebase_auth.FirebaseAuthException) {
          throw _handleAuthException(authError);
        } else {
          throw Exception('Authentication failed: $authError');
        }
      }

      final firebaseUser =
          _firebaseAuth.currentUser; // Re-check current user after auth attempt
      if (firebaseUser == null) {
        print(
            "AuthService: Firebase user is null after sign-in attempt for $email.");
        throw Exception(
            'Authentication failed: No Firebase user after sign-in.');
      }

      print(
          "AuthService: Attempting to fetch user data from Firestore for UID: ${firebaseUser.uid}");
      try {
        _appUser = await _userRepository.getUserById(firebaseUser.uid);
        if (_appUser != null) {
          print(
              "AuthService: User successfully fetched from Firestore after sign-in. ID: ${_appUser!.id}, Role: ${_appUser!.role}");

          // Save authentication session with timestamp for 1-hour persistence using the session manager
          await _sessionManager.saveSession(_appUser!);
          print(
              "AuthService: Authentication session saved for 1-hour persistence");

          return _appUser!;
        } else {
          print(
              "AuthService: User not found in Firestore with UID: ${firebaseUser.uid} after successful Firebase auth. This should ideally not happen for existing users.");
          // This case might occur if a user exists in Firebase Auth but not in Firestore, which is unusual for this app's flow.
          // For robustness, one might consider creating a Firestore entry here, but current logic implies user should exist.
          throw Exception(
              'User authenticated with Firebase but not found in application database.');
        }
      } catch (firestoreError) {
        print(
            "AuthService: Error fetching user from Firestore after sign-in for UID: ${firebaseUser.uid}. Error: $firestoreError");
        // If user exists in Firebase Auth but fetching from Firestore fails, this is a critical issue.
        throw Exception(
            'Failed to load user data from database after authentication: $firestoreError');
      }
    } catch (e) {
      print('AuthService: Overall signIn error details: $e');
      _appUser = null; // Clear any potentially stale cached user on error
      if (e is Exception) {
        throw e;
      }
      throw Exception('Authentication failed: $e');
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
  }) async {
    if (kDebugMode) {
      print("AuthService: register() called for email: $email, role: $role");
    }
    try {
      // Check if user already exists in Firestore by email (as a pre-check)
      try {
        print(
            "AuthService: Checking if user exists by email: $email in Firestore before Firebase registration.");
        final existingUser = await _userRepository.getUserByEmail(email);
        // If getUserByEmail doesn't throw, it means user exists.
        print(
            "AuthService: User with email $email already exists in Firestore. ID: ${existingUser!.id}");
        throw Exception('כתובת האימייל כבר בשימוש');
      } catch (e) {
        // This is expected if user doesn't exist. Check if it's the specific 'not found' or a different error.
        if (e.toString().contains('User not found with email') ||
            e.toString().contains('No user found with email')) {
          print(
              "AuthService: User with email $email does not exist in Firestore. Proceeding with registration.");
        } else if (e.toString().contains('כתובת האימייל כבר בשימוש')) {
          rethrow; // Rethrow the specific exception if it's already the one we want
        } else {
          print(
              "AuthService: Unexpected error checking user by email $email: $e. Proceeding with registration cautiously.");
        }
      }

      firebase_auth.UserCredential userCredential;
      String userId;
      try {
        print(
            "AuthService: Attempting Firebase createUserWithEmailAndPassword for $email");
        userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (userCredential.user == null) {
          print(
              "AuthService: Firebase createUserWithEmailAndPassword returned null user for $email.");
          throw Exception(
              'Registration failed: No user returned from Firebase');
        }
        userId = userCredential.user!.uid;
        print(
            "AuthService: Firebase user created successfully. UID: $userId for email: $email");
      } catch (authError) {
        print(
            "AuthService: Firebase createUserWithEmailAndPassword failed for $email. Error: $authError");
        if (authError.toString().contains(
            "type 'List<Object?>' is not a subtype of type 'Pigeon UserDetails?'")) {
          print(
              "AuthService: Caught Pigeon UserDetails error during registration. Checking if user was created despite error.");
          try {
            // Attempt to sign in to see if the user was actually created in Firebase
            await _firebaseAuth.signInWithEmailAndPassword(
                email: email, password: password);
            final firebaseAuthCurrentUser = _firebaseAuth.currentUser;
            if (firebaseAuthCurrentUser != null) {
              userId = firebaseAuthCurrentUser.uid;
              print(
                  "AuthService: User $email found in Firebase after Pigeon error during registration. UID: $userId");
            } else {
              print(
                  "AuthService: User $email NOT found in Firebase after Pigeon error. Generating UUID.");
              userId = _uuid
                  .v4(); // Fallback, though this user won't be linked to Firebase Auth
            }
          } catch (signInError) {
            print(
                "AuthService: SignIn attempt after Pigeon error failed during registration for $email. Error: $signInError. Generating UUID.");
            userId = _uuid.v4(); // Fallback
          }
        } else if (authError is firebase_auth.FirebaseAuthException) {
          throw _handleAuthException(authError);
        } else {
          throw Exception('Registration failed: $authError');
        }
      }

      final user = User(
        id: userId,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        role: role, // Role is passed in during registration
        createdAt: DateTime.now(),
      );
      print(
          "AuthService: Creating user object in Firestore. ID: ${user.id}, Name: ${user.name}, Role: ${user.role}");
      _appUser = await _userRepository.createUser(user);
      print(
          "AuthService: User created in Firestore. ID: ${_appUser!.id}, Role: ${_appUser!.role}");

      // Save authentication session with timestamp for 1-hour persistence using the session manager
      await _sessionManager.saveSession(_appUser!);
      print(
          "AuthService: Authentication session saved for 1-hour persistence after registration");

      return _appUser!;
    } catch (e) {
      print('AuthService: Overall registration error details: $e');
      _appUser = null; // Clear cache on error
      if (e is Exception) {
        throw e;
      }
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    print("AuthService: resetPassword() called for email: $email");
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print("AuthService: Password reset email sent to $email");
    } on firebase_auth.FirebaseAuthException catch (e) {
      print(
          "AuthService: Firebase Auth Exception during password reset for $email: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    } catch (e) {
      print("AuthService: Generic error during password reset for $email: $e");
      throw Exception('Password reset failed: $e');
    }
  }

  Future<void> signOut() async {
    print("AuthService: signOut() called.");
    try {
      await _firebaseAuth.signOut();
      _appUser = null;

      // Clear the persisted session using the session manager
      await _sessionManager.clearSession();
      print(
          "AuthService: Firebase sign out successful. _appUser and persisted session cleared.");
    } catch (e) {
      print(
          "AuthService: Error during Firebase sign out: $e. Clearing _appUser and persisted session anyway.");
      _appUser = null;
      await _sessionManager.clearSession();
      throw Exception('Sign out failed: $e');
    }
  }

  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    print("AuthService: updatePassword() called.");
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        print("AuthService: User not authenticated for updatePassword.");
        throw Exception('User not authenticated');
      }
      print(
          "AuthService: Re-authenticating user ${user.email} for password update.");
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      print("AuthService: User re-authenticated. Updating password.");
      await user.updatePassword(newPassword);
      print("AuthService: Password updated successfully for ${user.email}.");
    } on firebase_auth.FirebaseAuthException catch (e) {
      print(
          "AuthService: Firebase Auth Exception during password update: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    } catch (e) {
      print("AuthService: Generic error during password update: $e");
      throw Exception('Password update failed: $e');
    }
  }

  Future<void> deleteAccount(String password) async {
    print("AuthService: deleteAccount() called.");
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        print("AuthService: User not authenticated for deleteAccount.");
        throw Exception('User not authenticated');
      }
      print(
          "AuthService: Re-authenticating user ${user.email} for account deletion.");
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      print(
          "AuthService: User re-authenticated. Deleting user from Firestore (UID: ${user.uid}).");
      await _userRepository.deleteUser(user.uid);
      print(
          "AuthService: User deleted from Firestore. Deleting from Firebase Auth.");
      await user.delete();
      _appUser = null;

      // Clear the persisted session using the session manager
      await _sessionManager.clearSession();
      print(
          "AuthService: Account deleted successfully for ${user.email}. _appUser and persisted session cleared.");
    } on firebase_auth.FirebaseAuthException catch (e) {
      print(
          "AuthService: Firebase Auth Exception during account deletion: ${e.code} - ${e.message}");
      throw _handleAuthException(e);
    } catch (e) {
      print("AuthService: Generic error during account deletion: $e");
      throw Exception('Account deletion failed: $e');
    }
  }

  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    print(
        'AuthService: Firebase Auth Exception (handled): ${e.code} - ${e.message}');
    switch (e.code) {
      case 'user-not-found':
        return Exception('משתמש לא נמצא');
      case 'wrong-password':
        return Exception('סיסמה שגויה');
      case 'invalid-email':
        return Exception('כתובת אימייל לא תקינה');
      case 'user-disabled':
        return Exception('המשתמש מושבת');
      case 'email-already-in-use':
        return Exception('כתובת האימייל כבר בשימוש');
      case 'operation-not-allowed':
        return Exception('הפעולה אינה מורשית');
      case 'weak-password':
        return Exception('הסיסמה חלשה מדי');
      case 'requires-recent-login':
        return Exception('נדרשת התחברות מחדש לפעולה זו');
      default:
        return Exception('שגיאת אימות: ${e.message}');
    }
  }
}
