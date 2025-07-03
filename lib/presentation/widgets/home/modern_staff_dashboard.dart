import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/data/models/enhanced_notification.dart';
import 'package:knafayim_app/data/models/lesson.dart';
import 'package:knafayim_app/data/repositories/lesson_repository.dart';
import 'package:knafayim_app/presentation/providers/working_hours_providers.dart';
import 'package:knafayim_app/presentation/screens/lessons/create_recurring_lesson_screen.dart';
import 'package:knafayim_app/presentation/screens/lessons/staff_attendance_overview_screen.dart';
import 'package:knafayim_app/presentation/widgets/home/enhanced_analytics_section.dart';
import 'package:knafayim_app/presentation/widgets/hours/staff_hours_approval_screen.dart';
import 'package:knafayim_app/presentation/widgets/lessons/lesson_creation_form.dart';
import 'package:knafayim_app/presentation/widgets/lessons/lesson_details_modal.dart';
import 'package:knafayim_app/presentation/widgets/messages/enhanced_message_composer.dart';
import 'package:knafayim_app/presentation/widgets/messages/message_composer_modal.dart';
import 'package:knafayim_app/services/enhanced_notification_service.dart';
import 'package:knafayim_app/services/notification_integration_service.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/unified_calendar_repository.dart';
import '../../../config/service_locator.dart';
import '../../providers/lesson_providers.dart';

class ModernStaffDashboard extends ConsumerStatefulWidget {
  final User user;

  const ModernStaffDashboard({super.key, required this.user});

  @override
  ConsumerState<ModernStaffDashboard> createState() =>
      _ModernStaffDashboardState();
}

class _ModernStaffDashboardState extends ConsumerState<ModernStaffDashboard> {
  final UnifiedCalendarRepository _unifiedRepository =
      serviceLocator<UnifiedCalendarRepository>();

  // Repository-based approach
  List<Lesson> _allLessons = [];
  bool _isLoadingLessons = true;
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();

  // Statistics variables
  final int _artistsCount = 25;
  final int _mentorsCount = 12;
  final int _eventsThisMonth = 8;
  final int _meetingsThisWeek = 5;

  @override
  void initState() {
    super.initState();
    _loadAllLessons();
  }

  Future<void> _loadDashboardData() async {
    // Refresh dashboard statistics
    if (mounted) {
      setState(() {
        // Trigger rebuild to refresh data
      });
    }
  }

