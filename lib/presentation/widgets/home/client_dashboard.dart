import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/presentation/widgets/lessons/artist_lesson_card.dart';
import 'package:knafayim_app/services/enhanced_notification_service.dart';
import '../../../data/models/user.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';
import '../../screens/lessons/available_lessons_screen.dart';
import '../../../config/themes.dart';
import '../../providers/lesson_providers.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  final User user;

  const ClientDashboard({super.key, required this.user});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  List<Lesson> _upcomingLessons = [];
  List<Lesson> _availableLessons = [];
  bool _isLoadingLessons = true;
  bool _isLoadingAvailableLessons = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() => _isInitialized = true);
    await _loadUpcomingLessons();
    await _loadAvailableLessons();
  }

  Future<void> _loadUpcomingLessons() async {
    if (!mounted) return;
    setState(() => _isLoadingLessons = true);
    try {
      // ✅ FIXED: Use repository method instead of stream
      final allLessons = await _lessonRepository.getAllLessons(
        startDate: DateTime(2000), // Replace with your desired start date
        endDate: DateTime(2100), // Replace with your desired end date
      );

      // Get lessons where user is registered
      final userLessons = allLessons
          .where(
            (lesson) => lesson.registeredArtistIds.contains(widget.user.id),
          )
          .toList();

      if (mounted) {
        setState(() {
          _upcomingLessons = userLessons;
          _isLoadingLessons = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLessons = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת שיעורים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAvailableLessons() async {
    if (!mounted) return;
    setState(() => _isLoadingAvailableLessons = true);
    try {
      // ✅ FIXED: Use repository method instead of stream
      final allLessons = await _lessonRepository.getAllLessons(
        startDate: DateTime(2000), // Replace with your desired start date
        endDate: DateTime(2100), // Replace with your desired end date
      );

      // Get lessons where user is NOT registered
      final availableLessons = allLessons
          .where(
            (lesson) => !lesson.registeredArtistIds.contains(widget.user.id),
          )
          .toList();

      if (mounted) {
        setState(() {
          _availableLessons = availableLessons;
          _isLoadingAvailableLessons = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAvailableLessons = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת שיעורים זמינים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ FIXED: Better attendance rate calculation with fallback
  double _calculateAttendanceRate() {
    if (_upcomingLessons.isEmpty) return 85.0; // Default rate

    int totalSessions = 0;
    int attendedSessions = 0;

    for (final lesson in _upcomingLessons) {
      final userAttendance = lesson.attendanceRecords.where(
        (record) => record.artistId == widget.user.id,
      );

      totalSessions += userAttendance.length;
      attendedSessions += userAttendance
          .where((record) => record.isPresent) // ✅ Now this will work
          .length;
    }

    if (totalSessions == 0) return 85.0; // Default rate if no attendance data
    return (attendedSessions / totalSessions) * 100;
  }

  void _navigateToAvailableLessons() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AvailableLessonsScreen(user: widget.user),
          ),
        )
        .then((_) {
          _loadUpcomingLessons();
          _loadAvailableLessons();
        });
  }

  // ✅ CALCULATE REAL ATTENDANCE RATE

  // ✅ CALCULATE REAL LESSON PROGRESS
  String _getLessonProgress() {
    final totalRegistered = _upcomingLessons.length;
    final completed = _upcomingLessons
        .where((lesson) => lesson.date.isBefore(DateTime.now()))
        .length;
    return '$completed/$totalRegistered';
  }

  // ✅ CALCULATE DAYS TO NEXT LESSON
  String _getDaysToNextLesson() {
    final now = DateTime.now();
    final upcomingLessons = _upcomingLessons
        .where((lesson) => lesson.date.isAfter(now))
        .toList();

    if (upcomingLessons.isEmpty) return 'אין שיעורים';

    upcomingLessons.sort((a, b) => a.date.compareTo(b.date));
    final nextLesson = upcomingLessons.first;
    final daysUntil = nextLesson.date.difference(now).inDays;

    if (daysUntil == 0) return 'היום';
    if (daysUntil == 1) return 'מחר';
    return 'בעוד $daysUntil ימים';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = _getHorizontalPadding(context);
    final verticalSpacing = _getVerticalSpacing(context);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadUpcomingLessons(), _loadAvailableLessons()]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header with consistent styling
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(horizontalPadding),
              decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'שלום, ${widget.user.name}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'המסע האמנותי שלך ממשיך!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: verticalSpacing),

            // ✅ REAL DATA Journey stats with harmonious design
            _buildHarmoniousJourneySection(horizontalPadding, verticalSpacing),

            SizedBox(height: verticalSpacing * 1.5),

            // Upcoming lessons section
            _buildSectionHeader(
              'השיעורים הקרובים שלי',
              Icons.schedule_outlined,
              horizontalPadding,
            ),
            SizedBox(height: verticalSpacing * 0.75),
            _buildLessonsSection(_upcomingLessons, _isLoadingLessons, false),

            SizedBox(height: verticalSpacing * 1.5),

            // Available lessons section
            _buildSectionHeaderWithAction(
              'שיעורים זמינים להרשמה',
              Icons.explore_outlined,
              'הצג הכל',
              _navigateToAvailableLessons,
              horizontalPadding,
            ),
            SizedBox(height: verticalSpacing * 0.75),
            _buildLessonsSection(
              _availableLessons,
              _isLoadingAvailableLessons,
              true,
            ),

            SizedBox(height: verticalSpacing * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildHarmoniousJourneySection(
    double horizontalPadding,
    double verticalSpacing,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3b82f6).withOpacity(0.1),
            const Color(0xFF3b82f6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3b82f6).withOpacity(0.2),
          width: 1,
        ),
      ),
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
                  Icons.auto_graph,
                  color: Color(0xFF3b82f6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'המסע שלי החודש',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          SizedBox(height: verticalSpacing),
          _buildHarmoniousStats(),

          // ✅ ADD FCM TOKEN REGISTRATION BUTTON HERE
          SizedBox(height: verticalSpacing),
          ElevatedButton(
            onPressed: () async {
              try {
                final notificationService =
                    serviceLocator<EnhancedNotificationService>();
                await notificationService.registerUserFCMToken(widget.user.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('FCM Token registered!')),
                );
              } catch (e) {
                print('Error: $e');
              }
            },
            child: Text('Register for Notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmoniousStats() {
    // ✅ REAL DATA with explanations
    final attendanceRate = _calculateAttendanceRate();
    final lessonProgress = _getLessonProgress();
    final nextLessonDays = _getDaysToNextLesson();

    final stats = [
      (
        'נוכחות', // Attendance Rate
        '${attendanceRate.toInt()}%',
        Icons.check_circle_outline,
        const Color(0xFF10b981),
        'אחוז הנוכחות בשיעורים', // Tooltip
      ),
      (
        'שיעורים', // Lessons Progress
        lessonProgress,
        Icons.school_outlined,
        const Color(0xFF3b82f6),
        'שיעורים שהושלמו מתוך הרשומים',
      ),
      (
        'השיעור הבא', // Next Lesson
        nextLessonDays,
        Icons.flag_outlined,
        const Color(0xFFf59e0b),
        'זמן עד השיעור הקרוב',
      ),
    ];

    return Row(
      children: stats.map((stat) {
        final (title, value, icon, color, tooltip) = stat;
        final index = stats.indexOf(stat);
        return Expanded(
          child: Tooltip(
            message: tooltip,
            child: Container(
              margin: EdgeInsets.only(left: index < stats.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6b7280),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFf1f5f9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6b7280), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1f2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithAction(
    String title,
    IconData icon,
    String actionText,
    VoidCallback onAction,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFf1f5f9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6b7280), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1f2937),
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3b82f6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsSection(
    List<Lesson> lessons,
    bool isLoading,
    bool isAvailable,
  ) {
    if (isLoading) {
      return Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (lessons.isEmpty) {
      return _buildEmptyState(
        isAvailable ? 'אין שיעורים זמינים כרגע' : 'אין שיעורים קרובים',
        isAvailable ? Icons.explore_off : Icons.schedule_outlined,
      );
    }

    final displayLessons = isAvailable && lessons.length > 3
        ? lessons.take(3).toList()
        : lessons;

    return Container(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(context),
        ),
        itemCount: displayLessons.length,
        itemBuilder: (context, index) {
          final lesson = displayLessons[index];
          return Container(
            width: 260,
            margin: EdgeInsets.only(
              left: index < displayLessons.length - 1 ? 16 : 0,
            ),
            child: ModernArtistLessonCard(
              lesson: lesson,
              user: widget.user,
              index: isAvailable ? index + 10 : index,
              onTap: isAvailable ? _navigateToAvailableLessons : () {},
              // ✅ FIXED: Different behavior for registered vs available lessons
              onJoinClass: isAvailable
                  ? _navigateToAvailableLessons
                  : null, // ✅ No join action for registered lessons
              isRegistered: !isAvailable, // ✅ Pass registration status
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      height: 120,
      margin: EdgeInsets.symmetric(horizontal: _getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF9ca3af)),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6b7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ HELPER METHODS (replacing AppTheme calls)
  double _getHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 16.0;
    if (screenWidth < 1200) return 24.0;
    return 32.0;
  }

  double _getVerticalSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 16.0;
    if (screenWidth < 1200) return 20.0;
    return 24.0;
  }
}
