import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/lesson.dart';
import '../models/attendance_record.dart';
import 'user_repository.dart';
import 'lesson_repository.dart';
import '../../config/service_locator.dart';

class ArtistCommunityAnalyticsRepository {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();

  /// Get comprehensive community analytics with real data
  Future<Map<String, dynamic>> getCommunityAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? now;

      // Get all real data
      final allUsers = await _userRepository.getAllUsers();
      final artists = allUsers.where((u) => u.role == UserRole.client).toList();
      final mentors = allUsers.where((u) => u.role == UserRole.mentor).toList();
      final lessons = await _lessonRepository.getAllLessons(
        startDate: start,
        endDate: end,
      );

      // Calculate real aggregate statistics
      final stats = await _calculateAggregateStats(artists, lessons);

      // Generate real studio participation data
      final studioData = await _calculateStudioParticipation(lessons);

      // Calculate real attendance trends
      final attendanceTrends = await _calculateAttendanceTrends(
        lessons,
        start,
        end,
      );

      // Get real top performing artists
      final topArtists = await _getTopPerformingArtists(artists, lessons);

      // Get artists needing attention
      final needAttentionArtists = await _getArtistsNeedingAttention(
        artists,
        lessons,
      );

      // Calculate weekly patterns
      final weeklyPatterns = await _calculateWeeklyPatterns(lessons);

