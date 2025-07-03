enum NotificationType { message, reminder, announcement, system }

class Notification {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  Notification markAsRead() {
    return Notification(
      id: id,
      userId: userId,
      title: title,
      content: content,
      timestamp: timestamp,
      type: type,
      isRead: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
      'isRead': isRead,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      type: _typeFromString(map['type'] ?? 'system'),
      isRead: map['isRead'] ?? false,
    );
  }

  static NotificationType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'message':
        return NotificationType.message;
      case 'reminder':
        return NotificationType.reminder;
      case 'announcement':
        return NotificationType.announcement;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}
