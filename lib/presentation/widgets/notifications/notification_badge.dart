import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/data/models/enhanced_notification.dart';
import '../../providers/notification_providers.dart';

class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final String? userId;
  final bool showZero;
  final Color? badgeColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;

  const NotificationBadge({
    super.key,
    required this.child,
    this.userId,
    this.showZero = false,
    this.badgeColor,
    this.textColor,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Use current user if userId not provided
    final unreadCountAsync = userId != null
        ? ref.watch(unreadNotificationCountProvider(userId!))
        : ref.watch(currentUserUnreadCountProvider);

    return unreadCountAsync.when(
      data: (count) {
        if (count == 0 && !showZero) {
          return child;
        }

        return Badge(
          label: Text(
            count > 99 ? '99+' : count.toString(),
            style: TextStyle(
              color: textColor ?? theme.colorScheme.onError,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: badgeColor ?? theme.colorScheme.error,
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: child,
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

// Specialized badge for navigation items
class NavigationNotificationBadge extends ConsumerWidget {
  final Widget child;
  final String? userId;

  const NavigationNotificationBadge({
    super.key,
    required this.child,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationBadge(userId: userId, child: child);
  }
}

// Badge for app icon (shows total unread count)
class AppIconNotificationBadge extends ConsumerWidget {
  final Widget child;

  const AppIconNotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(currentUserUnreadCountProvider);

    return unreadCountAsync.when(
      data: (count) {
        // Update app badge count (platform-specific implementation would go here)
        _updateAppBadgeCount(count);
        return child;
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }

  void _updateAppBadgeCount(int count) {
    // Platform-specific implementation for updating app icon badge
    // This would use flutter_app_badger or similar package
    // For now, this is a placeholder
  }
}

// Floating notification badge for real-time updates
class FloatingNotificationBadge extends ConsumerStatefulWidget {
  final Widget child;

  const FloatingNotificationBadge({super.key, required this.child});

  @override
  ConsumerState<FloatingNotificationBadge> createState() =>
      _FloatingNotificationBadgeState();
}

class _FloatingNotificationBadgeState
    extends ConsumerState<FloatingNotificationBadge>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen to real-time notifications
    ref.listen(realTimeNotificationProvider, (previous, next) {
      next.whenData((notification) {
        if (notification.priority == NotificationPriority.urgent ||
            notification.priority == NotificationPriority.high) {
          _showFloatingBadge(notification.title);
        }
      });
    });

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 16,
          left: 16,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'הודעה חדשה התקבלה',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _animationController.reverse(),
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFloatingBadge(String title) {
    _animationController.forward();

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }
}

// Custom badge for specific notification types
class TypedNotificationBadge extends ConsumerWidget {
  final Widget child;
  final NotificationType notificationType;
  final String? userId;

  const TypedNotificationBadge({
    super.key,
    required this.child,
    required this.notificationType,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // This would need a provider that filters by notification type
    // For now, we'll use the general unread count
    final unreadCountAsync = userId != null
        ? ref.watch(unreadNotificationCountProvider(userId!))
        : ref.watch(currentUserUnreadCountProvider);

    return unreadCountAsync.when(
      data: (count) {
        if (count == 0) return child;

        Color badgeColor;
        switch (notificationType) {
          case NotificationType.emergency:
            badgeColor = theme.colorScheme.error;
            break;
          case NotificationType.lessonReminder24h:
          case NotificationType.lessonReminder1h:
            badgeColor = theme.colorScheme.primary;
            break;
          case NotificationType.attendanceRequest:
          case NotificationType.attendanceMissing:
            badgeColor = theme.colorScheme.secondary;
            break;
          default:
            badgeColor = theme.colorScheme.outline;
        }

        return NotificationBadge(
          userId: userId,
          badgeColor: badgeColor,
          child: child,
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}