      return {
        'aggregateStats': stats,
        'studioParticipation': studioData,
        'attendanceTrends': attendanceTrends,
        'topPerformingArtists': topArtists,
        'artistsNeedingAttention': needAttentionArtists,
        'weeklyPatterns': weeklyPatterns,
        'totalArtists': artists.length,
        'totalMentors': mentors.length,
        'totalLessons': lessons.length,
        'dateRange': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      print('Error getting community analytics: $e');
      return {};
    }
  }

  /// Calculate real aggregate statistics
  Future<Map<String, dynamic>> _calculateAggregateStats(
    List<User> artists,
    List<Lesson> lessons,
  ) async {
    // Count active artists (those with attendance records)
    final activeArtistIds = <String>{};
    int totalAttendanceRecords = 0;
    int presentRecords = 0;

    for (final lesson in lessons) {
      for (final record in lesson.attendanceRecords) {
        totalAttendanceRecords++;
        if (record.status == 'present' || record.status == 'late') {
          activeArtistIds.add(record.artistId);
          presentRecords++;
        }
      }
    }

    final averageAttendanceRate = totalAttendanceRecords > 0
        ? (presentRecords / totalAttendanceRecords) * 100
        : 0.0;

    return {
      'totalRegistered': artists.length,
      'activeThisMonth': activeArtistIds.length,
      'averageAttendanceRate': averageAttendanceRate,
      'totalLessonsHeld': lessons.length,
      'totalAttendanceRecords': totalAttendanceRecords,
    };
  }

  /// Calculate real studio participation rates
  Future<List<Map<String, dynamic>>> _calculateStudioParticipation(
    List<Lesson> lessons,
  ) async {
    final studioParticipation = <String, int>{};
    final studioColors = {
      'פלסטיקה': 0xFF10b981,
      'תיאטרון': 0xFF3b82f6,
      'מוזיקה': 0xFF8b5cf6,
      'כתיבה': 0xFFf59e0b,
      'אנימציה': 0xFFef4444,
      'וידאו': 0xFF06b6d4,
      'כללי': 0xFF6b7280,
    };

    for (final lesson in lessons) {
      final studio = _extractStudioFromLesson(lesson);
      final attendedCount = lesson.attendanceRecords
          .where((r) => r.status == 'present' || r.status == 'late')
          .length;
      studioParticipation[studio] =
          (studioParticipation[studio] ?? 0) + attendedCount;
    }

    if (studioParticipation.isEmpty) return [];

    final total = studioParticipation.values.reduce((a, b) => a + b);

    return studioParticipation.entries.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return {
        'name': entry.key,
        'value': percentage,
        'absoluteValue': entry.value,
        'color': studioColors[entry.key] ?? 0xFF6b7280,
      };
    }).toList()..sort(
      (a, b) => (b['value'] as int).compareTo(a['value'] as int),
    ); // ✅ FIXED: Added explicit cast
  }

  /// Calculate real attendance trends over time
  Future<List<Map<String, dynamic>>> _calculateAttendanceTrends(
    List<Lesson> lessons,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final trends = <Map<String, dynamic>>[];
    final daysDiff = endDate.difference(startDate).inDays;
    final interval = daysDiff > 60
        ? 7
        : 1; // Weekly if > 2 months, daily otherwise

    for (int i = 0; i < daysDiff; i += interval) {
      final date = startDate.add(Duration(days: i));
      final periodEnd = startDate.add(Duration(days: i + interval - 1));

      final periodLessons = lessons
          .where(
            (lesson) =>
                lesson.date.isAfter(date.subtract(const Duration(days: 1))) &&
                lesson.date.isBefore(periodEnd.add(const Duration(days: 1))),
          )
          .toList();

      int totalAttendance = 0;
      int totalPossible = 0;

      for (final lesson in periodLessons) {
        final attended = lesson.attendanceRecords
            .where((r) => r.status == 'present' || r.status == 'late')
            .length;
        totalAttendance += attended;
        totalPossible += lesson.registeredArtistIds.length;
      }

      final attendanceRate = totalPossible > 0
          ? (totalAttendance / totalPossible) * 100
          : 0.0;

      trends.add({
        'date': date,
        'attendanceRate': attendanceRate,
        'totalAttendance': totalAttendance,
        'totalLessons': periodLessons.length,
        'label': interval == 7
            ? 'שבוע ${(i / 7 + 1).round()}'
            : '${date.day}/${date.month}',
      });
    }

    return trends;
  }

  /// Get real top performing artists
  Future<List<Map<String, dynamic>>> _getTopPerformingArtists(
    List<User> artists,
    List<Lesson> lessons,
  ) async {
    final artistPerformance = <String, Map<String, dynamic>>{};

    // Initialize all artists
    for (final artist in artists) {
      artistPerformance[artist.id] = {
        'artist': artist,
        'totalLessons': 0,
        'attendedLessons': 0,
        'attendanceRate': 0.0,
      };
    }

    // Calculate real performance
    for (final lesson in lessons) {
      for (final record in lesson.attendanceRecords) {
        if (artistPerformance.containsKey(record.artistId)) {
          // ✅ FIXED: Safe null check and increment
          final performance = artistPerformance[record.artistId]!;
          performance['totalLessons'] =
              (performance['totalLessons'] as int) + 1;

          if (record.status == 'present' || record.status == 'late') {
            performance['attendedLessons'] =
                (performance['attendedLessons'] as int) + 1;
          }
        }
      }
    }

    // Calculate attendance rates
    for (final performance in artistPerformance.values) {
      final total = performance['totalLessons'] as int;
      final attended = performance['attendedLessons'] as int;
      performance['attendanceRate'] = total > 0
          ? (attended / total) * 100
          : 0.0;
    }

    // Sort by attendance rate and return top 10
    final sortedPerformance = artistPerformance.values.toList()
      ..sort(
        (a, b) => (b['attendanceRate'] as double).compareTo(
          a['attendanceRate'] as double,
        ),
      );

    return sortedPerformance.take(10).map((performance) {
      final artist = performance['artist'] as User;
      return {
        'artistId': artist.id,
        'artistName': artist.name,
        'attendanceRate': performance['attendanceRate'],
        'totalLessons': performance['totalLessons'],
        'attendedLessons': performance['attendedLessons'],
      };
    }).toList();
  }

  /// Get artists needing attention (low attendance)
  Future<List<Map<String, dynamic>>> _getArtistsNeedingAttention(
    List<User> artists,
    List<Lesson> lessons,
  ) async {
    final artistPerformance = <String, Map<String, dynamic>>{};

    // Initialize all artists
    for (final artist in artists) {
      artistPerformance[artist.id] = {
        'artist': artist,
        'totalLessons': 0,
        'attendedLessons': 0,
        'attendanceRate': 0.0,
        'lastAttended': null,
      };
    }

    // Calculate real performance
    for (final lesson in lessons) {
      for (final record in lesson.attendanceRecords) {
        if (artistPerformance.containsKey(record.artistId)) {
          // ✅ FIXED: Safe null check and increment
          final performance = artistPerformance[record.artistId]!;
          performance['totalLessons'] =
              (performance['totalLessons'] as int) + 1;

          if (record.status == 'present' || record.status == 'late') {
            performance['attendedLessons'] =
                (performance['attendedLessons'] as int) + 1;
            performance['lastAttended'] = lesson.date;
          }
        }
      }
    }

    // Calculate attendance rates and filter low performers
    final needAttention = <Map<String, dynamic>>[];

    for (final performance in artistPerformance.values) {
      final total = performance['totalLessons'] as int;
      final attended = performance['attendedLessons'] as int;
      final attendanceRate = total > 0 ? (attended / total) * 100 : 0.0;

      // Consider artists needing attention if:
      // 1. Attendance rate < 60% AND they have attended at least 3 lessons
      // 2. OR haven't attended any lesson in the last 2 weeks
      final lastAttended = performance['lastAttended'] as DateTime?;
      final daysSinceLastAttendance = lastAttended != null
          ? DateTime.now().difference(lastAttended).inDays
          : 999;

      if ((attendanceRate < 60 && total >= 3) || daysSinceLastAttendance > 14) {
        final artist = performance['artist'] as User;
        needAttention.add({
          'artistId': artist.id,
          'artistName': artist.name,
          'attendanceRate': attendanceRate,
          'totalLessons': total,
          'attendedLessons': attended,
          'daysSinceLastAttendance': daysSinceLastAttendance,
          'reason': attendanceRate < 60 ? 'נוכחות נמוכה' : 'לא השתתף לאחרונה',
        });
      }
    }

    // ✅ FIXED: Safe comparison with explicit cast
    return needAttention..sort(
      (a, b) => (a['attendanceRate'] as double).compareTo(
        b['attendanceRate'] as double,
      ),
    );
  }

  /// Calculate weekly attendance patterns
  Future<List<Map<String, dynamic>>> _calculateWeeklyPatterns(
    List<Lesson> lessons,
  ) async {
    final weeklyData = List.generate(
      7,
      (index) => {
        'dayOfWeek': _getDayName(index),
        'totalLessons': 0,
        'totalAttendance': 0,
        'averageAttendance': 0.0,
      },
    );

    for (final lesson in lessons) {
      final dayOfWeek = lesson.date.weekday % 7; // Convert to 0-6 (Sunday = 0)
      final attended = lesson.attendanceRecords
          .where((r) => r.status == 'present' || r.status == 'late')
          .length;

      // ✅ FIXED: Safe increment with explicit cast
      final dayData = weeklyData[dayOfWeek];
      dayData['totalLessons'] = (dayData['totalLessons'] as int) + 1;
      dayData['totalAttendance'] =
          (dayData['totalAttendance'] as int) + attended;
    }

    // Calculate averages
    for (final dayData in weeklyData) {
      final totalLessons = dayData['totalLessons'] as int;
      final totalAttendance = dayData['totalAttendance'] as int;
      dayData['averageAttendance'] = totalLessons > 0
          ? totalAttendance / totalLessons
          : 0.0;
    }

    return weeklyData;
  }

  /// Helper method to extract studio from lesson title
  String _extractStudioFromLesson(Lesson lesson) {
    final title = lesson.title.toLowerCase();

    if (title.contains('פלסטיק') ||
        title.contains('ציור') ||
        title.contains('פיסול')) {
      return 'פלסטיקה';
    } else if (title.contains('תיאטרון') ||
        title.contains('משחק') ||
        title.contains('דרמה')) {
      return 'תיאטרון';
    } else if (title.contains('מוזיקה') ||
        title.contains('שירה') ||
        title.contains('נגינה')) {
      return 'מוזיקה';
    } else if (title.contains('כתיבה') || title.contains('ספרות')) {
      return 'כתיבה';
    } else if (title.contains('אנימציה') || title.contains('הנפשה')) {
      return 'אנימציה';
    } else if (title.contains('וידאו') ||
        title.contains('צילום') ||
        title.contains('עריכה')) {
      return 'וידאו';
    }

    return 'כללי';
  }

  /// Helper method to get day name in Hebrew
  String _getDayName(int dayIndex) {
    const dayNames = ['ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת'];
    return dayNames[dayIndex];
  }
}