  Future<void> _loadAllLessons() async {
    if (!mounted) return;
    setState(() => _isLoadingLessons = true);
    try {
      final lessons = await _lessonRepository.getAllLessons(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      if (mounted) {
        setState(() {
          _allLessons = lessons;
          _isLoadingLessons = false;
        });
        print('✅ STAFF: Loaded ${lessons.length} lessons via repository');
        for (int i = 0; i < lessons.length; i++) {
          print('   ${i + 1}. ${lessons[i].title} - ${lessons[i].date}');
        }
      }
    } catch (e) {
      print('❌ STAFF: Error loading lessons: $e');
      if (mounted) {
        setState(() => _isLoadingLessons = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת שיעורים: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventDialog,
        backgroundColor: const Color(0xFF3b82f6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'אירוע חדש',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAllLessons();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSimpleMessageContainer(),
              const SizedBox(height: 32),
              // 2. Upcoming lessons
              _buildUpcomingLessonsSection(context),
              const SizedBox(height: 32),
              // 3. Recent reports
              _buildRecentReportsSection(context),
              const SizedBox(height: 32),
              // 4. Enhanced statistics
              _buildEnhancedStatisticsSection(context),
              const SizedBox(height: 100),
              EnhancedAnalyticsSection(user: widget.user),

              // Add this button somewhere in your staff dashboard for testing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingLessonsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF10b981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'שיעורים קרובים',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1f2937),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildManagementButton(
                  context,
                  'יצירת שיעור חדש',
                  Icons.add_circle_outline,
                  const Color(0xFF10b981),
                  () => _showAddLessonDialog(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingLessons)
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF10b981),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'טוען שיעורים...',
                    style: TextStyle(
                      color: Color(0xFF6b7280),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_allLessons.isEmpty)
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 48,
                    color: Color(0xFF9ca3af),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'אין שיעורים זמינים',
                    style: TextStyle(
                      color: Color(0xFF6b7280),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'צור שיעור חדש כדי להתחיל',
                    style: TextStyle(color: Color(0xFF9ca3af), fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _allLessons.length,
              itemBuilder: (context, index) {
                final lesson = _allLessons[index];
                return _buildLessonCard(
                  context,
                  lesson,
                  index,
                  key: ValueKey('lesson_${lesson.id}_$index'),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    Lesson lesson,
    int index, {
    Key? key,
  }) {
    final colors = [
      const Color(0xFF3b82f6),
      const Color(0xFF8b5cf6),
      const Color(0xFF06b6d4),
      const Color(0xFF10b981),
    ];

    final bool hasValidImage =
        lesson.backgroundImagePath != null &&
        File(lesson.backgroundImagePath!).existsSync();

    return Container(
      key: key,
      width: 180,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showLessonDetailsWithActualLesson(context, lesson),
          onLongPress: () => _showLessonOptionsBottomSheet(
            context,
            lesson,
          ), // ✅ NEW: Long press for options
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 108,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      image: hasValidImage
                          ? DecorationImage(
                              image: FileImage(
                                File(lesson.backgroundImagePath!),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: !hasValidImage
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors[index % colors.length].withOpacity(0.1),
                                colors[index % colors.length].withOpacity(0.2),
                              ],
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        if (hasValidImage)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        Center(
                          child: Icon(
                            _getIconForLesson('lesson'),
                            size: 48,
                            color: hasValidImage
                                ? Colors.white
                                : colors[index % colors.length],
                          ),
                        ),
                        // ✅ NEW: Quick delete button
                        Positioned(
                          top: 8,
                          left: 8,
                          child: InkWell(
                            onTap: () =>
                                _showDeleteConfirmation(context, lesson),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1f2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.instructorName ?? 'לא צוין',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors[index % colors.length],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Show lesson options bottom sheet
  void _showLessonOptionsBottomSheet(BuildContext context, Lesson lesson) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFe5e7eb),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildOptionTile(
                    'הצג פרטים',
                    Icons.info_outline,
                    const Color(0xFF3b82f6),
                    () {
                      Navigator.pop(context);
                      _showLessonDetailsWithActualLesson(context, lesson);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildOptionTile(
                    'מחק שיעור',
                    Icons.delete_outline,
                    const Color(0xFFef4444),
                    () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, lesson);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, Lesson lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת שיעור'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('האם אתה בטוח שברצונך למחוק את השיעור "${lesson.title}"?'),
            const SizedBox(height: 8),
            Text(
              'תאריך: ${DateFormat('dd/MM/yyyy HH:mm').format(lesson.date)}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            ),
            if (lesson.instructorName != null) ...[
              const SizedBox(height: 4),
              Text(
                'מנחה: ${lesson.instructorName}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFfef2f2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFfecaca)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Color(0xFFef4444), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'פעולה זו אינה ניתנת לביטול',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFef4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteLesson(lesson);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Delete lesson with real-time updates
  Future<void> _deleteLesson(Lesson lesson) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('מוחק שיעור...'),
              ],
            ),
            backgroundColor: Color(0xFF6b7280),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Delete via lesson repository
      final lessonRepository = serviceLocator<LessonRepository>();
      final success = await lessonRepository.deleteLesson(lesson.id);

      if (success && mounted) {
        // ✅ Force refresh unified calendar data
        final unifiedRepository = serviceLocator<UnifiedCalendarRepository>();
        unifiedRepository.clearUserCache(widget.user.id);

        try {
          await unifiedRepository.getUnifiedCalendarItems(
            userId: widget.user.id,
            userRole: widget.user.role,
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now().add(const Duration(days: 365)),
            forceRefresh: true,
          );
        } catch (e) {
          print('Error refreshing calendar after deletion: $e');
        }

        // ✅ Update local dashboard lessons immediately
        setState(() {
          _allLessons.removeWhere((l) => l.id == lesson.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('השיעור "${lesson.title}" נמחק בהצלחה!'),
              ],
            ),
            backgroundColor: const Color(0xFF10b981),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה במחיקת השיעור'),
            backgroundColor: Color(0xFFef4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה במחיקת השיעור: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  Widget _buildOptionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFe5e7eb)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6b7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFf59e0b).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFFf59e0b),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'דוחות אחרונים',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildReportCard(
                context,
                'דוח ינואר 2024',
                'נוצר ב-15.01.2024',
                Icons.description,
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                context,
                'דוח דצמבר 2023',
                'נוצר ב-15.12.2023',
                Icons.description,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String date,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showReportDetails(context, title);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3b82f6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF3b82f6), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF6b7280),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatisticsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8b5cf6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF8b5cf6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'סטטיסטיקות מערכת',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedStatCard(
                      title: 'אמנים פעילים',
                      value: _artistsCount.toString(),
                      icon: Icons.people_outline,
                      color: const Color(0xFF3b82f6),
                      trend: '+12%',
                      isPositive: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEnhancedStatCard(
                      title: 'מנחים',
                      value: _mentorsCount.toString(),
                      icon: Icons.person_outline,
                      color: const Color(0xFF10b981),
                      trend: '+5%',
                      isPositive: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedStatCard(
                      title: 'אירועים החודש',
                      value: _eventsThisMonth.toString(),
                      icon: Icons.event_outlined,
                      color: const Color(0xFFf59e0b),
                      trend: '+25%',
                      isPositive: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEnhancedStatCard(
                      title: 'פגישות השבוע',
                      value: _meetingsThisWeek.toString(),
                      icon: Icons.calendar_today_outlined,
                      color: const Color(0xFF8b5cf6),
                      trend: '-8%',
                      isPositive: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMessageContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.campaign,
                  color: Color(0xFF3b82f6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'מרכז תקשורת',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showMessageComposerModal(context),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3b82f6),
                              const Color(0xFF3b82f6).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            widget.user.name.isNotEmpty
                                ? widget.user.name[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'כתיבת הודעה חדשה...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6b7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'שלח עדכונים לצוות ולמשתתפים',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF6b7280).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3b82f6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Color(0xFF3b82f6),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageComposerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return MessageComposerModal(
            user: widget.user,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  Widget _buildEnhancedStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF10b981).withOpacity(0.1)
                        : const Color(0xFFef4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: isPositive
                            ? const Color(0xFF10b981)
                            : const Color(0xFFef4444),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPositive
                              ? const Color(0xFF10b981)
                              : const Color(0xFFef4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6b7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForLesson(String type) {
    switch (type) {
      case 'painting':
        return Icons.brush;
      case 'sculpture':
        return Icons.architecture;
      case 'pottery':
        return Icons.circle_outlined;
      case 'digital':
        return Icons.computer;
      default:
        return Icons.art_track;
    }
  }

  void _showLessonDetailsWithActualLesson(BuildContext context, Lesson lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonDetailsModal(
        lesson: lesson,
        currentUser: widget.user,
        user: widget.user,
        isRegistered: true,
      ),
    );
  }

  void _showAddLessonDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLessonCreationForm(),
    );
  }

  Widget _buildLessonCreationForm() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: LessonCreationForm(
            user: widget.user,
            scrollController: scrollController,
            onLessonCreated: () async {
              Navigator.pop(context);

              // ✅ Wait a moment for the lesson to be saved
              await Future.delayed(const Duration(milliseconds: 1000));

              // ✅ Invalidate calendar cache to trigger refresh
              final unifiedRepository =
                  serviceLocator<UnifiedCalendarRepository>();
              unifiedRepository.clearUserCache(widget.user.id);

              // Reload dashboard lessons
              await _loadAllLessons();

              // ✅ Force refresh unified calendar data
              try {
                await unifiedRepository.getUnifiedCalendarItems(
                  userId: widget.user.id,
                  userRole: widget.user.role,
                  startDate: DateTime.now().subtract(const Duration(days: 30)),
                  endDate: DateTime.now().add(const Duration(days: 365)),
                  forceRefresh: true,
                );
              } catch (e) {
                print('Error refreshing calendar: $e');
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('השיעור נוצר בהצלחה! התראות נשלחו למשתתפים'),
                      ],
                    ),
                    backgroundColor: Color(0xFF10b981),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  void _showCreateEventDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFe5e7eb),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'צור אירוע חדש',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildCreateOptionTile(
                      'שיעור חדש',
                      'צור שיעור עם מנחה ותלמידים',
                      Icons.school,
                      const Color(0xFF3b82f6),
                      () {
                        Navigator.pop(context);
                        _showAddLessonDialog(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCreateOptionTile(
                      'אירוע כללי',
                      'פגישה, טיפול או אירוע אחר',
                      Icons.event,
                      const Color(0xFF10b981),
                      () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('יצירת אירוע כללי תהיה זמינה בקרוב'),
                            backgroundColor: Color(0xFF10b981),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOptionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFe5e7eb)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6b7280)),
          ],
        ),
      ),
    );
  }

  void _showReportDetails(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('פתיחת דוח: $title'),
        backgroundColor: const Color(0xFF3b82f6),
      ),
    );
  }

  // ✅ ADD THIS METHOD to integrate notifications with lesson creation
}
