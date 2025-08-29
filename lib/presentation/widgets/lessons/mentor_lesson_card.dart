import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/user.dart';
import '../../../config/themes.dart';

class MentorLessonCard extends StatelessWidget {
  final Lesson lesson;
  final User user;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onTakeAttendance;
  final VoidCallback? onManageClass;

  const MentorLessonCard({
    Key? key,
    required this.lesson,
    required this.user,
    required this.index,
    this.onTap,
    this.onTakeAttendance,
    this.onManageClass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Professional color palette for mentors
    final colors = [
      const Color(0xFF059669), // Emerald
      const Color(0xFF0369a1), // Sky blue
      const Color(0xFF7c3aed), // Violet
      const Color(0xFFdc2626), // Red
      const Color(0xFFea580c), // Orange
    ];

    final cardColor = colors[index % colors.length];
    final hasValidImage = lesson.backgroundImagePath != null &&
        File(lesson.backgroundImagePath!).existsSync();

    // Mock data for demo
    final enrolledCount = 8;
    final maxCapacity = 12;
    final attendanceRate = 0.78;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with class info overlay
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: hasValidImage
                      ? DecorationImage(
                          image: FileImage(File(lesson.backgroundImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: !hasValidImage
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cardColor.withOpacity(0.1),
                            cardColor.withOpacity(0.2),
                          ],
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Overlay for better visibility
                    if (hasValidImage)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
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

                    // Center teaching icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: hasValidImage
                              ? Colors.white.withOpacity(0.2)
                              : cardColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.school,
                          size: 32,
                          color: hasValidImage ? Colors.white : cardColor,
                        ),
                      ),
                    ),

                    // Student count indicator
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cardColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: cardColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$enrolledCount/$maxCapacity',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cardColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Status indicator
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: enrolledCount >= maxCapacity * 0.8
                              ? Colors.green
                              : enrolledCount >= maxCapacity * 0.5
                                  ? Colors.orange
                                  : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          enrolledCount >= maxCapacity * 0.8
                              ? Icons.trending_up
                              : enrolledCount >= maxCapacity * 0.5
                                  ? Icons.trending_flat
                                  : Icons.trending_down,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lesson title
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Teaching opportunity label
                      Text(
                        'הזדמנות הוראה',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cardColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Class stats
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: const Color(0xFF6b7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$enrolledCount תלמידים',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(attendanceRate * 100).toInt()}% נוכחות',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: cardColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: onTakeAttendance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cardColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: const Text(
                                'נוכחות',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onManageClass,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cardColor,
                                side: BorderSide(color: cardColor, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: const Text(
                                'ניהול',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
