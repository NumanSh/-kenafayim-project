import './attendance_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ NEW: Recurrence pattern model
enum RecurrenceType { none, weekly, biweekly, monthly, custom }

enum WeekDay { sunday, monday, tuesday, wednesday, thursday, friday, saturday }

class RecurrencePattern {
  final RecurrenceType type;
  final int interval; // Every X weeks/months
  final List<WeekDay> daysOfWeek; // Which days (for weekly)
  final int? dayOfMonth; // Which day (for monthly)
  final int maxOccurrences; // How many total lessons
  final List<DateTime> excludeDates; // Holidays/breaks
  final DateTime? endDate; // When series ends
  final Map<String, dynamic> customRules; // Future flexibility
  final List<bool>? selectedDays; // ✅ ADD THIS LINE if missing

  const RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.dayOfMonth,
    required this.maxOccurrences,
    this.excludeDates = const [],
    this.endDate,
    this.customRules = const {},
    this.selectedDays, // ✅ ADD THIS LINE if missing
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'interval': interval,
      'daysOfWeek': daysOfWeek.map((d) => d.name).toList(),
      'dayOfMonth': dayOfMonth,
      'maxOccurrences': maxOccurrences,
      'excludeDates': excludeDates.map((d) => d.toIso8601String()).toList(),
      'endDate': endDate?.toIso8601String(),
      'customRules': customRules,
    };
  }

  factory RecurrencePattern.fromMap(Map<String, dynamic> map) {
    return RecurrencePattern(
      type: RecurrenceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RecurrenceType.none,
      ),
      interval: map['interval'] ?? 1,
      daysOfWeek:
          (map['daysOfWeek'] as List<dynamic>?)
              ?.map((d) => WeekDay.values.firstWhere((e) => e.name == d))
              .toList() ??
          [],
      dayOfMonth: map['dayOfMonth'],
      maxOccurrences: map['maxOccurrences'] ?? 1,
      excludeDates:
          (map['excludeDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d))
              .toList() ??
          [],
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      customRules: map['customRules'] ?? {},
      selectedDays: map['selectedDays'] != null
          ? List<bool>.from(map['selectedDays'])
          : null, // ✅ ADD THIS LINE if missing
    );
  }
}

// ✅ ENHANCED: Lesson model with recurring support
class Lesson {
  final String id;
  final String title;
  final DateTime date;
  final int durationMinutes;
  final String? instructorName;
  final String? instructorEmail;
  final String? assignedInstructorId;
  final List<String> registeredArtistIds;
  List<AttendanceRecord> attendanceRecords;
  final int? maxCapacity;
  String status;
  final String? backgroundImagePath;

  // ✅ NEW: Recurring lesson fields
  final String? recurrenceId; // Links all lessons in a series
  final RecurrencePattern? recurrence; // How it repeats
  final DateTime? seriesStartDate; // When the series began
  final DateTime? seriesEndDate; // When the series ends
  final bool isRecurring; // Quick check flag
  final int? instanceNumber; // Which instance in the series (1, 2, 3...)
  final String? seriesTitle; // Original series title
  final Map<String, dynamic> seriesMetadata; // Additional series info

  Lesson({
    required this.id,
    required this.title,
    required this.date,
    required this.durationMinutes,
    this.instructorName,
    this.instructorEmail,
    this.assignedInstructorId,
    this.registeredArtistIds = const [],
    this.attendanceRecords = const [],
    this.maxCapacity,
    this.status = "scheduled",
    this.backgroundImagePath,
    // ✅ NEW: Recurring fields with defaults
    this.recurrenceId,
    this.recurrence,
    this.seriesStartDate,
    this.seriesEndDate,
    this.isRecurring = false,
    this.instanceNumber,
    this.seriesTitle,
    this.seriesMetadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "date": date.toIso8601String(),
      "durationMinutes": durationMinutes,
      "instructorName": instructorName,
      "instructorEmail": instructorEmail,
      "assignedInstructorId": assignedInstructorId,
      "registeredArtistIds": registeredArtistIds,
      "attendanceRecords": attendanceRecords.map((ar) => ar.toMap()).toList(),
      "maxCapacity": maxCapacity,
      "status": status,
      "backgroundImagePath": backgroundImagePath,
      // ✅ NEW: Recurring fields
      "recurrenceId": recurrenceId,
      "recurrence": recurrence?.toMap(),
      "seriesStartDate": seriesStartDate?.toIso8601String(),
      "seriesEndDate": seriesEndDate?.toIso8601String(),
      "isRecurring": isRecurring,
      "instanceNumber": instanceNumber,
      "seriesTitle": seriesTitle,
      "seriesMetadata": seriesMetadata,
      'selectedDays': recurrence?.selectedDays, // ✅ ADD THIS LINE if missing
    };
  }

