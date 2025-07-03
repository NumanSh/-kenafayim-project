import 'package:flutter/material.dart';
import 'package:knafayim_app/presentation/widgets/common/rtl_wrapper.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/enhanced_notification.dart';

class NotificationCard extends StatelessWidget {
  final EnhancedNotification notification;
  final VoidCallback? onTap;
  final Function(String)? onActionTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onActionTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RTLTextDirectionWrapper(
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss?.call(),
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16),
          color: theme.colorScheme.error,
          child: Icon(Icons.delete, color: theme.colorScheme.onError),
        ),
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: notification.isRead ? 1 : 3,
          color: notification.isRead
              ? theme.colorScheme.surface
              : theme.colorScheme.primaryContainer.withOpacity(0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildNotificationIcon(theme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: notification.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                  ),
                                ),
                                _buildPriorityIndicator(theme),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeago.format(
                                notification.timestamp,
                                locale: 'he',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(notification.content, style: theme.textTheme.bodyMedium),
                  if (notification.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        notification.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          color: theme.colorScheme.surfaceVariant,
                          child: Icon(
                            Icons.broken_image,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (notification.actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: notification.actions.map((action) {
                        return _buildActionButton(action, theme);
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(ThemeData theme) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.lessonReminder24h:
      case NotificationType.lessonReminder1h:
        iconData = Icons.schedule;
        iconColor = theme.colorScheme.primary;
        break;
      case NotificationType.attendanceRequest:
      case NotificationType.attendanceMissing:
        iconData = Icons.how_to_reg;
        iconColor = theme.colorScheme.secondary;
        break;
      case NotificationType.seriesUpdate:
      case NotificationType.seriesComplete:
        iconData = Icons.auto_stories;
        iconColor = theme.colorScheme.tertiary;
        break;
      case NotificationType.emergency:
        iconData = Icons.warning;
        iconColor = theme.colorScheme.error;
        break;
      case NotificationType.adminNewRegistration:
      case NotificationType.adminAttendanceReport:
        iconData = Icons.admin_panel_settings;
        iconColor = theme.colorScheme.outline;
        break;
      case NotificationType.mentorAssignment:
        iconData = Icons.assignment_ind;
        iconColor = theme.colorScheme.primary;
        break;
      case NotificationType.artistConfirmation:
      case NotificationType.artistAchievement:
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case NotificationType.realTimeUpdate:
        iconData = Icons.update;
        iconColor = theme.colorScheme.secondary;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = theme.colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildPriorityIndicator(ThemeData theme) {
    if (notification.priority == NotificationPriority.normal) {
      return const SizedBox.shrink();
    }

    Color color;
    IconData icon;

    switch (notification.priority) {
      case NotificationPriority.high:
        color = Colors.orange;
        icon = Icons.priority_high;
        break;
      case NotificationPriority.urgent:
        color = theme.colorScheme.error;
        icon = Icons.warning;
        break;
      case NotificationPriority.low:
        color = theme.colorScheme.outline;
        icon = Icons.low_priority;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Icon(icon, color: color, size: 16);
  }

  Widget _buildActionButton(NotificationAction action, ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: () => onActionTap?.call(action.id),
      icon: _getActionIcon(action.action),
      label: Text(action.title),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: theme.textTheme.bodySmall,
      ),
    );
  }

  Icon _getActionIcon(String action) {
    switch (action) {
      case 'mark_present':
        return const Icon(Icons.check, size: 16);
      case 'mark_absent':
        return const Icon(Icons.close, size: 16);
      case 'view_lesson':
        return const Icon(Icons.visibility, size: 16);
      case 'contact_artist':
        return const Icon(Icons.message, size: 16);
      case 'mark_attendance':
        return const Icon(Icons.how_to_reg, size: 16);
      default:
        return const Icon(Icons.touch_app, size: 16);
    }
  }
}
