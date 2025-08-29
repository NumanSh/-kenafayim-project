import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knafayim_app/config/service_locator.dart';
import 'package:knafayim_app/services/enhanced_notification_service.dart';
import 'package:knafayim_app/data/models/enhanced_notification.dart';
import '../data/models/message.dart';
import '../data/models/user.dart';

class EnhancedMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notification service
  EnhancedNotificationService get _notificationService =>
      serviceLocator<EnhancedNotificationService>();

  // קבלת כל ההודעות
  Stream<List<Message>> getMessages() {
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  // קבלת הודעות עבור משתמש ספציפי (כולל הודעות כלליות)
  Stream<List<Message>> getMessagesForUser(String userId, String? userEmail) {
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Message.fromMap({...doc.data(), 'id': doc.id});
                } catch (e) {
                  print('Error parsing message ${doc.id}: $e');
                  return null;
                }
              })
              .where((message) => message != null)
              .cast<Message>()
              .where(
                (message) =>
                    // הודעה מיועדת למשתמש הספציפי לפי ID
                    message.recipientIds.contains(userId) ||
                    // או הודעה כללית (ללא נמענים)
                    message.recipientIds.isEmpty ||
                    // או הודעה שנשלחה על ידי המשתמש
                    message.senderId == userId ||
                    // או הודעה מיועדת למשתמש לפי כתובת מייל
                    (userEmail != null && message.recipientEmail == userEmail),
              )
              .toList();
        });
  }

  // ✅ ENHANCED: הוספת הודעה חדשה עם התראות
  Future<void> addMessage({
    required String title,
    required String content,
    required String createdBy,
    required String senderId,
    required List<String> recipientIds,
    String? recipientEmail,
    required UserRole senderRole,
  }) async {
    // בדיקה שהשולח הוא איש צוות
    if (senderRole != UserRole.staff) {
      throw Exception('רק אנשי צוות רשאים להוסיף הודעות');
    }

    // ✅ Save message to Firestore
    await _firestore.collection('messages').add({
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'readBy': [],
      'senderId': senderId,
      'recipientIds': recipientIds,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'recipientEmail': recipientEmail,
    });

    // ✅ SEND NOTIFICATIONS to recipients
    try {
      List<String> notificationRecipients = [];

      if (recipientIds.isNotEmpty) {
        // Send to specific recipients
        notificationRecipients = recipientIds;
      } else {
        // Send to all users (broadcast message)
        final allUsers = await _getAllUserIds();
        notificationRecipients = allUsers;
      }

      // ✅ FIXED: Remove sender from recipients BEFORE sending notifications
      notificationRecipients.removeWhere((id) => id == senderId);

      print('🔍 DEBUG: Original recipients: $recipientIds');
      print('🔍 DEBUG: Sender ID: $senderId');
      print(
        '🔍 DEBUG: Final recipients (excluding sender): $notificationRecipients',
      );

      if (notificationRecipients.isNotEmpty) {
        await _notificationService.sendRealTimeUpdate(
          userIds: notificationRecipients, // ✅ Now excludes sender
          title: 'הודעה חדשה 📩',
          content:
              '$title: ${content.length > 50 ? content.substring(0, 50) + "..." : content}',
          priority: NotificationPriority.normal,
          data: {
            'type': 'message',
            'messageTitle': title,
            'senderName': createdBy,
          },
        );

        print(
          '✅ Message notifications sent to ${notificationRecipients.length} users',
        );
        print('📧 Message: $title');
        print(
          '👥 Recipients (excluding sender): ${notificationRecipients.join(", ")}',
        );
        print('🚫 Sender excluded: $senderId');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to send message notifications: $e');
    }
  }

  // סימון הודעה כנקראה
  Future<void> markAsRead(String messageId, String userId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  // עדכון הודעה קיימת (רק עבור צוות)
  Future<void> updateMessage({
    required String messageId,
    required String title,
    required String content,
    String? recipientEmail,
    List<String>? recipientIds,
    required UserRole updaterRole,
  }) async {
    // בדיקה שהמעדכן הוא איש צוות
    if (updaterRole != UserRole.staff) {
      throw Exception('רק אנשי צוות רשאים לעדכן הודעות');
    }

    final updateData = <String, dynamic>{
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (recipientEmail != null) {
      updateData['recipientEmail'] = recipientEmail;
    }

    if (recipientIds != null) {
      updateData['recipientIds'] = recipientIds;
    }

    await _firestore.collection('messages').doc(messageId).update(updateData);
  }

  // מחיקת הודעה (רק עבור צוות)
  Future<void> deleteMessage(String messageId, UserRole deleterRole) async {
    if (deleterRole != UserRole.staff) {
      throw Exception('רק אנשי צוות רשאים למחוק הודעות');
    }

    await _firestore.collection('messages').doc(messageId).delete();
  }

  // חיפוש משתמש לפי כתובת מייל
  Future<String?> findUserIdByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      return null;
    } catch (e) {
      throw Exception('שגיאה בחיפוש משתמש לפי מייל: $e');
    }
  }

  // ✅ Helper method to get all user IDs
  Future<List<String>> _getAllUserIds() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting all user IDs: $e');
      return [];
    }
  }
}
