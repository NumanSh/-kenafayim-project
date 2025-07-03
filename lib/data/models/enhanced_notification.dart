import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  lessonReminder24h,
  lessonReminder1h,
  attendanceRequest,
  attendanceMissing,
  seriesUpdate,
  seriesComplete,
  adminNewRegistration,
  adminAttendanceReport,
  mentorAssignment,
  mentorAttendanceReminder,
  artistConfirmation,
  artistAchievement,
  realTimeUpdate,
  emergency,
  message,
  system,
}

enum NotificationPriority { low, normal, high, urgent }

class NotificationAction {
  final String id;
  final String title;
  final String action;
  final Map<String, dynamic>? data;

  NotificationAction({
    required this.id,
    required this.title,
    required this.action,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'action': action, 'data': data};
  }

  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      action: map['action'] ?? '',
      data: map['data'],
    );
  }
}

class EnhancedNotification {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime timestamp;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final bool isScheduled;
  final DateTime? scheduledFor;
  final String? lessonId;
  final String? seriesId;
  final String? imageUrl;
  final List<NotificationAction> actions;
  final Map<String, dynamic>? metadata;

  EnhancedNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.isScheduled = false,
    this.scheduledFor,
    this.lessonId,
    this.seriesId,
    this.imageUrl,
    this.actions = const [],
    this.metadata,
  });

  EnhancedNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? timestamp,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    bool? isScheduled,
    DateTime? scheduledFor,
    String? lessonId,
    String? seriesId,
    String? imageUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      lessonId: lessonId ?? this.lessonId,
      seriesId: seriesId ?? this.seriesId,
      imageUrl: imageUrl ?? this.imageUrl,
      actions: actions ?? this.actions,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'timestamp': Timestamp.fromDate(
        timestamp,
      ), // ✅ FIXED: Ensure proper Timestamp conversion
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'isRead': isRead,
      'isScheduled': isScheduled,
      'scheduledFor': scheduledFor != null
          ? Timestamp.fromDate(scheduledFor!)
          : null, // ✅ FIXED
      'lessonId': lessonId,
      'seriesId': seriesId,
      'imageUrl': imageUrl,
      'actions': actions.map((action) => action.toMap()).toList(),
      'metadata': metadata,
    };
  }

  factory EnhancedNotification.fromMap(Map<String, dynamic> map) {
    return EnhancedNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: _typeFromString(map['type'] ?? 'system'),
      priority: _priorityFromString(map['priority'] ?? 'normal'),
      isRead: map['isRead'] ?? false,
      isScheduled: map['isScheduled'] ?? false,
      scheduledFor: (map['scheduledFor'] as Timestamp?)?.toDate(),
      lessonId: map['lessonId'],
      seriesId: map['seriesId'],
      imageUrl: map['imageUrl'],
      actions:
          (map['actions'] as List<dynamic>?)
              ?.map((action) => NotificationAction.fromMap(action))
              .toList() ??
          [],
      metadata: map['metadata'],
    );
  }

  static NotificationType _typeFromString(String typeStr) {
    return NotificationType.values.firstWhere(
      (type) => type.toString().split('.').last == typeStr,
      orElse: () => NotificationType.system,
    );
  }

  static NotificationPriority _priorityFromString(String priorityStr) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.toString().split('.').last == priorityStr,
      orElse: () => NotificationPriority.normal,
    );
  }
}
