import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/message.dart';
import '../data/models/user.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // הוספת הודעה חדשה (רק עבור צוות)
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

    await _firestore.collection('messages').add({
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'readBy': [],
      'senderId': senderId,
      'recipientIds': recipientIds, // Keep as List<String>
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'recipientEmail': recipientEmail,
    });
  }

  // סימון הודעה כנקראה
  Future<void> markAsRead(String messageId, String userId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  // עדכון הודעה קיימת (רק עבור צוות) - FIXED
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

    // הוספת שדות אופציונליים אם הם קיימים
    if (recipientEmail != null) {
      updateData['recipientEmail'] = recipientEmail;
    }

    if (recipientIds != null) {
      // ✅ FIXED: Keep as List<String>, don't convert to String
      updateData['recipientIds'] = recipientIds;
    }

    await _firestore.collection('messages').doc(messageId).update(updateData);
  }

  // מחיקת הודעה (רק עבור צוות)
  Future<void> deleteMessage(String messageId, UserRole deleterRole) async {
    // בדיקה שהמוחק הוא איש צוות
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
}
