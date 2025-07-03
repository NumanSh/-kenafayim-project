import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/presentation/providers/lesson_providers.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/models/enhanced_notification.dart';
import '../../data/models/notification_preference.dart';
import '../../services/enhanced_notification_service.dart';
import '../../services/auth_service.dart'; // Use your existing auth service

// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// Notification service provider
final notificationServiceProvider = Provider<EnhancedNotificationService>((
  ref,
) {
  return EnhancedNotificationService();
});

// Auth service provider (using your existing auth service)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(userRepository: ref.read(userRepositoryProvider));
});

// Current user notifications stream
final userNotificationsProvider =
    StreamProvider.family<List<EnhancedNotification>, String>((ref, userId) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getUserNotifications(userId);
    });

// Unread notification count
final unreadNotificationCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadNotificationCount(userId);
});

// Notification preferences
final notificationPreferencesProvider =
    FutureProvider.family<NotificationPreference, String>((ref, userId) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getUserPreferences(userId);
    });

// Notification statistics
final notificationStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, userId) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationStats(userId);
    });

// Scheduled notifications
final scheduledNotificationsProvider =
    FutureProvider.family<List<EnhancedNotification>, String>((ref, userId) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getScheduledNotifications(userId);
    });

// Notifications by type
final notificationsByTypeProvider =
    StreamProvider.family<List<EnhancedNotification>, NotificationTypeQuery>((
      ref,
      query,
    ) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationsByType(
        query.userId,
        query.type,
        limit: query.limit,
      );
    });

// Real-time notification stream
final realTimeNotificationProvider = StreamProvider<EnhancedNotification>((
  ref,
) {
  final service = ref.watch(notificationServiceProvider);
  return service.notificationStream;
});

// Notification actions state notifier
final notificationActionsProvider =
    StateNotifierProvider<
      NotificationActionsNotifier,
      NotificationActionsState
    >((ref) => NotificationActionsNotifier(ref));

// Helper class for notification type queries
class NotificationTypeQuery {
  final String userId;
  final NotificationType type;
  final int limit;

  NotificationTypeQuery({
    required this.userId,
    required this.type,
    this.limit = 10,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeQuery &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          type == other.type &&
          limit == other.limit;

  @override
  int get hashCode => userId.hashCode ^ type.hashCode ^ limit.hashCode;
}

// Notification actions state
class NotificationActionsState {
  final bool isLoading;
  final String? error;
  final Map<String, bool> actionStates;

  NotificationActionsState({
    this.isLoading = false,
    this.error,
    this.actionStates = const {},
  });

  NotificationActionsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, bool>? actionStates,
  }) {
    return NotificationActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      actionStates: actionStates ?? this.actionStates,
    );
  }
}

// Notification actions notifier
class NotificationActionsNotifier
    extends StateNotifier<NotificationActionsState> {
  final Ref _ref;

  NotificationActionsNotifier(this._ref) : super(NotificationActionsState());

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.markAsRead(notificationId);

      final newActionStates = Map<String, bool>.from(state.actionStates);
      newActionStates[notificationId] = true;

      state = state.copyWith(isLoading: false, actionStates: newActionStates);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'שגיאה בסימון ההודעה כנקראה: $e',
      );
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.markAllAsRead(userId);

      state = state.copyWith(isLoading: false);

      // Refresh notifications
      _ref.invalidate(userNotificationsProvider(userId));
      _ref.invalidate(unreadNotificationCountProvider(userId));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'שגיאה בסימון כל ההודעות כנקראו: $e',
      );
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId, String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.deleteNotification(notificationId);

      state = state.copyWith(isLoading: false);

      // Refresh notifications
      _ref.invalidate(userNotificationsProvider(userId));
      _ref.invalidate(unreadNotificationCountProvider(userId));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'שגיאה במחיקת ההודעה: $e',
      );
    }
  }

  // Save notification preferences
  Future<void> savePreferences(NotificationPreference preferences) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.saveUserPreferences(preferences);

      state = state.copyWith(isLoading: false);

      // Refresh preferences
      _ref.invalidate(notificationPreferencesProvider(preferences.userId));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'שגיאה בשמירת העדפות ההודעות: $e',
      );
    }
  }

  // Handle notification action (mark present, view lesson, etc.)
  Future<void> handleNotificationAction({
    required EnhancedNotification notification,
    required String actionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final action = notification.actions.firstWhere((a) => a.id == actionId);

      switch (action.action) {
        case 'mark_present':
          await _handleMarkPresent(action.data);
          break;
        case 'mark_absent':
          await _handleMarkAbsent(action.data);
          break;
        case 'view_lesson':
          await _handleViewLesson(action.data);
          break;
        case 'contact_artist':
          await _handleContactArtist(action.data);
          break;
        default:
          throw Exception('פעולה לא נתמכת: ${action.action}');
      }

      // Mark notification as read after action
      await markAsRead(notification.id);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'שגיאה בביצוע הפעולה: $e',
      );
    }
  }

  Future<void> _handleMarkPresent(Map<String, dynamic>? data) async {
    if (data == null) return;

    final lessonId = data['lessonId'] as String?;
    final userId = data['userId'] as String?;

    if (lessonId != null && userId != null) {
      // This would integrate with your attendance system
      // For now, we'll just mark it in the action states
      final newActionStates = Map<String, bool>.from(state.actionStates);
      newActionStates['${lessonId}_${userId}_present'] = true;

      state = state.copyWith(actionStates: newActionStates);
    }
  }

  Future<void> _handleMarkAbsent(Map<String, dynamic>? data) async {
    if (data == null) return;

    final lessonId = data['lessonId'] as String?;
    final userId = data['userId'] as String?;

    if (lessonId != null && userId != null) {
      // This would integrate with your attendance system
      final newActionStates = Map<String, bool>.from(state.actionStates);
      newActionStates['${lessonId}_${userId}_absent'] = true;

      state = state.copyWith(actionStates: newActionStates);
    }
  }

  Future<void> _handleViewLesson(Map<String, dynamic>? data) async {
    if (data == null) return;

    final lessonId = data['lessonId'] as String?;
    if (lessonId != null) {
      // This would navigate to lesson details
      // Implementation depends on your navigation system
    }
  }

  Future<void> _handleContactArtist(Map<String, dynamic>? data) async {
    if (data == null) return;

    final artistId = data['artistId'] as String?;
    if (artistId != null) {
      // This would open contact/message screen
      // Implementation depends on your messaging system
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Convenience providers for current user
final currentUserNotificationsProvider =
    StreamProvider<List<EnhancedNotification>>((ref) {
      final authService = ref.watch(authServiceProvider);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        return Stream.value(<EnhancedNotification>[]);
      }

      return ref.watch(
        userNotificationsProvider(currentUser.id)
            as ProviderListenable<Stream<List<EnhancedNotification>>>,
      );
    });

final currentUserUnreadCountProvider = StreamProvider<int>((ref) {
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.currentUser;

  if (currentUser == null) {
    return Stream.value(0);
  }

  return ref.watch(
    unreadNotificationCountProvider(currentUser.id)
        as ProviderListenable<Stream<int>>,
  );
});
