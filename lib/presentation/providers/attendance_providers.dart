import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/attendance_record.dart';
import '../../data/models/lesson.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../config/service_locator.dart';

// Repository providers
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return serviceLocator<AttendanceRepository>();
});

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return serviceLocator<LessonRepository>();
});

// Attendance records for a specific lesson
// Enhanced attendance provider with immediate updates
final lessonAttendanceProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, lessonId) {
      final lessonRepository = ref.watch(lessonRepositoryProvider);

      // Create a stream that emits immediately and then every 10 seconds
      return Stream<dynamic>.multi((controller) async {
        // Emit immediately
        controller.add(null);

        // Then emit every 10 seconds
        await for (var _ in Stream.periodic(const Duration(seconds: 10))) {
          controller.add(null);
        }
      }).asyncMap((_) async {
        try {
          print('🔄 PROVIDER: Fetching lesson attendance for $lessonId');
          final lesson = await lessonRepository.getLessonById(lessonId);
          final records = lesson?.attendanceRecords ?? [];
          print('🔄 PROVIDER: Found ${records.length} attendance records');
          return records;
        } catch (e) {
          print('❌ PROVIDER: Error fetching lesson attendance: $e');
          return <AttendanceRecord>[];
        }
      });
    });

// Attendance statistics for a lesson
final attendanceStatsProvider =
    Provider.family<Map<String, int>, List<AttendanceRecord>>((
      ref,
      attendanceRecords,
    ) {
      return {
        'present': attendanceRecords.where((r) => r.status == 'present').length,
        'absent': attendanceRecords.where((r) => r.status == 'absent').length,
        'late': attendanceRecords.where((r) => r.status == 'late').length,
        'excused': attendanceRecords.where((r) => r.status == 'excused').length,
        'pending': attendanceRecords.where((r) => r.status == 'pending').length,
        'total': attendanceRecords.length,
      };
    });

// Attendance actions provider
final attendanceActionsProvider = Provider<AttendanceActions>((ref) {
  final lessonRepository = ref.watch(lessonRepositoryProvider);
  return AttendanceActions(lessonRepository, ref);
});

// Actions class for attendance operations
class AttendanceActions {
  final LessonRepository _lessonRepository;
  final Ref _ref;

  AttendanceActions(this._lessonRepository, this._ref);

  Future<bool> updateLessonAttendance(
    Lesson lesson,
    List<AttendanceRecord> attendanceRecords,
  ) async {
    try {
      print('💾 ACTIONS: Updating lesson attendance...');

      final updatedLesson = lesson.copyWith(
        attendanceRecords: attendanceRecords,
      );
      await _lessonRepository.updateLessonDetails(updatedLesson);

      print('✅ ACTIONS: Lesson updated in Firestore');

      // 🔥 CRITICAL FIX: Multiple invalidation strategy
      _ref.invalidate(lessonAttendanceProvider(lesson.id));

      // Force immediate refresh
      await Future.delayed(const Duration(milliseconds: 200));
      _ref.invalidate(lessonAttendanceProvider(lesson.id));

      // Final refresh after a longer delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        _ref.invalidate(lessonAttendanceProvider(lesson.id));
      });

      return true;
    } catch (e) {
      print('❌ ACTIONS: Error updating lesson attendance: $e');
      return false;
    }
  }

  Future<bool> bulkUpdateAttendance(
    Lesson lesson,
    String status,
    List<String> artistIds,
  ) async {
    try {
      final updatedRecords = lesson.attendanceRecords.map((record) {
        if (artistIds.contains(record.artistId)) {
          return record.copyWith(status: status, updatedAt: DateTime.now());
        }
        return record;
      }).toList();

      return await updateLessonAttendance(lesson, updatedRecords);
    } catch (e) {
      print('Error bulk updating attendance: $e');
      return false;
    }
  }

  Future<bool> updateSingleAttendance(
    Lesson lesson,
    String artistId,
    String status, {
    String? notes,
  }) async {
    try {
      print('💾 ACTIONS: Updating single attendance for $artistId to $status');

      // Find and update the specific attendance record
      final updatedRecords = lesson.attendanceRecords.map((record) {
        if (record.artistId == artistId) {
          return record.copyWith(
            status: status,
            notes: notes,
            updatedAt: DateTime.now(),
          );
        }
        return record;
      }).toList();

      // If no existing record, create a new one
      if (!updatedRecords.any((record) => record.artistId == artistId)) {
        updatedRecords.add(
          AttendanceRecord(
            id: '${lesson.id}_$artistId',
            artistId: artistId,
            lessonId: lesson.id,
            date: lesson.date,
            status: status,
            notes: notes,
          ),
        );
      }

      return await updateLessonAttendance(lesson, updatedRecords);
    } catch (e) {
      print('❌ ACTIONS: Error updating single attendance: $e');
      return false;
    }
  }
}
