import 'package:flutter_test/flutter_test.dart';
import 'package:knafayim_app/data/models/user.dart';
import 'package:knafayim_app/data/models/notification.dart';
import 'package:knafayim_app/data/models/calendar_event.dart';
import 'package:knafayim_app/data/models/message.dart';
import 'package:knafayim_app/data/models/report.dart';

void main() {
  group('User Model Tests', () {
    test('User creation and properties', () {
      final user = User(
        id: '1',
        name: 'ישראל ישראלי',
        email: 'israel@example.com',
        phoneNumber: '0501234567',
        role: UserRole.client,
        createdAt: DateTime.now(),
        additionalInfo: {'address': 'תל אביב'},
      );

      expect(user.id, '1');
      expect(user.name, 'ישראל ישראלי');
      expect(user.email, 'israel@example.com');
      expect(user.phoneNumber, '0501234567');
      expect(user.role, UserRole.client);
      expect(user.additionalInfo['address'], 'תל אביב');
    });

    test('User copyWith method', () {
      final user = User(
        id: '1',
        name: 'ישראל ישראלי',
        email: 'israel@example.com',
        phoneNumber: '0501234567',
        role: UserRole.client,
        createdAt: DateTime.now(),
      );

      final updatedUser = user.copyWith(
        name: 'ישראל כהן',
        phoneNumber: '0507654321',
      );

      expect(updatedUser.id, '1');
      expect(updatedUser.name, 'ישראל כהן');
      expect(updatedUser.email, 'israel@example.com');
      expect(updatedUser.phoneNumber, '0507654321');
      expect(updatedUser.role, UserRole.client);
    });
  });

  group('Notification Model Tests', () {
    test('Notification creation and properties', () {
      final notification = Notification(
        id: '1',
        userId: '2',
        title: 'פגישה חדשה',
        content: 'נקבעה לך פגישה חדשה',
        timestamp: DateTime.now(),
        type: NotificationType.reminder,
        isRead: false,
      );

      expect(notification.id, '1');
      expect(notification.userId, '2');
      expect(notification.title, 'פגישה חדשה');
      expect(notification.content, 'נקבעה לך פגישה חדשה');
      expect(notification.type, NotificationType.reminder);
      expect(notification.isRead, false);
    });

    test('Notification markAsRead method', () {
      final notification = Notification(
        id: '1',
        userId: '2',
        title: 'פגישה חדשה',
        content: 'נקבעה לך פגישה חדשה',
        timestamp: DateTime.now(),
        type: NotificationType.reminder,
        isRead: false,
      );

      final readNotification = notification.markAsRead();
      expect(readNotification.isRead, true);
    });
  });

  group('CalendarEvent Model Tests', () {
    test('CalendarEvent creation and properties', () {
      final now = DateTime.now();
      final later = now.add(const Duration(hours: 1));

      final event = CalendarEvent(
        id: '1',
        title: 'פגישה עם מנחה',
        description: 'פגישה שבועית',
        startTime: now,
        endTime: later,
        createdById: '2',
        participantIds: ['2', '3'],
        type: EventType.meeting,
        locationOrLink: 'חדר 101',
        createdByName: '',
        createdAt: DateTime.now(),
      );

      expect(event.id, '1');
      expect(event.title, 'פגישה עם מנחה');
      expect(event.description, 'פגישה שבועית');
      expect(event.startTime, now);
      expect(event.endTime, later);
      expect(event.createdById, '2');
      expect(event.participantIds, ['2', '3']);
      expect(event.type, EventType.meeting);
      expect(event.locationOrLink, 'חדר 101');
    });

    test('CalendarEvent duration calculation', () {
      final now = DateTime.now();
      final later = now.add(const Duration(hours: 1, minutes: 30));

      final event = CalendarEvent(
        id: '1',
        title: 'פגישה עם מנחה',
        description: 'פגישה שבועית',
        startTime: now,
        endTime: later,
        createdById: '2',
        participantIds: ['2', '3'],
        type: EventType.meeting,
        createdByName: '',
        createdAt: DateTime.now(),
      );

      expect(event.durationInMinutes, 90);
    });
  });

  group('Message Model Tests', () {
    test('Message creation and properties', () {
      final now = DateTime.now();

      final message = Message(
        id: '1',
        content: 'שלום, מה שלומך?',
        senderId: '2',
        recipientIds: ['3'],
        timestamp: now,
        isRead: false,
        title: '',
        createdAt: DateTime.now(),
        createdBy: '',
      );

      expect(message.id, '1');
      expect(message.content, 'שלום, מה שלומך?');
      expect(message.senderId, '2');
      expect(message.recipientIds, ['3']);
      expect(message.timestamp, now);
      expect(message.isRead, false);
    });

    test('Message markAsRead method', () {
      final message = Message(
        id: '1',
        content: 'שלום, מה שלומך?',
        senderId: '2',
        recipientIds: ['3'],
        timestamp: DateTime.now(),
        isRead: false,
        title: '',
        createdAt: DateTime.now(),
        createdBy: '',
      );

      final readMessage = message.markAsRead();
      expect(readMessage.isRead, true);
    });
  });

  group('Report Model Tests', () {
    test('Report creation and properties', () {
      final now = DateTime.now();

      final report = Report(
        id: '1',
        title: 'דוח פגישה שבועית',
        content: 'תוכן הדוח',
        createdById: '2',
        createdByName: 'ישראל ישראלי',
        createdAt: now,
        type: ReportType.meeting,
        relatedUserIds: ['3', '4'],
      );

      expect(report.id, '1');
      expect(report.title, 'דוח פגישה שבועית');
      expect(report.content, 'תוכן הדוח');
      expect(report.createdById, '2');
      expect(report.createdByName, 'ישראל ישראלי');
      expect(report.createdAt, now);
      expect(report.type, ReportType.meeting);
      expect(report.relatedUserIds, ['3', '4']);
    });
  });
}
