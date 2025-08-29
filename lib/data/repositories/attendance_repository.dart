import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_record.dart';
import '../models/lesson.dart';
import '../models/user.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Record artist check-in/check-out
  Future<bool> recordArtistAttendance({
    required String artistId,
    required DateTime timestamp,
    required String action, // 'check_in' or 'check_out'
    String? notes,
  }) async {
    try {
      final attendanceData = {
        'artistId': artistId,
        'timestamp': timestamp.toIso8601String(),
        'action': action,
        'notes': notes,
        'date': DateTime(
          timestamp.year,
          timestamp.month,
          timestamp.day,
        ).toIso8601String(),
      };

      await _firestore
          .collection('daily_attendance')
          .doc('${artistId}_${DateTime.now().toString().substring(0, 10)}')
          .set(attendanceData, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Attendance recorded: $action for artist $artistId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error recording attendance: $e');
      }
      return false;
    }
  }

  // Get artist attendance status for today
  Future<Map<String, dynamic>?> getArtistTodayAttendance(
    String artistId,
  ) async {
    try {
      final today = DateTime.now().toString().substring(0, 10);
      final doc = await _firestore
          .collection('daily_attendance')
          .doc('${artistId}_$today')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting today attendance: $e');
      }
      return null;
    }
  }

  // Update lesson attendance record
  // Update lesson attendance record
  Future<bool> updateLessonAttendance({
    required String lessonId,
    required String artistId,
    required String status, // 'present', 'absent', 'late'
    String? notes,
    Function(String artistId, String status)? onAbsentCallback, // ✅ ADD THIS
  }) async {
    try {
      final lessonRef = _firestore.collection('lessons').doc(lessonId);
      final lessonDoc = await lessonRef.get();

      if (!lessonDoc.exists) {
        throw Exception('Lesson not found');
      }

      final lessonData = lessonDoc.data()!;
      final lesson = Lesson.fromMap(lessonData);

      // Update or add attendance record
      final updatedRecords = lesson.attendanceRecords.toList();
      final existingIndex = updatedRecords.indexWhere(
        (record) => record.artistId == artistId,
      );

      final newRecord = AttendanceRecord(
        id: '${lessonId}_$artistId',
        lessonId: lessonId,
        artistId: artistId,
        date: DateTime.now(),
        status: status,
        notes: notes,
      );

      if (existingIndex >= 0) {
        updatedRecords[existingIndex] = newRecord;
      } else {
        updatedRecords.add(newRecord);
      }

      // Update lesson with new attendance records
      await lessonRef.update({
        'attendanceRecords': updatedRecords
            .map((record) => record.toMap())
            .toList(),
      });

      if (kDebugMode) {
        print('✅ Lesson attendance updated for artist $artistId: $status');
      }

      // ✅ TRIGGER CALLBACK FOR ABSENT STATUS
      if (status == 'absent' && onAbsentCallback != null) {
        print('🚨 REPO: Triggering absent callback for $artistId');
        onAbsentCallback(artistId, status);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating lesson attendance: $e');
      }
      return false;
    }
  }

  // Get attendance report for date range
  Future<List<Map<String, dynamic>>> getAttendanceReport({
    required DateTime startDate,
    required DateTime endDate,
    String? artistId,
  }) async {
    try {
      Query query = _firestore.collection('daily_attendance');

      if (artistId != null) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      final querySnapshot = await query
          .where(
            'date',
            isGreaterThanOrEqualTo: startDate.toIso8601String().substring(
              0,
              10,
            ),
          )
          .where(
            'date',
            isLessThanOrEqualTo: endDate.toIso8601String().substring(0, 10),
          )
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting attendance report: $e');
      }
      return [];
    }
  }

  // Get all artists currently checked in
  Future<List<String>> getCurrentlyCheckedInArtists() async {
    try {
      final today = DateTime.now().toString().substring(0, 10);
      final querySnapshot = await _firestore
          .collection('daily_attendance')
          .where('date', isEqualTo: today)
          .where('action', isEqualTo: 'check_in')
          .get();

      final checkedInArtists = <String>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final artistId = data['artistId'] as String;

        // Check if they haven't checked out yet
        final checkOutQuery = await _firestore
            .collection('daily_attendance')
            .where('artistId', isEqualTo: artistId)
            .where('date', isEqualTo: today)
            .where('action', isEqualTo: 'check_out')
            .get();

        if (checkOutQuery.docs.isEmpty) {
          checkedInArtists.add(artistId);
        }
      }

      return checkedInArtists;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting checked in artists: $e');
      }
      return [];
    }
  }
}
