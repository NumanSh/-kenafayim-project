// ✅ NEW: Supporting enums and classes for recurring lessons

import 'package:knafayim_app/data/models/lesson.dart';

enum SeriesUpdateType {
  singleInstance, // Update only this lesson
  thisAndFuture, // Update this lesson and all future ones
  allInstances, // Update entire series
}

enum SeriesCancelType {
  singleInstance, // Cancel only this lesson
  remainingInstances, // Cancel all future lessons
  entireSeries, // Cancel entire series
}

/// Represents a complete lesson series for management purposes
class LessonSeries {
  final String recurrenceId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final RecurrencePattern recurrence;
  final List<Lesson> lessons;
  final String? instructorName;
  final int totalLessons;
  final int completedLessons;
  final int cancelledLessons;
  final int scheduledLessons;
  final Map<String, dynamic> metadata;

  const LessonSeries({
    required this.recurrenceId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.recurrence,
    required this.lessons,
    this.instructorName,
    required this.totalLessons,
    required this.completedLessons,
    required this.cancelledLessons,
    required this.scheduledLessons,
    this.metadata = const {},
  });

  factory LessonSeries.fromLessons(List<Lesson> lessons) {
    if (lessons.isEmpty) {
      throw ArgumentError('Cannot create LessonSeries from empty lesson list');
    }

    final firstLesson = lessons.first;
    final sortedLessons = lessons..sort((a, b) => a.date.compareTo(b.date));

    return LessonSeries(
      recurrenceId: firstLesson.recurrenceId!,
      title: firstLesson.seriesTitle ?? firstLesson.title,
      startDate: sortedLessons.first.date,
      endDate: sortedLessons.last.date,
      recurrence: firstLesson.recurrence!,
      lessons: sortedLessons,
      instructorName: firstLesson.instructorName,
      totalLessons: lessons.length,
      completedLessons: lessons.where((l) => l.status == 'completed').length,
      cancelledLessons: lessons.where((l) => l.status == 'cancelled').length,
      scheduledLessons: lessons.where((l) => l.status == 'scheduled').length,
      metadata: firstLesson.seriesMetadata,
    );
  }

  double get completionPercentage {
    if (totalLessons == 0) return 0.0;
    return completedLessons / totalLessons;
  }

  bool get isActive => scheduledLessons > 0;
  bool get isCompleted => completedLessons == totalLessons;
  bool get isCancelled => cancelledLessons == totalLessons;

  Lesson? get nextLesson {
    final now = DateTime.now();
    try {
      return lessons
          .where(
            (lesson) =>
                lesson.status == 'scheduled' && lesson.date.isAfter(now),
          )
          .first;
    } catch (e) {
      return null;
    }
  }
}
