class NotificationPreference {
  final String userId;
  final bool lessonReminders;
  final bool attendanceNotifications;
  final bool seriesUpdates;
  final bool adminNotifications;
  final bool realTimeUpdates;
  final bool emergencyNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int reminderHours24;
  final int reminderHours1;
  final Map<String, bool> customPreferences;

  NotificationPreference({
    required this.userId,
    this.lessonReminders = true,
    this.attendanceNotifications = true,
    this.seriesUpdates = true,
    this.adminNotifications = true,
    this.realTimeUpdates = true,
    this.emergencyNotifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.reminderHours24 = 24,
    this.reminderHours1 = 1,
    this.customPreferences = const {},
  });

  NotificationPreference copyWith({
    String? userId,
    bool? lessonReminders,
    bool? attendanceNotifications,
    bool? seriesUpdates,
    bool? adminNotifications,
    bool? realTimeUpdates,
    bool? emergencyNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? reminderHours24,
    int? reminderHours1,
    Map<String, bool>? customPreferences,
  }) {
    return NotificationPreference(
      userId: userId ?? this.userId,
      lessonReminders: lessonReminders ?? this.lessonReminders,
      attendanceNotifications:
          attendanceNotifications ?? this.attendanceNotifications,
      seriesUpdates: seriesUpdates ?? this.seriesUpdates,
      adminNotifications: adminNotifications ?? this.adminNotifications,
      realTimeUpdates: realTimeUpdates ?? this.realTimeUpdates,
      emergencyNotifications:
          emergencyNotifications ?? this.emergencyNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      reminderHours24: reminderHours24 ?? this.reminderHours24,
      reminderHours1: reminderHours1 ?? this.reminderHours1,
      customPreferences: customPreferences ?? this.customPreferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lessonReminders': lessonReminders,
      'attendanceNotifications': attendanceNotifications,
      'seriesUpdates': seriesUpdates,
      'adminNotifications': adminNotifications,
      'realTimeUpdates': realTimeUpdates,
      'emergencyNotifications': emergencyNotifications,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'reminderHours24': reminderHours24,
      'reminderHours1': reminderHours1,
      'customPreferences': customPreferences,
    };
  }

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      userId: map['userId'] ?? '',
      lessonReminders: map['lessonReminders'] ?? true,
      attendanceNotifications: map['attendanceNotifications'] ?? true,
      seriesUpdates: map['seriesUpdates'] ?? true,
      adminNotifications: map['adminNotifications'] ?? true,
      realTimeUpdates: map['realTimeUpdates'] ?? true,
      emergencyNotifications: map['emergencyNotifications'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      reminderHours24: map['reminderHours24'] ?? 24,
      reminderHours1: map['reminderHours1'] ?? 1,
      customPreferences: Map<String, bool>.from(map['customPreferences'] ?? {}),
    );
  }
}