  Lesson copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? durationMinutes,
    String? instructorName,
    String? instructorEmail,
    String? assignedInstructorId,
    List<String>? registeredArtistIds,
    List<AttendanceRecord>? attendanceRecords,
    int? maxCapacity,
    String? status,
    String? backgroundImagePath,
    // ✅ NEW: Recurring parameters
    String? recurrenceId,
    RecurrencePattern? recurrence,
    DateTime? seriesStartDate,
    DateTime? seriesEndDate,
    bool? isRecurring,
    int? instanceNumber,
    String? seriesTitle,
    Map<String, dynamic>? seriesMetadata,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      instructorName: instructorName ?? this.instructorName,
      instructorEmail: instructorEmail ?? this.instructorEmail,
      assignedInstructorId: assignedInstructorId ?? this.assignedInstructorId,
      registeredArtistIds: registeredArtistIds ?? this.registeredArtistIds,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      status: status ?? this.status,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      // ✅ NEW: Recurring fields
      recurrenceId: recurrenceId ?? this.recurrenceId,
      recurrence: recurrence ?? this.recurrence,
      seriesStartDate: seriesStartDate ?? this.seriesStartDate,
      seriesEndDate: seriesEndDate ?? this.seriesEndDate,
      isRecurring: isRecurring ?? this.isRecurring,
      instanceNumber: instanceNumber ?? this.instanceNumber,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      seriesMetadata: seriesMetadata ?? this.seriesMetadata,
    );
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    // ✅ Helper function to parse DateTime from various formats
    DateTime parseDateTime(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is Timestamp) {
        return value.toDate();
      }

      if (value.runtimeType.toString().contains('Timestamp')) {
        return value.toDate();
      }

      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date string: $value, error: $e');
          return DateTime.now();
        }
      }

      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      if (value is double) {
        return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
      }

      return DateTime.now();
    }

    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    try {
      return Lesson(
        id: map["id"] as String? ?? '',
        title: map["title"] as String? ?? '',
        date: parseDateTime(map["date"]),
        durationMinutes: map["durationMinutes"] as int? ?? 60,
        instructorName: map["instructorName"] as String?,
        instructorEmail: map["instructorEmail"] as String?,
        assignedInstructorId: map["assignedInstructorId"] as String?,
        registeredArtistIds: parseStringList(map["registeredArtistIds"]),
        attendanceRecords: (map["attendanceRecords"] as List<dynamic>? ?? [])
            .map((arMap) {
              try {
                return AttendanceRecord.fromMap(arMap as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing attendance record: $e');
                return null;
              }
            })
            .where((record) => record != null)
            .cast<AttendanceRecord>()
            .toList(),
        maxCapacity: map["maxCapacity"] as int?,
        status: map["status"] as String? ?? "scheduled",
        backgroundImagePath: map["backgroundImagePath"] as String?,
        // ✅ NEW: Parse recurring fields
        recurrenceId: map["recurrenceId"] as String?,
        recurrence: map["recurrence"] != null
            ? RecurrencePattern.fromMap(map["recurrence"])
            : null,
        seriesStartDate: map["seriesStartDate"] != null
            ? parseDateTime(map["seriesStartDate"])
            : null,
        seriesEndDate: map["seriesEndDate"] != null
            ? parseDateTime(map["seriesEndDate"])
            : null,
        isRecurring: map["isRecurring"] as bool? ?? false,
        instanceNumber: map["instanceNumber"] as int?,
        seriesTitle: map["seriesTitle"] as String?,
        seriesMetadata: map["seriesMetadata"] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      print('Error creating Lesson from map: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  // ✅ NEW: Helper methods for recurring lessons
  bool get isPartOfSeries => recurrenceId != null && recurrenceId!.isNotEmpty;

  String get displayTitle => isPartOfSeries && instanceNumber != null
      ? '$title (${instanceNumber}/${recurrence?.maxOccurrences ?? '?'})'
      : title;

  bool get canModifySeries => status == 'scheduled' && isPartOfSeries;

  get attendedArtistIds => null;
}
