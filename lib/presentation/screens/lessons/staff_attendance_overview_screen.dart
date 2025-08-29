import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';
import 'staff_lesson_attendance_view.dart';

class StaffAttendanceOverviewScreen extends ConsumerStatefulWidget {
  const StaffAttendanceOverviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StaffAttendanceOverviewScreen> createState() =>
      _StaffAttendanceOverviewScreenState();
}

class _StaffAttendanceOverviewScreenState
    extends ConsumerState<StaffAttendanceOverviewScreen> {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();

  bool _isLoading = false;
  List<Lesson> _lessons = [];
  DateTime _selectedDate = DateTime.now();
  String _filterStatus = 'all'; // all, today, week, month

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      print('🔍 STAFF DEBUG: Loading lessons from Firestore...');

      // Use getAllLessonsForStaff to get ALL lessons
      final allLessons = await _lessonRepository.getAllLessonsForStaff();
      print('🔍 STAFF DEBUG: Found ${allLessons.length} total lessons');

      // Filter to get lessons from the past 2 months to next month (wider range)
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 60)); // 2 months back
      final endDate = now.add(const Duration(days: 30)); // 1 month forward

      final filteredLessons = allLessons.where((lesson) {
        final isInRange =
            lesson.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            lesson.date.isBefore(endDate.add(const Duration(days: 1)));

        if (isInRange) {
          print(
            '🔍 STAFF DEBUG: Including lesson "${lesson.title}" from ${lesson.date}',
          );
        }

        return isInRange;
      }).toList();

      print(
        '🔍 STAFF DEBUG: Filtered to ${filteredLessons.length} lessons in date range',
      );

      // Debug attendance records
      for (var lesson in filteredLessons) {
        print(
          '🔍 STAFF DEBUG: Lesson "${lesson.title}" has ${lesson.attendanceRecords.length} attendance records',
        );
        for (var record in lesson.attendanceRecords) {
          print(
            '🔍 STAFF DEBUG: - Record: ${record.artistId} = ${record.status}',
          );
        }
      }

      // Sort by date (newest first)
      filteredLessons.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _lessons = filteredLessons;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔍 STAFF DEBUG: Error loading lessons: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת שיעורים: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          'צפייה בנוכחות',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _loadLessons(); // Manually refresh lessons
            },
            icon: const Icon(Icons.refresh, color: Color(0xFF6b7280)),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('כל השיעורים')),
              const PopupMenuItem(value: 'today', child: Text('היום')),
              const PopupMenuItem(value: 'week', child: Text('השבוע')),
              const PopupMenuItem(value: 'month', child: Text('החודש')),
            ],
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.filter_list, color: Color(0xFF6b7280)),
            ),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildContent() {
    final filteredLessons = _getFilteredLessons();

    return Column(
      children: [
        // Summary stats
        _buildSummaryStats(),

        // Lessons list
        Expanded(
          child: filteredLessons.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = filteredLessons[index];
                    return _buildLessonCard(lesson);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats() {
    final filteredLessons = _getFilteredLessons();
    final totalStudents = filteredLessons.fold<int>(
      0,
      (sum, lesson) => sum + lesson.registeredArtistIds.length,
    );
    final totalPresent = filteredLessons.fold<int>(
      0,
      (sum, lesson) =>
          sum +
          lesson.attendanceRecords.where((r) => r.status == 'present').length,
    );
    final attendanceRate = totalStudents > 0
        ? (totalPresent / totalStudents * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  filteredLessons.length.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3b82f6),
                  ),
                ),
                const Text(
                  'שיעורים',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  totalStudents.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8b5cf6),
                  ),
                ),
                const Text(
                  'תלמידים',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$attendanceRate%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10b981),
                  ),
                ),
                const Text(
                  'נוכחות',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    final presentCount = lesson.attendanceRecords
        .where((r) => r.status == 'present')
        .length;
    final totalCount = lesson.registeredArtistIds.length;
    final attendanceRate = totalCount > 0
        ? (presentCount / totalCount * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffLessonAttendanceView(lesson: lesson),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'מנחה: ${lesson.instructorName ?? "לא צוין"}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getAttendanceRateColor(
                          attendanceRate,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$attendanceRate%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getAttendanceRateColor(attendanceRate),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: const Color(0xFF6b7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(lesson.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.people,
                      size: 16,
                      color: const Color(0xFF6b7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$presentCount/$totalCount נוכחים',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Color(0xFF6b7280)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('טוען שיעורים...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: const Color(0xFF6b7280).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'אין שיעורים להצגה',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'נסה לשנות את המסנן או לבדוק שיש שיעורים מתוכננים',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Lesson> _getFilteredLessons() {
    final now = DateTime.now();

    switch (_filterStatus) {
      case 'today':
        return _lessons
            .where(
              (lesson) =>
                  lesson.date.year == now.year &&
                  lesson.date.month == now.month &&
                  lesson.date.day == now.day,
            )
            .toList();
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return _lessons
            .where(
              (lesson) =>
                  lesson.date.isAfter(
                    startOfWeek.subtract(const Duration(days: 1)),
                  ) &&
                  lesson.date.isBefore(endOfWeek.add(const Duration(days: 1))),
            )
            .toList();
      case 'month':
        return _lessons
            .where(
              (lesson) =>
                  lesson.date.year == now.year &&
                  lesson.date.month == now.month,
            )
            .toList();
      default:
        return _lessons;
    }
  }

  Color _getAttendanceRateColor(int rate) {
    if (rate >= 80) return const Color(0xFF10b981);
    if (rate >= 60) return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }
}
