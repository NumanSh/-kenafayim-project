import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkingHoursStatus { pending, approved, rejected }

class WorkingHours {
  final String id;
  final String mentorId;
  final String mentorName;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String? lessonId;
  final String? lessonTitle;
  final String discipline; // Art discipline (plastic arts, theater, etc.)
  final int numberOfStudents;
  final String? notes;
  final String? photoEvidenceUrl;
  final WorkingHoursStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? lastModified;

  WorkingHours({
    required this.id,
    required this.mentorId,
    required this.mentorName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.lessonId,
    this.lessonTitle,
    required this.discipline,
    required this.numberOfStudents,
    this.notes,
    this.photoEvidenceUrl,
    this.status = WorkingHoursStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.lastModified,
  });

  // Calculate hours from duration
  double get hours => durationMinutes / 60.0;

  // Check if hours are from today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if hours are from this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Check if hours are from this month
  bool get isThisMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  WorkingHours copyWith({
    String? id,
    String? mentorId,
    String? mentorName,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? lessonId,
    String? lessonTitle,
    String? discipline,
    int? numberOfStudents,
    String? notes,
    String? photoEvidenceUrl,
    WorkingHoursStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return WorkingHours(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      mentorName: mentorName ?? this.mentorName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      discipline: discipline ?? this.discipline,
      numberOfStudents: numberOfStudents ?? this.numberOfStudents,
      notes: notes ?? this.notes,
      photoEvidenceUrl: photoEvidenceUrl ?? this.photoEvidenceUrl,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'discipline': discipline,
      'numberOfStudents': numberOfStudents,
      'notes': notes,
      'photoEvidenceUrl': photoEvidenceUrl,
      'status': status.toString().split('.').last,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': lastModified != null
          ? Timestamp.fromDate(lastModified!)
          : null,
    };
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      id: map['id'] ?? '',
      mentorId: map['mentorId'] ?? '',
      mentorName: map['mentorName'] ?? '',
      date: _parseDateTime(map['date'] ?? DateTime.now()) ?? DateTime.now(),
      startTime: _parseDateTime(map['startTime']) ?? DateTime.now(),
      endTime: _parseDateTime(map['endTime']) ?? DateTime.now(),
      durationMinutes: map['durationMinutes'] ?? 0,
      lessonId: map['lessonId'],
      lessonTitle: map['lessonTitle'],
      discipline: map['discipline'] ?? '',
      numberOfStudents: map['numberOfStudents'] ?? 0,
      notes: map['notes'],
      photoEvidenceUrl: map['photoEvidenceUrl'],
      status: WorkingHoursStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => WorkingHoursStatus.pending,
      ),
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null
          ? _parseDateTime(map['approvedAt'])
          : null,
      rejectionReason: map['rejectionReason'],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastModified: map['lastModified'] != null
          ? _parseDateTime(map['lastModified'])
          : null,
    );
  }

  // Add this helper method to handle both Timestamp and int
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is DateTime) {
      return value;
    }

    return null;
  }

  // Helper method to get status color
  Color getStatusColor() {
    switch (status) {
      case WorkingHoursStatus.pending:
        return const Color(0xFFf59e0b); // Orange
      case WorkingHoursStatus.approved:
        return const Color(0xFF10b981); // Green
      case WorkingHoursStatus.rejected:
        return const Color(0xFFef4444); // Red
    }
  }

  // Helper method to get status text in Hebrew
  String getStatusText() {
    switch (status) {
      case WorkingHoursStatus.pending:
        return 'ממתין לאישור';
      case WorkingHoursStatus.approved:
        return 'אושר';
      case WorkingHoursStatus.rejected:
        return 'נדחה';
    }
  }

  // Helper method to get discipline display name
  String getDisciplineDisplayName() {
    switch (discipline.toLowerCase()) {
      case 'plastic_arts':
        return 'אמנות פלסטית';
      case 'theater':
        return 'תאטרון';
      case 'creative_writing':
        return 'כתיבה יוצרת';
      case 'music':
        return 'מוזיקה';
      case 'animation':
        return 'אנימציה';
      case 'video_cinema':
        return 'וידאו קולנוע';
      default:
        return discipline;
    }
  }
}

// Helper class for working hours statistics
class WorkingHoursStats {
  final int totalHoursThisWeek;
  final int totalHoursThisMonth;
  final int pendingHours;
  final int approvedHours;
  final int rejectedHours;
  final double weeklyTarget;
  final double monthlyTarget;

  WorkingHoursStats({
    required this.totalHoursThisWeek,
    required this.totalHoursThisMonth,
    required this.pendingHours,
    required this.approvedHours,
    required this.rejectedHours,
    this.weeklyTarget = 20.0,
    this.monthlyTarget = 80.0,
  });

  double get weeklyProgress => totalHoursThisWeek / weeklyTarget;
  double get monthlyProgress => totalHoursThisMonth / monthlyTarget;

  bool get weeklyTargetMet => totalHoursThisWeek >= weeklyTarget;
  bool get monthlyTargetMet => totalHoursThisMonth >= monthlyTarget;
}
