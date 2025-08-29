import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knafayim_app/config/service_locator.dart';
import 'package:knafayim_app/data/models/lesson.dart';
import 'package:knafayim_app/data/models/user.dart';
import 'package:knafayim_app/data/repositories/lesson_repository.dart';
import 'package:knafayim_app/data/repositories/user_repository.dart';
import '../models/report.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  ReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ✅ CONSOLIDATED: One analytics method for all types
  Future<Map<String, dynamic>> generateAnalytics({
    required ReportType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final lessons = await _lessonRepository.getAllLessons(
        startDate: startDate,
        endDate: endDate,
      );

      switch (type) {
        case ReportType.workingHours:
          return _calculateWorkingHoursAnalytics(lessons);
        case ReportType.attendance:
          return _calculateAttendanceAnalytics(lessons);
        case ReportType.userActivity:
          return await _calculateUserActivityAnalytics(lessons);
        default:
          return _calculateWorkingHoursAnalytics(lessons);
      }
    } catch (e) {
      print('Error generating analytics for $type: $e');
      return _getDefaultAnalytics(type);
    }
  }

  // ✅ SIMPLIFIED: Working hours calculation
  Map<String, dynamic> _calculateWorkingHoursAnalytics(List<Lesson> lessons) {
    double totalHours = 0;
    int totalEntries = 0;
    int approvedEntries = 0;
    Map<String, double> mentorHours = {};

    for (final lesson in lessons) {
      if (lesson.status == 'completed') {
        final hours = lesson.durationMinutes / 60.0;
        totalHours += hours;
        totalEntries++;
        approvedEntries++;

        if (lesson.assignedInstructorId != null) {
          mentorHours[lesson.assignedInstructorId!] =
              (mentorHours[lesson.assignedInstructorId!] ?? 0) + hours;
        }
      }
    }

    return {
      'totalHours': totalHours,
      'totalEntries': totalEntries,
      'approvalRate': totalEntries > 0
          ? (approvedEntries / totalEntries) * 100
          : 0.0,
      'averageHoursPerEntry': totalEntries > 0
          ? totalHours / totalEntries
          : 0.0,
      'mentorHours': mentorHours,
      'topMentor': _getTopMentor(mentorHours),
    };
  }

  // ✅ SIMPLIFIED: Attendance calculation
  Map<String, dynamic> _calculateAttendanceAnalytics(List<Lesson> lessons) {
    int totalRecords = 0, present = 0, absent = 0, late = 0, excused = 0;

    for (final lesson in lessons) {
      for (final record in lesson.attendanceRecords) {
        totalRecords++;
        switch (record.status) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            present++;
            break; // Late counts as attended
          case 'excused':
            excused++;
            break;
        }
      }
    }

    return {
      'totalRecords': totalRecords,
      'presentCount': present,
      'absentCount': absent,
      'lateCount': late,
      'excusedCount': excused,
      'attendanceRate': totalRecords > 0 ? (present / totalRecords) * 100 : 0.0,
    };
  }

  // ✅ SIMPLIFIED: User activity calculation
  Future<Map<String, dynamic>> _calculateUserActivityAnalytics(
    List<Lesson> lessons,
  ) async {
    try {
      final users = await _userRepository.getAllUsers();
      final artists = users.where((u) => u.role == UserRole.client).toList();
      final mentors = users.where((u) => u.role == UserRole.mentor).toList();

      int activeArtists = 0;
      int activeMentors = 0;

      // Count active artists (attended at least one lesson)
      for (final artist in artists) {
        final hasAttended = lessons.any(
          (lesson) => lesson.attendanceRecords.any(
            (record) =>
                record.artistId == artist.id &&
                (record.status == 'present' || record.status == 'late'),
          ),
        );
        if (hasAttended) activeArtists++;
      }

      // Count active mentors (taught at least one lesson)
      for (final mentor in mentors) {
        final hasTaught = lessons.any(
          (lesson) => lesson.assignedInstructorId == mentor.id,
        );
        if (hasTaught) activeMentors++;
      }

      return {
        'totalUsers': users.length,
        'totalArtists': artists.length,
        'totalMentors': mentors.length,
        'activeUsers': activeArtists + activeMentors,
        'activeArtists': activeArtists,
        'activeMentors': activeMentors,
        'activityRate': artists.isNotEmpty
            ? (activeArtists / artists.length) * 100
            : 0.0,
      };
    } catch (e) {
      return _getDefaultAnalytics(ReportType.userActivity);
    }
  }

  // ✅ SIMPLIFIED: Default analytics
  Map<String, dynamic> _getDefaultAnalytics(ReportType type) {
    switch (type) {
      case ReportType.workingHours:
        return {
          'totalHours': 0.0,
          'totalEntries': 0,
          'approvalRate': 0.0,
          'averageHoursPerEntry': 0.0,
          'mentorHours': <String, double>{},
          'topMentor': 'אין נתונים',
        };
      case ReportType.attendance:
        return {
          'totalRecords': 0,
          'presentCount': 0,
          'absentCount': 0,
          'lateCount': 0,
          'excusedCount': 0,
          'attendanceRate': 0.0,
        };
      case ReportType.userActivity:
        return {
          'totalUsers': 0,
          'activeUsers': 0,
          'activityRate': 0.0,
          'totalArtists': 0,
          'totalMentors': 0,
          'activeArtists': 0,
          'activeMentors': 0,
        };
      default:
        return {};
    }
  }

  String _getTopMentor(Map<String, double> mentorHours) {
    if (mentorHours.isEmpty) return 'אין נתונים';
    return mentorHours.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // ✅ LEGACY: Keep for backward compatibility
  @Deprecated('Use generateAnalytics instead')
  Future<Map<String, dynamic>> generateWorkingHoursAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return generateAnalytics(
      type: ReportType.workingHours,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @Deprecated('Use generateAnalytics instead')
  Future<Map<String, dynamic>> generateAttendanceAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return generateAnalytics(
      type: ReportType.attendance,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @Deprecated('Use generateAnalytics instead')
  Future<Map<String, dynamic>> generateUserActivityAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return generateAnalytics(
      type: ReportType.userActivity,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Keep existing CRUD methods unchanged
  Future<List<Report>> getReports({
    ReportType type = ReportType.all,
    String? userId,
  }) async {
    try {
      Query query = _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true);

      if (type != ReportType.all) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (userId != null) {
        query = query.where('relatedUserIds', arrayContains: userId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map(
            (doc) => Report.fromMap(
              Map<String, dynamic>.from({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports: $e');
    }
  }

  Future<Report> getReportById(String reportId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (!doc.exists) throw Exception('Report not found');
      return Report.fromMap(
        Map<String, dynamic>.from({...doc.data()!, 'id': doc.id}),
      );
    } catch (e) {
      throw Exception('Failed to get report: $e');
    }
  }

  Future<String> createReport(Report report) async {
    try {
      final docRef = await _firestore.collection('reports').add(report.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  Future<void> updateReport(Report report) async {
    try {
      await _firestore
          .collection('reports')
          .doc(report.id)
          .update(report.toMap());
    } catch (e) {
      throw Exception('Failed to update report: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  Future<List<Lesson>> getAllLessons({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _lessonRepository.getAllLessons(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      return [];
    }
  }
}
