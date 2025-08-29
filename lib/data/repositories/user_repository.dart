import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  UserRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  // Create user
  Future<User> createUser(User user) async {
    try {
      if (kDebugMode) {
        print('Creating user: ${user.id}, ${user.name}, ${user.role}');
      }

      // Create user in Firestore
      await _firestore.collection('users').doc(user.id).set(user.toMap());

      if (kDebugMode) {
        print('User created successfully in Firestore');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user: $e');
      }
      throw Exception('Failed to create user: $e');
    }
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return User.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all users: $e');
      }
      return [];
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      // ✅ ADD: Check if document exists
      if (!doc.exists || doc.data() == null) {
        print('User document not found for ID: $userId');
        return null;
      }

      return User.fromMap({...doc.data()!, 'id': doc.id});
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      if (kDebugMode) {
        print('Getting user by email: $email');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('No user found with email: $email');
        }
        throw Exception('User not found with email: $email');
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;

      final user = User.fromMap(data);
      if (kDebugMode) {
        print('User found by email: ${user.name}, Role: ${user.role}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user by email: $e');
      }
      rethrow;
    }
  }

  // Update user
  Future<bool> updateUser(User user) async {
    try {
      if (kDebugMode) {
        print('Updating user: ${user.id}, ${user.name}, ${user.role}');
      }

      final userData = user.toMap();
      await _firestore.collection('users').doc(user.id).update(userData);

      if (kDebugMode) {
        print('User updated successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user: $e');
      }
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      if (kDebugMode) {
        print('Deleting user: $userId');
      }

      await _firestore.collection('users').doc(userId).delete();

      if (kDebugMode) {
        print('User deleted successfully from Firestore');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user: $e');
      }
      return false;
    }
  }

  // Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.toString().split('.').last)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return User.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting users by role: $e');
      }
      return [];
    }
  }
}
