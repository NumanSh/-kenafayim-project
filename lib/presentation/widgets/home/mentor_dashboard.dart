import 'package:flutter/material.dart';
import 'package:knafayim_app/presentation/screens/attendance/lesson_attendance_screen.dart';
import 'package:knafayim_app/presentation/widgets/hours/working_hours_card.dart';
import '../../../data/models/user.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';
import '../../screens/lessons/mentor_lesson_attendance_screen.dart';
import '../lessons/mentor_lesson_card.dart'; // Import the new card

class MentorDashboard extends StatefulWidget {
  final User user;

  const MentorDashboard({super.key, required this.user});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  List<Lesson> _upcomingLessons = [];
  bool _isLoadingLessons = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingLessons();
  }

  Future<void> _loadUpcomingLessons() async {
    if (!mounted) return;
    setState(() => _isLoadingLessons = true);
    try {
      final lessons = await _lessonRepository.getLessonsForMentor(
        widget.user.id,
        startDate: null,
        endDate: null,
      );
      if (mounted) {
        setState(() {
          _upcomingLessons = lessons;
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadUpcomingLessons,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildWelcomeHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: WorkingHoursCard(
                key: ValueKey('working_hours_${widget.user.id}'), // Unique key
                user: widget.user,
              ),
            ),
            const SizedBox(height: 32),

            _buildTeachingStatsSection(),
            const SizedBox(height: 24),

            _buildUpcomingClassesSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'שלום, ${widget.user.name} 👨‍🏫',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'מוכן להעביר השראה היום?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6b7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachingStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF059669), Color(0xFF10b981)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'סטטיסטיקות הוראה',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTeachingStatCard(
                    'נוכחות ממוצעת',
                    '78%',
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTeachingStatCard(
                    'שיעור פופולרי',
                    'ציור',
                    Icons.star,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTeachingStatCard('תלמידים', '24', Icons.people),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachingStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'השיעורים שלי היום 🏫',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingLessons)
          SizedBox(
            height: 260,
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_upcomingLessons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFf9fafb),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFe5e7eb)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 32,
                      color: Color(0xFF9ca3af),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'אין שיעורים קרובים',
                      style: TextStyle(
                        color: Color(0xFF6b7280),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 283,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _upcomingLessons.length,
              itemBuilder: (context, index) {
                final lesson = _upcomingLessons[index];
                return MentorLessonCard(
                  lesson: lesson,
                  user: widget.user,
                  index: index,
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LessonAttendanceScreen(
                          lesson: lesson,
                          mentor: widget.user,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadUpcomingLessons();
                    }
                  },
                  onTakeAttendance: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LessonAttendanceScreen(
                          lesson: lesson,
                          mentor: widget.user,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadUpcomingLessons();
                    }
                  },
                  onManageClass: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ניהול כיתה יהיה זמין בקרוב'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
