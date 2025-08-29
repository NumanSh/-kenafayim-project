import 'dart:ui';

enum EventType {
  holiday,
  meeting,
  workshop,
  special_event,
  announcement,
  other,
  therapy,
}

enum EventPriority { low, medium, high, urgent }

enum EventRecurrence { none, daily, weekly, monthly, yearly }

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String createdById;
  final String createdByName;
  final List<String> participantIds;
  final EventType type;
  final EventPriority priority;
  final EventRecurrence recurrence;
  final String? locationOrLink;
  final String? imageUrl;
  final bool isAllDay;
  final DateTime createdAt;
  final DateTime? lastModified;
  final Map<String, dynamic> additionalInfo;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.createdById,
    required this.createdByName,
    required this.participantIds,
    required this.type,
    this.priority = EventPriority.medium,
    this.recurrence = EventRecurrence.none,
    this.locationOrLink,
    this.imageUrl,
    this.isAllDay = false,
    required this.createdAt,
    this.lastModified,
    this.additionalInfo = const {},
  });

  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  // Get event color based on type
  // Get event color based on type
  Color getEventColor() {
    switch (type) {
      case EventType.holiday:
        return const Color(0xFFef4444); // Red
      case EventType.meeting:
        return const Color(0xFF3b82f6); // Blue
      case EventType.workshop:
        return const Color(0xFF8b5cf6); // Purple
      case EventType.special_event:
        return const Color(0xFF10b981); // Green
      case EventType.announcement:
        return const Color(0xFFf59e0b); // Orange
      case EventType.therapy:
        return const Color(0xFF06b6d4); // Cyan
      case EventType.other:
        return const Color(0xFF6b7280); // Gray
    }
  }

  // Get event type display name in Hebrew
  // Get event type display name in Hebrew
  String getTypeDisplayName() {
    switch (type) {
      case EventType.holiday:
        return 'חג/חופש';
      case EventType.meeting:
        return 'פגישה';
      case EventType.workshop:
        return 'סדנה';
      case EventType.special_event:
        return 'אירוע מיוחד';
      case EventType.announcement:
        return 'הודעה';
      case EventType.therapy:
        return 'טיפול';
      case EventType.other:
        return 'אחר';
    }
  }

  // Get priority display name in Hebrew
  String getPriorityDisplayName() {
    switch (priority) {
      case EventPriority.low:
        return 'נמוכה';
      case EventPriority.medium:
        return 'בינונית';
      case EventPriority.high:
        return 'גבוהה';
      case EventPriority.urgent:
        return 'דחוף';
    }
  }

  // Check if event is today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  // Check if event is upcoming (within next 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return startTime.isAfter(now) && startTime.isBefore(weekFromNow);
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? createdById,
    String? createdByName,
    List<String>? participantIds,
    EventType? type,
    EventPriority? priority,
    EventRecurrence? recurrence,
    String? locationOrLink,
    String? imageUrl,
    bool? isAllDay,
    DateTime? createdAt,
    DateTime? lastModified,
    Map<String, dynamic>? additionalInfo,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      participantIds: participantIds ?? this.participantIds,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      locationOrLink: locationOrLink ?? this.locationOrLink,
      imageUrl: imageUrl ?? this.imageUrl,
      isAllDay: isAllDay ?? this.isAllDay,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'createdById': createdById,
      'createdByName': createdByName,
      'participantIds': participantIds,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'recurrence': recurrence.toString().split('.').last,
      'locationOrLink': locationOrLink,
      'imageUrl': imageUrl,
      'isAllDay': isAllDay,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified?.millisecondsSinceEpoch,
      'additionalInfo': additionalInfo,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime'] ?? 0),
      createdById: map['createdById'] ?? '',
      createdByName: map['createdByName'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      type: _typeFromString(map['type'] ?? 'other'),
      priority: _priorityFromString(map['priority'] ?? 'medium'),
      recurrence: _recurrenceFromString(map['recurrence'] ?? 'none'),
      locationOrLink: map['locationOrLink'],
      imageUrl: map['imageUrl'],
      isAllDay: map['isAllDay'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'])
          : null,
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] ?? {}),
    );
  }

  static EventType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'holiday':
        return EventType.holiday;
      case 'meeting':
        return EventType.meeting;
      case 'workshop':
        return EventType.workshop;
      case 'special_event':
        return EventType.special_event;
      case 'announcement':
        return EventType.announcement;
      case 'therapy':
        return EventType.therapy;
      case 'other':
        return EventType.other;
      default:
        return EventType.other;
    }
  }

  static EventPriority _priorityFromString(String priorityStr) {
    switch (priorityStr) {
      case 'low':
        return EventPriority.low;
      case 'medium':
        return EventPriority.medium;
      case 'high':
        return EventPriority.high;
      case 'urgent':
        return EventPriority.urgent;
      default:
        return EventPriority.medium;
    }
  }

  static EventRecurrence _recurrenceFromString(String recurrenceStr) {
    switch (recurrenceStr) {
      case 'none':
        return EventRecurrence.none;
      case 'daily':
        return EventRecurrence.daily;
      case 'weekly':
        return EventRecurrence.weekly;
      case 'monthly':
        return EventRecurrence.monthly;
      case 'yearly':
        return EventRecurrence.yearly;
      default:
        return EventRecurrence.none;
    }
  }
}
