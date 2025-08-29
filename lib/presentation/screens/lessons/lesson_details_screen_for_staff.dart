import 'package:flutter/material.dart';
import '../../../data/models/lesson.dart';
import 'staff_lesson_attendance_view.dart';
import 'package:intl/intl.dart';

class LessonDetailsScreenForStaff extends StatelessWidget {
  final Lesson lesson;

  const LessonDetailsScreenForStaff({Key? key, required this.lesson})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("פרטי שיעור: ${lesson.title}"),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "תאריך: ${DateFormat("dd/MM/yyyy HH:mm").format(lesson.date)}",
                    ),
                    Text("משך: ${lesson.durationMinutes} דקות"),
                    Text("מנחה: ${lesson.instructorName ?? 'לא צוין'}"),
                    Text("רשומים: ${lesson.registeredArtistIds.length}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Attendance section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'נוכחות',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    // Attendance stats
                    Row(
                      children: [
                        _buildQuickStat(
                          'נוכחים',
                          lesson.attendanceRecords
                              .where((r) => r.status == 'present')
                              .length,
                          Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _buildQuickStat(
                          'נעדרים',
                          lesson.attendanceRecords
                              .where((r) => r.status == 'absent')
                              .length,
                          Colors.red,
                        ),
                        const SizedBox(width: 16),
                        _buildQuickStat(
                          'ממתינים',
                          lesson.registeredArtistIds.length -
                              lesson.attendanceRecords.length,
                          Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // View attendance button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StaffLessonAttendanceView(lesson: lesson),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('צפה בנוכחות מפורטת'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8b5cf6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
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

  Widget _buildQuickStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
