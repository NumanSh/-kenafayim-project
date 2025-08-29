class Message {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String createdBy;
  final List<String> readBy;
  final String senderId;
  final List<String> recipientIds;
  final DateTime timestamp;
  final bool isRead;
  final String? recipientEmail;

  Message({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.createdBy,
    this.readBy = const [],
    required this.senderId,
    required this.recipientIds,
    DateTime? timestamp,
    this.isRead = false,
    this.recipientEmail,
  }) : timestamp = timestamp ?? createdAt;

  // המרה ל-Map לשמירה ב-Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'readBy': readBy,
      'senderId': senderId,
      'recipientIds': recipientIds,
      'timestamp': timestamp,
      'isRead': isRead,
      'recipientEmail': recipientEmail,
    };
  }

  // יצירת אובייקט Message מ-Map שהתקבל מ-Firestore - ENHANCED
  factory Message.fromMap(Map<String, dynamic> map) {
    // פונקציה עזר להמרת ערך לתאריך
    DateTime parseDateTime(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }

      if (value is DateTime) {
        return value;
      }

      // אם זה אובייקט Timestamp של פיירבייס
      if (value.runtimeType.toString().contains('Timestamp')) {
        return value.toDate();
      }

      // אם זה מספר שלם (timestamp במילישניות)
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      // אם זה מספר עשרוני (timestamp בשניות)
      if (value is double) {
        return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
      }

      // אם זה מחרוזת, ננסה לנתח אותה כתאריך
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }

      return DateTime.now();
    }

    // ✅ ENHANCED: Better parsing for recipientIds
    List<String> parseRecipientIds(dynamic value) {
      if (value == null) return [];

      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }

      if (value is String) {
        // If it's a comma-separated string, split it
        if (value.contains(',')) {
          return value
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        // If it's a single string, return as single item list
        return value.isEmpty ? [] : [value];
      }

      return [];
    }

    // ✅ ENHANCED: Better parsing for readBy
    List<String> parseReadBy(dynamic value) {
      if (value == null) return [];

      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }

      return [];
    }

    return Message(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: parseDateTime(map['createdAt']),
      createdBy: map['createdBy'] ?? '',
      readBy: parseReadBy(map['readBy']),
      senderId: map['senderId'] ?? '',
      recipientIds: parseRecipientIds(map['recipientIds']),
      timestamp: parseDateTime(map['timestamp']),
      isRead: map['isRead'] ?? false,
      recipientEmail: map['recipientEmail'],
    );
  }

  // בדיקה האם הודעה נקראה על ידי משתמש מסוים
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  // בדיקה האם ההודעה מיועדת לכל המשתמשים (הודעה כללית)
  bool isBroadcast() {
    return recipientIds.isEmpty;
  }

  Message markAsRead() {
    return Message(
      id: id,
      content: content,
      senderId: senderId,
      recipientIds: recipientIds,
      timestamp: timestamp,
      isRead: true,
      title: title,
      createdAt: createdAt,
      createdBy: createdBy,
      readBy: readBy,
      recipientEmail: recipientEmail,
    );
  }

  // יצירת עותק של ההודעה עם שינויים
  Message copyWith({
    String? title,
    String? content,
    List<String>? readBy,
    List<String>? recipientIds,
    bool? isRead,
    String? recipientEmail,
  }) {
    return Message(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      createdBy: createdBy,
      readBy: readBy ?? this.readBy,
      senderId: senderId,
      recipientIds: recipientIds ?? this.recipientIds,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      recipientEmail: recipientEmail ?? this.recipientEmail,
    );
  }
}
