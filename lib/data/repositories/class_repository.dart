import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class.dart';

class ClassRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'classes';

  ClassRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get all classes
  Stream<List<Class>> getClasses() {
    return _firestore
        .collection(_collectionPath)
        .where('isActive', isEqualTo: true)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Class.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get classes by mentor ID
  Stream<List<Class>> getClassesByMentor(String mentorId) {
    return _firestore
        .collection(_collectionPath)
        .where('mentorId', isEqualTo: mentorId)
        .where('isActive', isEqualTo: true)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Class.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get classes that a user is registered for
  Stream<List<Class>> getRegisteredClasses(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('registeredUserIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Class.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Add a new class
  Future<String> addClass(Class classItem) async {
    try {
      final docRef = await _firestore.collection(_collectionPath).add(classItem.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add class: $e');
    }
  }

  // Update an existing class
  Future<void> updateClass(Class classItem) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(classItem.id)
          .update(classItem.toMap());
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  // Delete a class (mark as inactive)
  Future<void> deleteClass(String classId) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(classId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }

  // Register a user for a class
  Future<void> registerForClass(String classId, String userId) async {
    try {
      // Get the current class data
      final docSnapshot = await _firestore.collection(_collectionPath).doc(classId).get();
      if (!docSnapshot.exists) {
        throw Exception('Class not found');
      }

      final classData = Class.fromMap(docSnapshot.data()!, docSnapshot.id);
      
      // Check if class is full
      if (classData.isFull) {
        throw Exception('Class is already full');
      }
      
      // Check if user is already registered
      if (classData.registeredUserIds.contains(userId)) {
        throw Exception('User is already registered for this class');
      }
      
      // Add user to registered users
      final updatedUserIds = List<String>.from(classData.registeredUserIds)..add(userId);
      
      // Update the class
      await _firestore
          .collection(_collectionPath)
          .doc(classId)
          .update({'registeredUserIds': updatedUserIds});
    } catch (e) {
      throw Exception('Failed to register for class: $e');
    }
  }

  // Unregister a user from a class
  Future<void> unregisterFromClass(String classId, String userId) async {
    try {
      // Get the current class data
      final docSnapshot = await _firestore.collection(_collectionPath).doc(classId).get();
      if (!docSnapshot.exists) {
        throw Exception('Class not found');
      }

      final classData = Class.fromMap(docSnapshot.data()!, docSnapshot.id);
      
      // Check if user is registered
      if (!classData.registeredUserIds.contains(userId)) {
        throw Exception('User is not registered for this class');
      }
      
      // Remove user from registered users
      final updatedUserIds = List<String>.from(classData.registeredUserIds)..remove(userId);
      
      // Update the class
      await _firestore
          .collection(_collectionPath)
          .doc(classId)
          .update({'registeredUserIds': updatedUserIds});
    } catch (e) {
      throw Exception('Failed to unregister from class: $e');
    }
  }
}
