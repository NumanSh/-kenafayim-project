import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/data/models/attendance_record.dart';
import 'package:knafayim_app/services/excel_export_service.dart';
import '../../../data/models/user.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';

class ArtistProfileAnalytics extends ConsumerStatefulWidget {
  final User artist;

  const ArtistProfileAnalytics({super.key, required this.artist});

  @override
  ConsumerState<ArtistProfileAnalytics> createState() =>
      _ArtistProfileAnalyticsState();
}

class _ArtistProfileAnalyticsState extends ConsumerState<ArtistProfileAnalytics>
    with TickerProviderStateMixin {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();

  late TabController _tabController;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  Map<String, dynamic> _artistStats = {};
  List<Map<String, dynamic>> _attendanceData = [];
  List<Lesson> _artistLessons = [];
  bool _isLoading = true;
  String _selectedPeriod = 'month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutCubic,
    );
    _loadArtistData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistData() async {
    setState(() => _isLoading = true);

    try {
      // Get artist lessons in date range
      final allLessons = await _lessonRepository.getAllLessons(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Filter lessons where this artist was registered
      final artistLessons = allLessons
          .where(
            (lesson) => lesson.registeredArtistIds.contains(widget.artist.id),
          )
          .toList();

      // Calculate comprehensive stats
      final stats = _calculateComprehensiveStats(artistLessons);
      final attendanceData = _generateAttendanceData(artistLessons);

      if (mounted) {
        setState(() {
          _artistLessons = artistLessons;
          _artistStats = stats;
          _attendanceData = attendanceData;
          _isLoading = false;
        });
        _chartAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת נתוני אמן: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _calculateComprehensiveStats(List<Lesson> lessons) {
    int totalLessons = lessons.length;
    int attendedLessons = 0;
    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;
    int excusedCount = 0;

    // Studio participation tracking
    final studioStats = <String, int>{};

    // Streak tracking
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    // Sort lessons by date for streak calculation
    final sortedLessons = List<Lesson>.from(lessons)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final lesson in sortedLessons) {
      final record = lesson.attendanceRecords
          .where((r) => r.artistId == widget.artist.id)
          .firstOrNull;

      if (record != null) {
        switch (record.status) {
          case 'present':
            presentCount++;
            attendedLessons++;
            tempStreak++;
            break;
          case 'late':
            lateCount++;
            attendedLessons++;
            tempStreak++;
            break;
          case 'absent':
            absentCount++;
            tempStreak = 0;
            break;
          case 'excused':
            excusedCount++;
            tempStreak = 0;
            break;
        }

        longestStreak = math.max(longestStreak, tempStreak);

        // Track studio participation
        final studio = _getStudioFromLesson(lesson);
        studioStats[studio] = (studioStats[studio] ?? 0) + 1;
      }
    }

    // Calculate current streak from the end
    for (int i = sortedLessons.length - 1; i >= 0; i--) {
      final lesson = sortedLessons[i];
      final record = lesson.attendanceRecords
          .where((r) => r.artistId == widget.artist.id)
          .firstOrNull;

      if (record != null &&
          (record.status == 'present' || record.status == 'late')) {
        currentStreak++;
      } else {
        break;
      }
    }

    final attendanceRate = totalLessons > 0
        ? (attendedLessons / totalLessons) * 100
        : 0.0;
    final lateRate = totalLessons > 0 ? (lateCount / totalLessons) * 100 : 0.0;

    return {
      'totalLessons': totalLessons,
      'attendedLessons': attendedLessons,
      'presentCount': presentCount,
      'lateCount': lateCount,
      'absentCount': absentCount,
      'excusedCount': excusedCount,
      'attendanceRate': attendanceRate,
      'lateRate': lateRate,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'favoriteStudio': _getFavoriteStudio(studioStats),
      'studioStats': studioStats,
      'averageLessonsPerWeek': totalLessons / 4,
      'activityStatus': _getActivityStatus(attendanceRate),
    };
  }

  String _getActivityStatus(double attendanceRate) {
    if (attendanceRate >= 95) return 'פעיל מאוד';
    if (attendanceRate >= 85) return 'פעיל';
    if (attendanceRate >= 70) return 'בינוני';
    if (attendanceRate >= 50) return 'זקוק לעידוד';
    return 'זקוק לתשומת לב';
  }

  String _getStudioFromLesson(Lesson lesson) {
    final title = lesson.title.toLowerCase();
    if (title.contains('פלסטיק') ||
        title.contains('ציור') ||
        title.contains('פיסול')) {
      return 'פלסטיקה';
    } else if (title.contains('תיאטרון') || title.contains('משחק')) {
      return 'תיאטרון';
    } else if (title.contains('מוזיקה') || title.contains('שירה')) {
      return 'מוזיקה';
    } else if (title.contains('כתיבה') || title.contains('ספרות')) {
      return 'כתיבה';
    } else if (title.contains('אנימציה') || title.contains('הנפשה')) {
      return 'אנימציה';
    } else if (title.contains('וידאו') || title.contains('צילום')) {
      return 'וידאו';
    }
    return 'כללי';
  }

  String _getFavoriteStudio(Map<String, int> studioStats) {
    if (studioStats.isEmpty) return 'אין נתונים';
    return studioStats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<Map<String, dynamic>> _generateAttendanceData(List<Lesson> lessons) {
    final data = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));

      final weekLessons = lessons
          .where(
            (lesson) =>
                lesson.date.isAfter(weekStart) && lesson.date.isBefore(weekEnd),
          )
          .toList();

      final weekAttended = weekLessons.where((lesson) {
        final record = lesson.attendanceRecords
            .where((r) => r.artistId == widget.artist.id)
            .firstOrNull;
        return record != null &&
            (record.status == 'present' || record.status == 'late');
      }).length;

      final attendanceRate = weekLessons.isNotEmpty
          ? (weekAttended.toDouble() / weekLessons.length.toDouble()) * 100.0
          : 0.0;

      data.add({
        'week': 'שבוע ${4 - i}',
        'total': weekLessons.length,
        'attended': weekAttended,
        'rate': attendanceRate,
        'lessons': weekLessons.map((l) => l.title).toList(),
      });
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildDetailsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: Text(
        'פרופיל אמן - ${widget.artist.name}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1f2937),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _exportArtistReport,
          icon: const Icon(Icons.download, color: Color(0xFF3b82f6)),
          tooltip: 'ייצא דוח אמן',
        ),
        IconButton(
          onPressed: _loadArtistData,
          icon: const Icon(Icons.refresh, color: Color(0xFF3b82f6)),
          tooltip: 'רענן נתונים',
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('שבוע', 'week'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('חודש', 'month'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('רבעון', 'quarter'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('שנה', 'year'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: _showDateRangePicker,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFe5e7eb)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.date_range,
                    size: 16,
                    color: Color(0xFF6b7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _updateDateRangeForPeriod(period);
        });
        _loadArtistData();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3b82f6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3b82f6)
                : const Color(0xFFe5e7eb),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6b7280),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF3b82f6),
        unselectedLabelColor: const Color(0xFF6b7280),
        indicatorColor: const Color(0xFF3b82f6),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard, size: 20), text: 'סקירה'),
          Tab(icon: Icon(Icons.bar_chart, size: 20), text: 'תרשימים'),
          Tab(icon: Icon(Icons.list_alt, size: 20), text: 'פירוט'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3b82f6)),
            ),
            SizedBox(height: 16),
            Text(
              'טוען נתוני אמן...',
              style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArtistHeader(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildQuickInsights(),
          const SizedBox(height: 24),
          _buildFavoriteStudioCard(),
        ],
      ),
    );
  }

  Widget _buildArtistHeader() {
    final attendanceRate = (_artistStats['attendanceRate'] as double?) ?? 0.0;
    final activityStatus =
        _artistStats['activityStatus'] as String? ?? 'לא ידוע';

    Color statusColor;
    if (attendanceRate >= 90) {
      statusColor = const Color(0xFF10b981);
    } else if (attendanceRate >= 75) {
      statusColor = const Color(0xFF3b82f6);
    } else if (attendanceRate >= 60) {
      statusColor = const Color(0xFFf59e0b);
    } else {
      statusColor = const Color(0xFFef4444);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor, statusColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                widget.artist.name.isNotEmpty
                    ? widget.artist.name[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.artist.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.artist.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activityStatus,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10b981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+12%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10b981),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount = 2;
        double childAspectRatio = 1.0;
        double crossAxisSpacing = 12;
        double mainAxisSpacing = 12;

        if (screenWidth > 600) {
          crossAxisCount = 4;
          childAspectRatio = 0.9;
          crossAxisSpacing = 16;
          mainAxisSpacing = 16;
        }

        return SizedBox(
          height: 340,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
            children: [
              _buildStatCard(
                'סה"כ שיעורים',
                '${_artistStats['totalLessons'] ?? 0}',
                'שיעורים רשומים',
                Icons.school,
                const Color(0xFF3b82f6),
                '+5%',
              ),
              _buildStatCard(
                'נוכחות',
                '${_artistStats['attendedLessons'] ?? 0}',
                'שיעורים השתתף',
                Icons.check_circle,
                const Color(0xFF10b981),
                '+12%',
              ),
              _buildStatCard(
                'אחוז נוכחות',
                '${(_artistStats['attendanceRate'] as double?)?.toStringAsFixed(1) ?? '0.0'}%',
                'מהשיעורים',
                Icons.trending_up,
                const Color(0xFFf59e0b),
                '+8%',
              ),
              _buildStatCard(
                'רצף נוכחות',
                '${_artistStats['currentStreak'] ?? 0}',
                'שיעורים ברצף',
                Icons.local_fire_department,
                const Color(0xFF8b5cf6),
                '+15%',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10b981),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6b7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9ca3af),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    final longestStreak = _artistStats['longestStreak'] ?? 0;
    final favoriteStudio = _artistStats['favoriteStudio'] ?? 'אין נתונים';
    final lateRate = (_artistStats['lateRate'] as double?) ?? 0.0;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'תובנות מהירות',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'הסטודיו המועדף',
            favoriteStudio,
            Icons.favorite,
            const Color(0xFF8b5cf6),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'רצף הכי ארוך',
            '$longestStreak שיעורים ברצף',
            Icons.local_fire_department,
            const Color(0xFFf59e0b),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'אחוז איחורים',
            '${lateRate.toStringAsFixed(1)}% מהשיעורים',
            Icons.access_time,
            lateRate > 10 ? const Color(0xFFef4444) : const Color(0xFF10b981),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteStudioCard() {
    final studioStats = _artistStats['studioStats'] as Map<String, int>? ?? {};

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'התפלגות סטודיואים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          if (studioStats.isEmpty)
            const Text('אין נתונים זמינים')
          else
            ...studioStats.entries
                .take(3)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStudioColor(entry.key),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} שיעורים',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6b7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  Color _getStudioColor(String studio) {
    switch (studio) {
      case 'פלסטיקה':
        return const Color(0xFF10b981);
      case 'תיאטרון':
        return const Color(0xFF3b82f6);
      case 'מוזיקה':
        return const Color(0xFF8b5cf6);
      case 'כתיבה':
        return const Color(0xFFf59e0b);
      case 'אנימציה':
        return const Color(0xFFef4444);
      case 'וידאו':
        return const Color(0xFF06b6d4);
      default:
        return const Color(0xFF6b7280);
    }
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAttendanceChart(),
          const SizedBox(height: 24),
          _buildStudioDistributionChart(),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return Container(
      height: 300,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'מגמת נוכחות שבועית',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() < _attendanceData.length) {
                              return Text(
                                _attendanceData[value.toInt()]['week'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF6b7280),
                                  fontSize: 10,
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFF6b7280),
                                fontSize: 10,
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _attendanceData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final rate = (data['rate'] as double?) ?? 0.0;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: rate * _chartAnimation.value,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10b981), Color(0xFF059669)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioDistributionChart() {
    final studioStats = _artistStats['studioStats'] as Map<String, int>? ?? {};

    if (studioStats.isEmpty) {
      return Container(
        height: 300,
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
        child: const Center(
          child: Text(
            'אין נתוני סטודיואים זמינים',
            style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
          ),
        ),
      );
    }

    final total = studioStats.values.reduce((a, b) => a + b);
    final studioData = studioStats.entries.map((entry) {
      return {
        'name': entry.key,
        'value': ((entry.value / total) * 100).round(),
        'color': _getStudioColor(entry.key).value,
      };
    }).toList();

    return Container(
      height: 300,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'התפלגות סטודיואים',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, child) {
                      return PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: studioData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            final isTouched = index == _touchedIndex;
                            final fontSize = isTouched ? 16.0 : 12.0;
                            final radius = isTouched ? 80.0 : 70.0;

                            return PieChartSectionData(
                              color: Color(data['color'] as int),
                              value:
                                  (data['value'] as num).toDouble() *
                                  _chartAnimation.value,
                              title: '${data['value']}%',
                              radius: radius,
                              titleStyle: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: studioData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(data['color'] as int),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['name'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: index == _touchedIndex
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: const Color(0xFF1f2937),
                                ),
                              ),
                            ),
                            Text(
                              '${data['value']}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: index == _touchedIndex
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: const Color(0xFF6b7280),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAttendanceBreakdown(),
          const SizedBox(height: 24),
          _buildRecentLessonsCard(),
        ],
      ),
    );
  }

  Widget _buildAttendanceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'פירוט נוכחות לפי שבועות',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 16),
          ...(_attendanceData.map((data) => _buildWeekItem(data)).toList()),
        ],
      ),
    );
  }

  Widget _buildWeekItem(Map<String, dynamic> data) {
    final rate = (data['rate'] as double?) ?? 0.0;
    final attended = data['attended'] as int;
    final total = data['total'] as int;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              data['week'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6b7280),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: rate / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10b981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$attended/$total (${rate.toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1f2937),
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLessonsCard() {
    final recentLessons = _artistLessons.take(10).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF10b981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'שיעורים אחרונים',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentLessons.isEmpty)
            const Text(
              'אין שיעורים אחרונים',
              style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            )
          else
            ...recentLessons.map((lesson) => _buildLessonItem(lesson)).toList(),
        ],
      ),
    );
  }

  Widget _buildLessonItem(Lesson lesson) {
    final record = lesson.attendanceRecords
        .where((r) => r.artistId == widget.artist.id)
        .firstOrNull;

    final attended = record?.status == 'present' || record?.status == 'late';
    final status = record?.status ?? 'לא ידוע';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'present':
        statusColor = const Color(0xFF10b981);
        statusText = 'נכח';
        break;
      case 'late':
        statusColor = const Color(0xFFf59e0b);
        statusText = 'איחור';
        break;
      case 'absent':
        statusColor = const Color(0xFFef4444);
        statusText = 'נעדר';
        break;
      case 'excused':
        statusColor = const Color(0xFF8b5cf6);
        statusText = 'מוצדק';
        break;
      default:
        statusColor = const Color(0xFF6b7280);
        statusText = 'לא ידוע';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1f2937),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(lesson.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                    if (lesson.isRecurring) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8b5cf6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'חוזר',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8b5cf6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _exportArtistReport,
      backgroundColor: const Color(0xFF10b981),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.download),
      label: const Text('ייצא דוח אמן'),
    );
  }

  // Helper methods
  void _updateDateRangeForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'week':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'quarter':
        _startDate = now.subtract(const Duration(days: 90));
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
    }
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF10b981)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'custom';
      });
      _loadArtistData();
    }
  }

  void _exportArtistReport() async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('מייצא דוח עבור ${widget.artist.name}...'),
            ],
          ),
          backgroundColor: const Color(0xFF10b981),
          duration: const Duration(seconds: 3),
        ),
      );

      final excelService = serviceLocator<ExcelExportService>();

      // ✅ FIXED: Use the individual artist export method
      final result = await excelService.saveIndividualArtistExcelToDevice(
        artist: widget.artist,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: const Color(0xFF10b981),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'פתח תיקייה',
              textColor: Colors.white,
              onPressed: () {
                // Could open file manager here
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בייצוא דוח אמן: $e'),
            backgroundColor: const Color(0xFFef4444),
            action: SnackBarAction(
              label: 'נסה שוב',
              textColor: Colors.white,
              onPressed: _exportArtistReport,
            ),
          ),
        );
      }
    }
  }
}
