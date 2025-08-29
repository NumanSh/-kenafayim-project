import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/models/enhanced_notification.dart';
import '../data/models/notification_preference.dart';
import '../data/models/user.dart';
import '../data/models/lesson.dart';

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamController<EnhancedNotification>? _notificationStreamController;
  Stream<EnhancedNotification>? _notificationStream;

  // Hebrew notification templates
  static const Map<NotificationType, Map<String, String>> _hebrewTemplates = {
    NotificationType.lessonReminder24h: {
      'title': 'תזכורת שיעור',
      'content': 'שיעור מחר: {lessonTitle} ב-{time}',
    },
    NotificationType.lessonReminder1h: {
      'title': 'שיעור בקרוב',
      'content': 'שיעור בעוד שעה: {lessonTitle}',
    },
    NotificationType.attendanceRequest: {
      'title': 'אישור נוכחות',
      'content': 'נא לאשר נוכחות לשיעור {lessonTitle}',
    },
    NotificationType.attendanceMissing: {
      'title': 'נוכחות חסרה',
      'content': 'אמן {artistName} לא אישר נוכחות לשיעור {lessonTitle}',
    },
    NotificationType.seriesComplete: {
      'title': 'סיום סדרה! 🎉',
      'content': 'סיימת את סדרת השיעורים {seriesName}!',
    },
    NotificationType.adminNewRegistration: {
      'title': 'רישום חדש',
      'content': 'משתמש חדש נרשם: {userName}',
    },
    NotificationType.mentorAssignment: {
      'title': 'שיעור חדש',
      'content': 'הוקצה לך שיעור חדש: {lessonTitle}',
    },
    NotificationType.emergency: {
      'title': 'הודעה דחופה ⚠️',
      'content': '{message}',
    },
  };

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    _setupNotificationStream();
    await _requestPermissions();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // ✅ FIXED: Handle foreground messages to show notifications
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Get initial message if app was opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  void _setupNotificationStream() {
    _notificationStreamController =
        StreamController<EnhancedNotification>.broadcast();
    _notificationStream = _notificationStreamController!.stream;
  }

  Stream<EnhancedNotification> get notificationStream => _notificationStream!;

  Future<void> _requestPermissions() async {
    // Request FCM permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('FCM Permission status: ${settings.authorizationStatus}');
    }

    // Request local notification permissions for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // Send lesson reminder notifications
  Future<void> scheduleLessonReminders(
    Lesson lesson,
    List<String> participantIds,
  ) async {
    for (final userId in participantIds) {
      final preferences = await _getUserPreferences(userId);

      if (!preferences.lessonReminders) continue;

      // Schedule 24h reminder
      await _scheduleLessonReminder(
        lesson: lesson,
        userId: userId,
        type: NotificationType.lessonReminder24h,
        hoursBeforeLesson: preferences.reminderHours24,
      );

      // Schedule 1h reminder
      await _scheduleLessonReminder(
        lesson: lesson,
        userId: userId,
        type: NotificationType.lessonReminder1h,
        hoursBeforeLesson: preferences.reminderHours1,
      );
    }
  }

  Future<void> _scheduleLessonReminder({
    required Lesson lesson,
    required String userId,
    required NotificationType type,
    required int hoursBeforeLesson,
  }) async {
    // Use lesson.date as the start time
    final scheduledTime = lesson.date.subtract(
      Duration(hours: hoursBeforeLesson),
    );

    // Don't schedule if time has passed
    if (scheduledTime.isBefore(DateTime.now())) return;

    final template = _hebrewTemplates[type]!;
    final notification = EnhancedNotification(
      id: '${lesson.id}_${type.toString()}_$userId',
      userId: userId,
      title: template['title']!,
      content: template['content']!
          .replaceAll('{lessonTitle}', lesson.title)
          .replaceAll('{time}', _formatTime(lesson.date)),
      timestamp: DateTime.now(),
      type: type,
      priority: NotificationPriority.normal,
      isScheduled: true,
      scheduledFor: scheduledTime,
      lessonId: lesson.id,
      actions: [
        NotificationAction(
          id: 'view_lesson',
          title: 'צפה בשיעור',
          action: 'view_lesson',
          data: {'lessonId': lesson.id},
        ),
        NotificationAction(
          id: 'mark_present',
          title: 'סמן נוכח',
          action: 'mark_present',
          data: {'lessonId': lesson.id, 'userId': userId},
        ),
      ],
    );

    await _saveNotification(notification);
    await _scheduleLocalNotification(notification);
  }

  // Send attendance notifications
  Future<void> sendAttendanceRequest(Lesson lesson, String artistId) async {
    final preferences = await _getUserPreferences(artistId);
    if (!preferences.attendanceNotifications) return;

    final template = _hebrewTemplates[NotificationType.attendanceRequest]!;
    final notification = EnhancedNotification(
      id: 'attendance_${lesson.id}_$artistId',
      userId: artistId,
      title: template['title']!,
      content: template['content']!.replaceAll('{lessonTitle}', lesson.title),
      timestamp: DateTime.now(),
      type: NotificationType.attendanceRequest,
      priority: NotificationPriority.high,
      lessonId: lesson.id,
      actions: [
        NotificationAction(
          id: 'mark_present',
          title: 'נוכח',
          action: 'mark_present',
          data: {
            'lessonId': lesson.id,
            'userId': artistId,
            'status': 'present',
          },
        ),
        NotificationAction(
          id: 'mark_absent',
          title: 'נעדר',
          action: 'mark_absent',
          data: {'lessonId': lesson.id, 'userId': artistId, 'status': 'absent'},
        ),
      ],
    );

    await _sendNotification(notification);
  }

  Future<void> sendAttendanceMissingAlert(
    Lesson lesson,
    String artistId,
    String mentorId,
  ) async {
    final artist = await _getUser(artistId);
    if (artist == null) return;

    final preferences = await _getUserPreferences(mentorId);
    if (!preferences.attendanceNotifications) return;

    final template = _hebrewTemplates[NotificationType.attendanceMissing]!;
    final notification = EnhancedNotification(
      id: 'missing_${lesson.id}_${artistId}_$mentorId',
      userId: mentorId,
      title: template['title']!,
      content: template['content']!
          .replaceAll('{artistName}', artist.name)
          .replaceAll('{lessonTitle}', lesson.title),
      timestamp: DateTime.now(),
      type: NotificationType.attendanceMissing,
      priority: NotificationPriority.high,
      lessonId: lesson.id,
      actions: [
        NotificationAction(
          id: 'contact_artist',
          title: 'צור קשר',
          action: 'contact_artist',
          data: {'artistId': artistId},
        ),
        NotificationAction(
          id: 'mark_for_artist',
          title: 'סמן עבור האמן',
          action: 'mark_attendance',
          data: {'lessonId': lesson.id, 'userId': artistId},
        ),
      ],
    );

    await _sendNotification(notification);
  }

  // Send recurring series notifications
  Future<void> sendSeriesUpdateNotification({
    required List<String> userIds,
    required String seriesName,
    required String updateMessage,
  }) async {
    for (final userId in userIds) {
      final preferences = await _getUserPreferences(userId);
      if (!preferences.seriesUpdates) continue;

      final notification = EnhancedNotification(
        id: 'series_update_${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        title: 'עדכון סדרת שיעורים',
        content: 'שינוי בסדרת השיעורים $seriesName: $updateMessage',
        timestamp: DateTime.now(),
        type: NotificationType.seriesUpdate,
        priority: NotificationPriority.normal,
      );

      await _sendNotification(notification);
    }
  }

  Future<void> sendSeriesCompleteNotification(
    String userId,
    String seriesName,
  ) async {
    final preferences = await _getUserPreferences(userId);
    if (!preferences.seriesUpdates) return;

    final template = _hebrewTemplates[NotificationType.seriesComplete]!;
    final notification = EnhancedNotification(
      id: 'series_complete_${DateTime.now().millisecondsSinceEpoch}_$userId',
      userId: userId,
      title: template['title']!,
      content: template['content']!.replaceAll('{seriesName}', seriesName),
      timestamp: DateTime.now(),
      type: NotificationType.seriesComplete,
      priority: NotificationPriority.high,
      actions: [
        NotificationAction(
          id: 'view_certificate',
          title: 'צפה בתעודה',
          action: 'view_certificate',
          data: {'seriesName': seriesName},
        ),
      ],
    );

    await _sendNotification(notification);
  }

  // Send real-time notifications
  Future<void> sendRealTimeUpdate({
    required List<String> userIds,
    required String title,
    required String content,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
  }) async {
    for (final userId in userIds) {
      final preferences = await _getUserPreferences(userId);
      if (!preferences.realTimeUpdates) continue;

      final notification = EnhancedNotification(
        id: 'realtime_${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        type: NotificationType.realTimeUpdate,
        priority: priority,
        metadata: data,
      );

      await _sendNotification(notification);
    }
  }

  // Emergency notifications
  Future<void> sendEmergencyNotification({
    required List<String> userIds,
    required String message,
  }) async {
    final template = _hebrewTemplates[NotificationType.emergency]!;

    for (final userId in userIds) {
      final notification = EnhancedNotification(
        id: 'emergency_${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        title: template['title']!,
        content: template['content']!.replaceAll('{message}', message),
        timestamp: DateTime.now(),
        type: NotificationType.emergency,
        priority: NotificationPriority.urgent,
      );

      await _sendNotification(notification);
    }
  }

  // Core notification sending
  Future<void> _sendNotification(EnhancedNotification notification) async {
    // ✅ FIRST: Save to Firestore (this was missing!)
    await _saveNotification(notification);
    print('✅ Notification saved to Firestore: ${notification.id}');

    // ✅ SECOND: Send local notification (for immediate display)
    await _sendLocalNotification(notification);
    print('✅ Local notification sent');

    // ✅ THIRD: Send push notification (for background delivery)
    await _sendPushNotification(notification);
    print('✅ Push notification queued');

    // ✅ FOURTH: Add to stream (for real-time updates)
    _notificationStreamController?.add(notification);
    print('✅ Notification added to stream');
  }

  Future<void> _sendLocalNotification(EnhancedNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      'knafayim_${notification.type.toString()}',
      _getChannelName(notification.type),
      channelDescription: _getChannelDescription(notification.type),
      importance: Importance.max, // ✅ CHANGED: Max importance
      priority: Priority.high, // ✅ CHANGED: High priority
      showWhen: true,
      enableVibration: true,
      enableLights: true, // ✅ ADDED: Enable lights
      playSound: true, // ✅ ADDED: Enable sound
      actions: notification.actions
          .map((action) => AndroidNotificationAction(action.id, action.title))
          .toList(),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ✅ Create serializable version for payload
    final serializableNotification = {
      'id': notification.id,
      'userId': notification.userId,
      'title': notification.title,
      'content': notification.content,
      'timestamp': notification.timestamp.millisecondsSinceEpoch,
      'type': notification.type.toString().split('.').last,
      'priority': notification.priority.toString().split('.').last,
      'lessonId': notification.lessonId,
      'seriesId': notification.seriesId,
      'actions': notification.actions.map((action) => action.toMap()).toList(),
      'metadata': notification.metadata,
    };

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.content,
      details,
      payload: jsonEncode(serializableNotification),
    );
  }

  Future<void> _scheduleLocalNotification(
    EnhancedNotification notification,
  ) async {
    if (notification.scheduledFor == null) return;

    final scheduledDate = tz.TZDateTime.from(
      notification.scheduledFor!,
      tz.local,
    );

    final androidDetails = AndroidNotificationDetails(
      'knafayim_scheduled',
      'שיעורים מתוזמנים',
      channelDescription: 'תזכורות לשיעורים קרובים',
      importance: Importance.high,
      priority: Priority.high,
      actions: notification.actions
          .map((action) => AndroidNotificationAction(action.id, action.title))
          .toList(),
    );

    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ✅ FIXED: Create serializable version for scheduled notifications too
    final serializableNotification = {
      'id': notification.id,
      'userId': notification.userId,
      'title': notification.title,
      'content': notification.content,
      'timestamp': notification.timestamp.millisecondsSinceEpoch,
      'scheduledFor': notification.scheduledFor?.millisecondsSinceEpoch,
      'type': notification.type.toString().split('.').last,
      'priority': notification.priority.toString().split('.').last,
      'lessonId': notification.lessonId,
      'seriesId': notification.seriesId,
      'actions': notification.actions.map((action) => action.toMap()).toList(),
      'metadata': notification.metadata,
    };

    await _localNotifications.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.content,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(serializableNotification),
    );
  }

  Future<void> _sendPushNotification(EnhancedNotification notification) async {
    final userToken = await _getUserFCMToken(notification.userId);
    if (userToken == null) {
      print('⚠️ No FCM token found for user: ${notification.userId}');
      return;
    }

    // ✅ FIXED: Send proper FCM message with notification payload
    await _firestore.collection('push_notifications').add({
      'to': userToken,
      'notification': {
        'title': notification.title,
        'body': notification.content,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      'data': {
        'notificationId': notification.id,
        'type': notification.type.toString(),
        'userId': notification.userId,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      'android': {
        'priority': 'high',
        'notification': {
          'channel_id': 'knafayim_notifications',
          'priority': 'high',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      'timestamp': FieldValue.serverTimestamp(),
    });

    print(
      '✅ Push notification queued for token: ${userToken.substring(0, 20)}...',
    );
  }

  // Helper methods
  Future<void> _saveNotification(EnhancedNotification notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  Future<NotificationPreference> _getUserPreferences(String userId) async {
    final doc = await _firestore
        .collection('notification_preferences')
        .doc(userId)
        .get();
    if (doc.exists) {
      return NotificationPreference.fromMap(doc.data()!);
    }
    return NotificationPreference(userId: userId);
  }

  Future<User?> _getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return User.fromMap(doc.data()!);
    }
    return null;
  }

  Future<String?> _getUserFCMToken(String userId) async {
    final doc = await _firestore.collection('user_tokens').doc(userId).get();
    return doc.data()?['fcmToken'];
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.lessonReminder24h:
      case NotificationType.lessonReminder1h:
        return 'תזכורות שיעורים';
      case NotificationType.attendanceRequest:
      case NotificationType.attendanceMissing:
        return 'נוכחות';
      case NotificationType.emergency:
        return 'הודעות דחופות';
      default:
        return 'הודעות כלליות';
    }
  }

  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.lessonReminder24h:
      case NotificationType.lessonReminder1h:
        return 'תזכורות לשיעורים קרובים';
      case NotificationType.attendanceRequest:
      case NotificationType.attendanceMissing:
        return 'הודעות נוכחות';
      case NotificationType.emergency:
        return 'הודעות דחופות וחשובות';
      default:
        return 'הודעות כלליות מהמערכת';
    }
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final notificationData = jsonDecode(response.payload!);
      final notification = EnhancedNotification.fromMap(notificationData);
      _handleNotificationAction(notification, response.actionId);
    }
  }

  void _handleNotificationAction(
    EnhancedNotification notification,
    String? actionId,
  ) {
    // Handle notification actions - this will be implemented with navigation
    if (kDebugMode) {
      print(
        'Notification action: $actionId for notification: ${notification.id}',
      );
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Background message: ${message.messageId}');
    }
  }

  // Add this method to your EnhancedNotificationService class
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print(
      '🔔 Foreground notification received: ${message.notification?.title}',
    );

    // Show local notification when app is in foreground
    if (message.notification != null) {
      await _localNotifications.show(
        message.hashCode,
        message.notification!.title ?? 'New Notification',
        message.notification!.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'foreground_channel',
            'Foreground Notifications',
            channelDescription: 'Notifications shown when app is open',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('Message opened app: ${message.messageId}');
    }
  }

  // Cleanup
  void dispose() {
    _notificationStreamController?.close();
  }

  // Add this method to save FCM tokens when users log in
  Future<void> registerUserFCMToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('user_tokens').doc(userId).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
          'platform': 'android', // or detect platform
        }, SetOptions(merge: true));

        print('✅ FCM Token registered for user: $userId');
        print('🔑 Token: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ Error registering FCM token: $e');
    }
  }

  // Add this debug method
  Future<void> debugNotificationFlow(
    String userId,
    String title,
    String content,
  ) async {
    print('🔍 DEBUG: Starting notification flow...');

    // Check if user exists
    final userDoc = await _firestore.collection('users').doc(userId).get();
    print('🔍 DEBUG: User exists: ${userDoc.exists}');

    // Check if FCM token exists
    final tokenDoc = await _firestore
        .collection('user_tokens')
        .doc(userId)
        .get();
    print('🔍 DEBUG: FCM token exists: ${tokenDoc.exists}');
    if (tokenDoc.exists) {
      print(
        '🔍 DEBUG: FCM token: ${tokenDoc.data()?['fcmToken']?.substring(0, 20)}...',
      );
    }

    // Try to create and save a test notification
    try {
      final testNotification = EnhancedNotification(
        id: 'debug_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        type: NotificationType.message,
      );

      print('🔍 DEBUG: Created notification object');

      // Try to save to Firestore
      await _firestore
          .collection('notifications')
          .doc(testNotification.id)
          .set(testNotification.toMap());
      print('🔍 DEBUG: ✅ Notification saved to Firestore');

      // Try to send local notification
      await _sendLocalNotification(testNotification);
      print('🔍 DEBUG: ✅ Local notification sent');
    } catch (e) {
      print('🔍 DEBUG: ❌ Error in notification flow: $e');
    }
  }
}
