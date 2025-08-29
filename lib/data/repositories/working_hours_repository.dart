import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/working_hours.dart';

class WorkingHoursRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simple query without complex indexes - this will work immediately
  // FIXED: Use Future instead of Stream to avoid index issues
  Future<List<WorkingHours>> getWorkingHoursForMentor(String mentorId) async {
    try {
      print("DEBUG: Getting working hours for mentor: $mentorId");

      final querySnapshot = await _firestore
          .collection('working_hours')
          .where('mentorId', isEqualTo: mentorId)
          .get(); // Remove orderBy to avoid index issues

      print("DEBUG: Found ${querySnapshot.docs.length} documents");

      final workingHours = querySnapshot.docs.map((doc) {
        print("DEBUG: Document data: ${doc.data()}");
        return WorkingHours.fromMap({...doc.data(), 'id': doc.id});
      }).toList();

      // Sort in Dart instead of Firestore
      workingHours.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print("DEBUG: Returning ${workingHours.length} working hours");
      return workingHours;
    } catch (e) {
      print('DEBUG: Error getting working hours: $e');
      return [];
    }
  }

  // Add new working hours
  Future<String> addWorkingHours(WorkingHours workingHours) async {
    try {
      final docRef = await _firestore
          .collection('working_hours')
          .add(
            workingHours
                .copyWith(
                  createdAt: DateTime.now(),
                  lastModified: DateTime.now(),
                )
                .toMap(),
          );

      if (kDebugMode) {
        print('Working hours added successfully: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding working hours: $e');
      }
      throw Exception('Failed to add working hours: $e');
    }
  }

  // Approve working hours (staff only)
  Future<bool> approveWorkingHours(
    String workingHoursId,
    String approvedBy,
  ) async {
    try {
      await _firestore.collection('working_hours').doc(workingHoursId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
        'rejectionReason': null, // Clear any previous rejection reason
      });

      if (kDebugMode) {
        print('Working hours approved: $workingHoursId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error approving working hours: $e');
      }
      return false;
    }
  }

  // Reject working hours (staff only)
  Future<bool> rejectWorkingHours(
    String workingHoursId,
    String rejectedBy,
    String reason,
  ) async {
    try {
      await _firestore.collection('working_hours').doc(workingHoursId).update({
        'status': 'rejected',
        'approvedBy': rejectedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'lastModified': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Working hours rejected: $workingHoursId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting working hours: $e');
      }
      return false;
    }
  }

  // Bulk approve working hours
  Future<bool> bulkApproveWorkingHours(
    List<String> workingHoursIds,
    String approvedBy,
  ) async {
    try {
      final batch = _firestore.batch();

      for (String id in workingHoursIds) {
        final docRef = _firestore.collection('working_hours').doc(id);
        batch.update(docRef, {
          'status': 'approved',
          'approvedBy': approvedBy,
          'approvedAt': FieldValue.serverTimestamp(),
          'lastModified': FieldValue.serverTimestamp(),
          'rejectionReason': null,
        });
      }

      await batch.commit();

      if (kDebugMode) {
        print('Bulk approved ${workingHoursIds.length} working hours');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error bulk approving working hours: $e');
      }
      return false;
    }
  }

  // Get all working hours for staff (from all mentors)
  Future<List<WorkingHours>> getAllWorkingHours() async {
    try {
      final querySnapshot = await _firestore.collection('working_hours').get();

      final workingHours = querySnapshot.docs
          .map((doc) => WorkingHours.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Sort in Dart instead of Firestore
      workingHours.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return workingHours;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all working hours: $e');
      }
      return [];
    }
  }

  // Get simple stats without complex queries
  Future<WorkingHoursStats> getWorkingHoursStats(String mentorId) async {
    try {
      final workingHours = await getWorkingHoursForMentor(mentorId);

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      int totalHoursThisWeek = 0;
      int totalHoursThisMonth = 0;
      int pendingHours = 0;
      int approvedHours = 0;
      int rejectedHours = 0;

      for (final hours in workingHours) {
        // Count hours by status
        switch (hours.status) {
          case WorkingHoursStatus.pending:
            pendingHours += hours.durationMinutes;
            break;
          case WorkingHoursStatus.approved:
            approvedHours += hours.durationMinutes;
            break;
          case WorkingHoursStatus.rejected:
            rejectedHours += hours.durationMinutes;
            break;
        }

        // Count weekly hours (approved only)
        if (hours.status == WorkingHoursStatus.approved &&
            hours.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
          totalHoursThisWeek += hours.durationMinutes;
        }

        // Count monthly hours (approved only)
        if (hours.status == WorkingHoursStatus.approved &&
            hours.date.isAfter(
              startOfMonth.subtract(const Duration(days: 1)),
            )) {
          totalHoursThisMonth += hours.durationMinutes;
        }
      }

      return WorkingHoursStats(
        totalHoursThisWeek: (totalHoursThisWeek / 60).round(),
        totalHoursThisMonth: (totalHoursThisMonth / 60).round(),
        pendingHours: (pendingHours / 60).round(),
        approvedHours: (approvedHours / 60).round(),
        rejectedHours: (rejectedHours / 60).round(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting working hours stats: $e');
      }

      return WorkingHoursStats(
        totalHoursThisWeek: 0,
        totalHoursThisMonth: 0,
        pendingHours: 0,
        approvedHours: 0,
        rejectedHours: 0,
      );
    }
  }
}
