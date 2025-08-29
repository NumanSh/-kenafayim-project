import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/enhanced_notification.dart';
import '../models/notification_preference.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user notifications with pagination
  Stream<List<EnhancedNotification>> getUserNotifications(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    Query query = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return EnhancedNotification.fromMap(data);
      }).toList();
    });
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
      rethrow;
    }
  }

  // Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
      rethrow;
    }
  }

  // Delete all notifications for user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final userNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all notifications: $e');
      }
      rethrow;
    }
  }

  // Get notification preferences
  Future<NotificationPreference> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('notification_preferences')
          .doc(userId)
          .get();

      if (doc.exists) {
        return NotificationPreference.fromMap(doc.data()!);
      }

      // Return default preferences if none exist
      final defaultPrefs = NotificationPreference(userId: userId);
      await saveUserPreferences(defaultPrefs);
      return defaultPrefs;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user preferences: $e');
      }
      return NotificationPreference(userId: userId);
    }
  }

  // Save notification preferences
  Future<void> saveUserPreferences(NotificationPreference preferences) async {
    try {
      await _firestore
          .collection('notification_preferences')
          .doc(preferences.userId)
          .set(preferences.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user preferences: $e');
      }
      rethrow;
    }
  }

  // Get notifications by type
  Stream<List<EnhancedNotification>> getNotificationsByType(
    String userId,
    NotificationType type, {
    int limit = 10,
  }) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return EnhancedNotification.fromMap(data);
          }).toList();
        });
  }

  // Get scheduled notifications
  Future<List<EnhancedNotification>> getScheduledNotifications(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isScheduled', isEqualTo: true)
          .where('scheduledFor', isGreaterThan: Timestamp.now())
          .orderBy('scheduledFor')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return EnhancedNotification.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting scheduled notifications: $e');
      }
      return [];
    }
  }

  // Cancel scheduled notification
  Future<void> cancelScheduledNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling scheduled notification: $e');
      }
      rethrow;
    }
  }

  // Get notification statistics
  Future<Map<String, int>> getNotificationStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'total': snapshot.docs.length,
        'unread': 0,
        'lessonReminders': 0,
        'attendance': 0,
        'admin': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['isRead'] == false) {
          stats['unread'] = stats['unread']! + 1;
        }

        final type = data['type'] as String?;
        if (type != null) {
          if (type.contains('lessonReminder')) {
            stats['lessonReminders'] = stats['lessonReminders']! + 1;
          } else if (type.contains('attendance')) {
            stats['attendance'] = stats['attendance']! + 1;
          } else if (type.contains('admin')) {
            stats['admin'] = stats['admin']! + 1;
          }
        }
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification stats: $e');
      }
      return {
        'total': 0,
        'unread': 0,
        'lessonReminders': 0,
        'attendance': 0,
        'admin': 0,
      };
    }
  }

  // Save FCM token for user
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('user_tokens').doc(userId).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
      rethrow;
    }
  }

  // Remove FCM token
  Future<void> removeFCMToken(String userId) async {
    try {
      await _firestore.collection('user_tokens').doc(userId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing FCM token: $e');
      }
      rethrow;
    }
  }
}
