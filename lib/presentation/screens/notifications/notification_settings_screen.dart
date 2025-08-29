import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/common/rtl_wrapper.dart';
import '../../../data/models/notification_preference.dart';
import '../../../services/auth_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  NotificationPreference? _preferences;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      final prefsAsync = ref.read(
        notificationPreferencesProvider(currentUser.id),
      );
      prefsAsync.when(
        data: (prefs) {
          if (mounted) {
            setState(() {
              _preferences = prefs;
            });
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('יש להתחבר כדי לגשת להגדרות')),
      );
    }

    final preferencesAsync = ref.watch(
      notificationPreferencesProvider(currentUser.id),
    );

    return RTLTextDirectionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הגדרות הודעות'),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _savePreferences,
                child: const Text('שמור'),
              ),
          ],
        ),
        body: preferencesAsync.when(
          data: (preferences) {
            _preferences ??= preferences;
            return _buildSettingsContent(theme);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'שגיאה בטעינת ההגדרות',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(
                    notificationPreferencesProvider(currentUser.id),
                  ),
                  child: const Text('נסה שוב'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(ThemeData theme) {
    if (_preferences == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('הודעות שיעורים', Icons.school),
          _buildLessonSettings(),
          const SizedBox(height: 24),

          _buildSectionHeader('הודעות נוכחות', Icons.how_to_reg),
          _buildAttendanceSettings(),
          const SizedBox(height: 24),

          _buildSectionHeader('הודעות ניהול', Icons.admin_panel_settings),
          _buildAdminSettings(),
          const SizedBox(height: 24),

          _buildSectionHeader('הודעות כלליות', Icons.notifications),
          _buildGeneralSettings(),
          const SizedBox(height: 24),

          _buildSectionHeader('הגדרות מתקדמות', Icons.tune),
          _buildAdvancedSettings(),
          const SizedBox(height: 24),

          _buildTestSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('תזכורות שיעורים'),
              subtitle: const Text('קבל תזכורות לפני שיעורים'),
              value: _preferences!.lessonReminders,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(lessonReminders: value);
                });
              },
            ),
            if (_preferences!.lessonReminders) ...[
              const Divider(),
              ListTile(
                title: const Text('תזכורת מוקדמת'),
                subtitle: Text('${_preferences!.reminderHours24} שעות לפני'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _preferences!.reminderHours24 > 1
                          ? () => _updateReminderHours24(
                              _preferences!.reminderHours24 - 1,
                            )
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('${_preferences!.reminderHours24}'),
                    IconButton(
                      onPressed: _preferences!.reminderHours24 < 48
                          ? () => _updateReminderHours24(
                              _preferences!.reminderHours24 + 1,
                            )
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('תזכורת קרובה'),
                subtitle: Text('${_preferences!.reminderHours1} שעה לפני'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _preferences!.reminderHours1 > 1
                          ? () => _updateReminderHours1(
                              _preferences!.reminderHours1 - 1,
                            )
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('${_preferences!.reminderHours1}'),
                    IconButton(
                      onPressed: _preferences!.reminderHours1 < 12
                          ? () => _updateReminderHours1(
                              _preferences!.reminderHours1 + 1,
                            )
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(),
            SwitchListTile(
              title: const Text('עדכוני סדרות'),
              subtitle: const Text('הודעות על שינויים בסדרות שיעורים'),
              value: _preferences!.seriesUpdates,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(seriesUpdates: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('בקשות נוכחות'),
              subtitle: const Text('הודעות לאישור נוכחות בשיעורים'),
              value: _preferences!.attendanceNotifications,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    attendanceNotifications: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('הודעות ניהול'),
              subtitle: const Text('הודעות על רישומים חדשים ודוחות'),
              value: _preferences!.adminNotifications,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    adminNotifications: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('עדכונים בזמן אמת'),
              subtitle: const Text('הודעות מיידיות על שינויים'),
              value: _preferences!.realTimeUpdates,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(realTimeUpdates: value);
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('הודעות דחופות'),
              subtitle: const Text('הודעות חשובות וביטחון (לא ניתן לכיבוי)'),
              value: _preferences!.emergencyNotifications,
              onChanged: null, // Always enabled
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('צלילים'),
              subtitle: const Text('השמע צלילים עם הודעות'),
              value: _preferences!.soundEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(soundEnabled: value);
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('רטט'),
              subtitle: const Text('הפעל רטט עם הודעות'),
              value: _preferences!.vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    vibrationEnabled: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'בדיקת הודעות',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('שלח הודעת בדיקה כדי לוודא שההגדרות עובדות'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.send),
                label: const Text('שלח הודעת בדיקה'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateReminderHours24(int hours) {
    setState(() {
      _preferences = _preferences!.copyWith(reminderHours24: hours);
    });
  }

  void _updateReminderHours1(int hours) {
    setState(() {
      _preferences = _preferences!.copyWith(reminderHours1: hours);
    });
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(notificationActionsProvider.notifier)
          .savePreferences(_preferences!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ההגדרות נשמרו בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת ההגדרות: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendTestNotification() async {
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.sendRealTimeUpdate(
        userIds: [currentUser.id],
        title: 'הודעת בדיקה 🔔',
        content:
            'זוהי הודעת בדיקה מהמערכת. אם אתה רואה הודעה זו, ההגדרות שלך עובדות כראוי!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הודעת הבדיקה נשלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשליחת הודעת הבדיקה: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
