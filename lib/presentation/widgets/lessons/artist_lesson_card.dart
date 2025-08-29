import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:knafayim_app/presentation/screens/attendance/lesson_attendance_screen.dart';
import 'package:knafayim_app/presentation/widgets/lessons/lesson_details_modal.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/user.dart';

class ModernArtistLessonCard extends StatefulWidget {
  final Lesson lesson;
  final User user;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onJoinClass;
  final bool isRegistered;

  const ModernArtistLessonCard({
    Key? key,
    required this.lesson,
    required this.user,
    required this.index,
    this.onTap,
    this.onJoinClass,
    this.isRegistered = false,
  }) : super(key: key);

  @override
  State<ModernArtistLessonCard> createState() => _ModernArtistLessonCardState();
}

class _ModernArtistLessonCardState extends State<ModernArtistLessonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTimeUntilClass() {
    final now = DateTime.now();
    final lessonDate = widget.lesson.date;
    final difference = lessonDate.difference(now);

    if (difference.isNegative) {
      final daysPast = difference.inDays.abs();
      if (daysPast == 0) return 'היום (הסתיים)';
      if (daysPast == 1) return 'אתמול';
      return 'לפני $daysPast ימים';
    } else {
      if (difference.inDays > 0) {
        final days = difference.inDays;
        if (days == 1) return 'מחר';
        return 'בעוד $days ימים';
      } else if (difference.inHours > 0) {
        return 'בעוד ${difference.inHours} שעות';
      } else if (difference.inMinutes > 0) {
        return 'בעוד ${difference.inMinutes} דקות';
      } else {
        return 'עכשיו!';
      }
    }
  }

  double _calculateAttendanceRate() {
    if (!widget.isRegistered) return 0.0;

    final userAttendance = widget.lesson.attendanceRecords.where(
      (record) => record.artistId == widget.user.id,
    );

    if (userAttendance.isEmpty) return 85.0;

    final totalSessions = userAttendance.length;
    final attendedSessions = userAttendance
        .where((record) => record.isPresent)
        .length;

    return totalSessions > 0 ? (attendedSessions / totalSessions) * 100 : 85.0;
  }

  bool _isLessonCompleted() {
    return widget.lesson.date.isBefore(DateTime.now());
  }

  void _showLessonDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonDetailsModal(
        lesson: widget.lesson,
        user: widget.user,
        isRegistered: widget.isRegistered,
        onJoinClass: widget.onJoinClass,
        currentUser: widget.user,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // ✅ RESPONSIVE DIMENSIONS
    final cardWidth = isSmallScreen ? 260.0 : 300.0;
    final cardHeight = isSmallScreen ? 320.0 : 360.0; // ✅ Reduced height
    final headerHeight = isSmallScreen
        ? 120.0
        : 140.0; // ✅ Reduced header height

    final colorPalettes = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
    ];

    final colors = colorPalettes[widget.index % colorPalettes.length];
    final hasValidImage =
        widget.lesson.backgroundImagePath != null &&
        File(widget.lesson.backgroundImagePath!).existsSync();

    final timeText = _formatTimeUntilClass();
    final attendanceRate = _calculateAttendanceRate();
    final isCompleted = _isLessonCompleted();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: cardWidth,
            height: cardHeight, // ✅ Fixed height
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), // ✅ Reduced radius
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.2),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _showLessonDetails,
                onHover: (hovering) {
                  setState(() => _isHovered = hovering);
                  if (hovering) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, colors[0].withOpacity(0.05)],
                    ),
                    border: Border.all(
                      color: colors[0].withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ HEADER WITH FIXED HEIGHT
                      Container(
                        height: headerHeight,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Background image
                            if (hasValidImage)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    image: DecorationImage(
                                      image: FileImage(
                                        File(
                                          widget.lesson.backgroundImagePath!,
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.1),
                                          Colors.black.withOpacity(0.4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Time badge
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors[0],
                                  ),
                                ),
                              ),
                            ),

                            // Attendance percentage (only for registered)
                            if (widget.isRegistered)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          value: attendanceRate / 100,
                                          strokeWidth: 2,
                                          backgroundColor: colors[0]
                                              .withOpacity(0.2),
                                          valueColor: AlwaysStoppedAnimation(
                                            colors[0],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${attendanceRate.toInt()}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: colors[0],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Center icon
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Icon(
                                  _getLessonIcon(widget.lesson.title),
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ✅ CONTENT SECTION WITH FLEXIBLE LAYOUT
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            16,
                          ), // ✅ Reduced padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Lesson title
                              Text(
                                widget.lesson.title,
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 16
                                      : 18, // ✅ Reduced font size
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1a1a1a),
                                  height: 1.2,
                                ),
                                maxLines: 1, // ✅ Limited to 1 line
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 6), // ✅ Reduced spacing
                              // Instructor with icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: colors[0],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.lesson.instructorName ??
                                          'מנחה לא צוין',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colors[0],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8), // ✅ Reduced spacing
                              // Duration and participants
                              Row(
                                children: [
                                  _buildInfoChip(
                                    Icons.schedule,
                                    '${widget.lesson.durationMinutes} דק\'',
                                    colors[0],
                                  ),
                                  const SizedBox(width: 6),
                                  _buildInfoChip(
                                    Icons.people_outline,
                                    '${widget.lesson.registeredArtistIds.length}',
                                    colors[1],
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // ✅ ACTION BUTTON WITH FIXED HEIGHT
                              SizedBox(
                                width: double.infinity,
                                height: 40, // ✅ Fixed button height
                                child: widget.isRegistered
                                    ? _buildStatusButton(colors, isCompleted)
                                    : _buildJoinButton(colors),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ), // ✅ Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(List<Color> colors, bool isCompleted) {
    if (widget.user.role == UserRole.mentor) {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonAttendanceScreen(
                lesson: widget.lesson,
                mentor: widget.user,
              ),
            ),
          );
        },
        icon: const Icon(Icons.how_to_reg, size: 16),
        label: const Text('נהל נוכחות'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors[0],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[0].withOpacity(0.1), colors[1].withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[0].withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.bookmark,
            size: 16,
            color: colors[0],
          ),
          const SizedBox(width: 6),
          Text(
            isCompleted ? 'הושלם' : 'רשום לשיעור',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors[0],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(List<Color> colors) {
    return ElevatedButton(
      onPressed: widget.onJoinClass,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.zero,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'הצטרף לשיעור',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getLessonIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('music') || titleLower.contains('מוזיקה')) {
      return Icons.music_note;
    } else if (titleLower.contains('dance') || titleLower.contains('ריקוד')) {
      return Icons.sports_gymnastics;
    } else if (titleLower.contains('art') || titleLower.contains('אמנות')) {
      return Icons.palette;
    } else if (titleLower.contains('theater') ||
        titleLower.contains('תיאטרון')) {
      return Icons.theater_comedy;
    }
    return Icons.school;
  }
}
