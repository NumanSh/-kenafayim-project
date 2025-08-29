import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/notifications/notification_card.dart';
import '../../widgets/common/rtl_wrapper.dart';
import '../../../data/models/enhanced_notification.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ FIXED: Get current user and handle null case
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.currentUser;

    // ✅ FIXED: Handle null user case
    if (currentUser == null) {
      return RTLTextDirectionWrapper(
        child: Scaffold(
          appBar: AppBar(title: const Text('מרכז הודעות')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'יש להתחבר כדי לצפות בהתראות',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ FIXED: Use explicit user ID for notifications
    final notificationsAsync = ref.watch(
      userNotificationsProvider(currentUser.id),
    );
    final unreadCountAsync = ref.watch(
      unreadNotificationCountProvider(currentUser.id),
    );
    final actionsState = ref.watch(notificationActionsProvider);

    return RTLTextDirectionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.notifications_outlined),
              const SizedBox(width: 8),
              const Text('מרכז הודעות'),
              const Spacer(),
              unreadCountAsync.when(
                data: (count) => count > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleMenuAction(
                value,
                currentUser.id,
              ), // ✅ FIXED: Pass user ID
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read),
                      SizedBox(width: 8),
                      Text('סמן הכל כנקרא'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('הגדרות הודעות'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('נקה הכל'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            onTap: (index) => _onTabChanged(index),
            tabs: const [
              Tab(text: 'הכל', icon: Icon(Icons.all_inbox)),
              Tab(text: 'שיעורים', icon: Icon(Icons.school)),
              Tab(text: 'נוכחות', icon: Icon(Icons.how_to_reg)),
              Tab(text: 'ניהול', icon: Icon(Icons.admin_panel_settings)),
              Tab(text: 'דחופות', icon: Icon(Icons.priority_high)),
            ],
          ),
        ),
        body: Column(
          children: [
            if (actionsState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        actionsState.error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(notificationActionsProvider.notifier)
                          .clearError(),
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationsList(notificationsAsync, null),
                  _buildNotificationsList(
                    notificationsAsync,
                    _getLessonTypes(),
                  ),
                  _buildNotificationsList(
                    notificationsAsync,
                    _getAttendanceTypes(),
                  ),
                  _buildNotificationsList(notificationsAsync, _getAdminTypes()),
                  _buildNotificationsList(
                    notificationsAsync,
                    _getUrgentTypes(),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: actionsState.isLoading
            ? FloatingActionButton(
                onPressed: null,
                child: const CircularProgressIndicator(),
              )
            : null,
      ),
    );
  }

  Widget _buildNotificationsList(
    AsyncValue<List<EnhancedNotification>> notificationsAsync,
    List<NotificationType>? filterTypes,
  ) {
    return notificationsAsync.when(
      data: (notifications) {
        final filteredNotifications = filterTypes != null
            ? notifications.where((n) => filterTypes.contains(n.type)).toList()
            : notifications;

        if (filteredNotifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserNotificationsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onActionTap: (actionId) =>
                    _handleActionTap(notification, actionId),
                onDismiss: () => _handleDismiss(notification),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'שגיאה בטעינת ההודעות',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(currentUserNotificationsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'אין הודעות חדשות',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'כל ההודעות שלך יופיעו כאן',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabChanged(int index) {
    setState(() {
      switch (index) {
        case 0:
          _selectedFilter = null;
          break;
        case 1:
          _selectedFilter = NotificationType.lessonReminder24h;
          break;
        case 2:
          _selectedFilter = NotificationType.attendanceRequest;
          break;
        case 3:
          _selectedFilter = NotificationType.adminNewRegistration;
          break;
        case 4:
          _selectedFilter = NotificationType.emergency;
          break;
      }
    });
  }

  List<NotificationType> _getLessonTypes() => [
    NotificationType.lessonReminder24h,
    NotificationType.lessonReminder1h,
    NotificationType.seriesUpdate,
    NotificationType.seriesComplete,
  ];

  List<NotificationType> _getAttendanceTypes() => [
    NotificationType.attendanceRequest,
    NotificationType.attendanceMissing,
  ];

  List<NotificationType> _getAdminTypes() => [
    NotificationType.adminNewRegistration,
    NotificationType.adminAttendanceReport,
    NotificationType.mentorAssignment,
  ];

  List<NotificationType> _getUrgentTypes() => [
    NotificationType.emergency,
    NotificationType.realTimeUpdate,
  ];

  void _handleNotificationTap(EnhancedNotification notification) {
    // Mark as read
    ref.read(notificationActionsProvider.notifier).markAsRead(notification.id);

    // Navigate based on notification type
    _navigateToNotificationTarget(notification);
  }

  void _handleActionTap(EnhancedNotification notification, String actionId) {
    ref
        .read(notificationActionsProvider.notifier)
        .handleNotificationAction(
          notification: notification,
          actionId: actionId,
        );
  }

  void _handleDismiss(EnhancedNotification notification) {
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      ref
          .read(notificationActionsProvider.notifier)
          .deleteNotification(notification.id, currentUser.id);
    }
  }

  void _handleMenuAction(String action, String userId) {
    switch (action) {
      case 'mark_all_read':
        ref.read(notificationActionsProvider.notifier).markAllAsRead(userId);
        break;
      case 'settings':
        Navigator.pushNamed(context, '/notification-settings');
        break;
      case 'clear_all':
        _showClearAllDialog(userId);
        break;
    }
  }

  void _showClearAllDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק את כל ההודעות'),
        content: const Text(
          'האם אתה בטוח שברצונך למחוק את כל ההודעות? פעולה זו לא ניתנת לביטול.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear all functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('מחק הכל'),
          ),
        ],
      ),
    );
  }

  void _navigateToNotificationTarget(EnhancedNotification notification) {
    switch (notification.type) {
      case NotificationType.lessonReminder24h:
      case NotificationType.lessonReminder1h:
      case NotificationType.attendanceRequest:
        if (notification.lessonId != null) {
          Navigator.pushNamed(
            context,
            '/lesson-details',
            arguments: {'lessonId': notification.lessonId},
          );
        }
        break;
      case NotificationType.seriesUpdate:
      case NotificationType.seriesComplete:
        if (notification.seriesId != null) {
          Navigator.pushNamed(
            context,
            '/lesson-series',
            arguments: {'seriesId': notification.seriesId},
          );
        }
        break;
      case NotificationType.adminNewRegistration:
        Navigator.pushNamed(context, '/user-management');
        break;
      case NotificationType.adminAttendanceReport:
        Navigator.pushNamed(context, '/reports');
        break;
      default:
        // Handle other types or show notification details
        break;
    }
  }
}
