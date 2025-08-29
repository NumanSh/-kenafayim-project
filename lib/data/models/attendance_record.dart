import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final bool hasReminder;
  final DateTime? reminderTime;
  final bool reminderShown;
  final String id;
  final String artistId;
  final String lessonId;
  final DateTime date;
  String status; // "pending", "present", "absent", "late", "excused"
  String? notes;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? markedBy; // ID of mentor/staff who marked attendance
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord({
    this.hasReminder = false,
    this.reminderTime,
    this.reminderShown = false,
    required this.id,
    required this.artistId,
    required this.lessonId,
    required this.date,
    this.status = "pending",
    this.notes,
    this.checkedInAt,
    this.checkedOutAt,
    this.markedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isPresent => status == "present";
  bool get isAbsent => status == "absent";
  bool get isLate => status == "late";
  bool get isPending => status == "pending";
  bool get isExcused => status == "excused";

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artistId': artistId,
      'lessonId': lessonId,
      'date': Timestamp.fromDate(date),
      'status': status,
      'notes': notes,
      'checkedInAt': checkedInAt != null
          ? Timestamp.fromDate(checkedInAt!)
          : null,
      'checkedOutAt': checkedOutAt != null
          ? Timestamp.fromDate(checkedOutAt!)
          : null,
      'markedBy': markedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'hasReminder': hasReminder,
      'reminderTime': reminderTime != null
          ? Timestamp.fromDate(reminderTime!)
          : null,
      'reminderShown': reminderShown,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      artistId: map['artistId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      checkedInAt: map['checkedInAt'] is Timestamp
          ? (map['checkedInAt'] as Timestamp).toDate()
          : null,
      checkedOutAt: map['checkedOutAt'] is Timestamp
          ? (map['checkedOutAt'] as Timestamp).toDate()
          : null,
      markedBy: map['markedBy'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      hasReminder: map['hasReminder'] ?? false,
      reminderTime: map['reminderTime'] is Timestamp
          ? (map['reminderTime'] as Timestamp).toDate()
          : null,
      reminderShown: map['reminderShown'] ?? false,
    );
  }

  AttendanceRecord copyWith({
    bool? hasReminder,
    DateTime? reminderTime,
    bool? reminderShown,
    String? id,
    String? artistId,
    String? lessonId,
    DateTime? date,
    String? status,
    String? notes,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    String? markedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      lessonId: lessonId ?? this.lessonId,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderShown: reminderShown ?? this.reminderShown,
    );
  }
}
