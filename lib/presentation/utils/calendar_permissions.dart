import 'package:knafayim_app/data/models/calendar_event.dart';

import '../../data/models/user.dart';

class CalendarPermissions {
  final User user;

  CalendarPermissions(this.user);

  // Check if user can create events
  bool get canCreateEvents => user.isStaff;

  // Check if user can edit events
  bool get canEditEvents => user.isStaff;

  // Check if user can delete events
  bool get canDeleteEvents => user.isStaff;

  // Check if user can view all events
  bool get canViewAllEvents => true; // Everyone can view

  // Check if user can view event details
  bool get canViewEventDetails => true; // Everyone can view details

  // Get appropriate app bar title based on role
  String get appBarTitle {
    switch (user.role) {
      case UserRole.staff:
        return 'ניהול יומן ארגוני';
      case UserRole.mentor:
        return 'יומן שיעורים';
      case UserRole.client:
        return 'יומן אירועים';
    }
  }

  // Get appropriate empty state message
  String get emptyStateMessage {
    switch (user.role) {
      case UserRole.staff:
        return 'אין אירועים. לחץ + ליצירת אירוע חדש';
      case UserRole.mentor:
        return 'אין שיעורים או אירועים מתוכננים';
      case UserRole.client:
        return 'אין אירועים מתוכננים';
    }
  }

  // Get role-specific event types to show
  List<EventType> get visibleEventTypes {
    switch (user.role) {
      case UserRole.staff:
        return EventType.values; // Staff see everything
      case UserRole.mentor:
        return [
          EventType.workshop,
          EventType.meeting,
          EventType.holiday,
          EventType.announcement,
        ];
      case UserRole.client:
        return [
          EventType.workshop,
          EventType.holiday,
          EventType.announcement,
          EventType.special_event,
        ];
    }
  }
}
