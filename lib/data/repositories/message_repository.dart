import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/user.dart';

class MessageRepository {
  final FirebaseFirestore _firestore;

  MessageRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Message>> getMessagesForUser(String userId, {String? userEmail, int limit = 50}) async {
    try {
      // קבלת כל ההודעות
      final allMessages = await _firestore
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();
      
      // סינון ההודעות בזיכרון
      final filteredMessages = allMessages.docs
          .map((doc) => Message.fromMap({...doc.data(), 'id': doc.id}))
          .where((message) => 
            // הודעה מיועדת למשתמש הספציפי לפי ID
            message.recipientIds.contains(userId) || 
            // או הודעה כללית (ללא נמענים)
            message.recipientIds.isEmpty || 
            // או הודעה שנשלחה על ידי המשתמש
            message.senderId == userId ||
            // או הודעה מיועדת למשתמש לפי כתובת מייל
            (userEmail != null && message.recipientEmail == userEmail)
          )
          .take(limit)
          .toList();
      
      return filteredMessages;
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  Future<List<Message>> getConversation(String userId1, String userId2, {int limit = 50}) async {
    try {
      // Modify the queries to avoid requiring composite indexes
      // Get messages from user1 to user2
      final messages1 = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId1)
          .get();
      
      // Filter in memory for messages where user2 is a recipient
      final filteredMessages1 = messages1.docs
          .where((doc) => (doc.data()['recipientIds'] as List<dynamic>).contains(userId2))
          .map((doc) => Message.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      
      // Get messages from user2 to user1
      final messages2 = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId2)
          .get();
      
      // Filter in memory for messages where user1 is a recipient
      final filteredMessages2 = messages2.docs
          .where((doc) => (doc.data()['recipientIds'] as List<dynamic>).contains(userId1))
          .map((doc) => Message.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      
      // Combine both directions of messages
      final allMessages = [...filteredMessages1, ...filteredMessages2];
      
      // Sort by timestamp descending in memory
      allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Limit the results after sorting
      return allMessages.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  Future<Message> sendMessage(Message message, UserRole senderRole) async {
    try {
      // בדיקה שהשולח הוא איש צוות
      if (senderRole != UserRole.staff) {
        throw Exception('רק אנשי צוות רשאים להוסיף הודעות');
      }
      
      final docRef = await _firestore.collection('messages').add(message.toMap());
      return Message.fromMap({...message.toMap(), 'id': docRef.id});
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'readBy': FieldValue.arrayUnion([userId]),
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  Future<void> updateMessage(String messageId, Map<String, dynamic> updateData, UserRole updaterRole) async {
    try {
      // בדיקה שהמעדכן הוא איש צוות
      if (updaterRole != UserRole.staff) {
        throw Exception('רק אנשי צוות רשאים לעדכן הודעות');
      }
      
      // טיפול בשדה recipientIds - אם הוא רשימה, נמיר אותו למחרוזת מופרדת בפסיקים
      if (updateData.containsKey('recipientIds') && updateData['recipientIds'] is List<String>) {
        updateData['recipientIds'] = (updateData['recipientIds'] as List<String>).join(',');
      }
      
      // טיפול בשדה recipientEmail - אם הוא null, נמחק אותו מהמילון
      if (updateData.containsKey('recipientEmail') && updateData['recipientEmail'] == null) {
        updateData.remove('recipientEmail');
      }
      
      await _firestore.collection('messages').doc(messageId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  Future<void> deleteMessage(String messageId, UserRole deleterRole) async {
    try {
      // בדיקה שהמוחק הוא איש צוות
      if (deleterRole != UserRole.staff) {
        throw Exception('רק אנשי צוות רשאים למחוק הודעות');
      }
      
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
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

