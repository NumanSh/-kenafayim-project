import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:knafayim_app/presentation/widgets/calendar/enhanced_calendar_view.dart";
import "package:knafayim_app/presentation/widgets/calendar/riverpod_calendar_wrapper.dart";
// ✅ ADD NOTIFICATION IMPORTS
import "package:knafayim_app/presentation/screens/notifications/notification_center_screen.dart";
import "package:knafayim_app/presentation/widgets/notifications/notification_badge.dart";
import "../../data/models/user.dart";
import "../screens/home/client_home_screen.dart";
import "../screens/home/mentor_home_screen.dart";
import "../screens/home/staff_home_screen.dart";
import "../screens/messages_screen.dart";
import "../screens/profile_screen.dart";
import "../screens/reports_screen.dart";
import "../screens/users/user_management_screen.dart";
import "../widgets/common/navigation_badge.dart";

// Import the unread messages provider
import "../screens/messages_screen.dart" show unreadMessagesCountProvider;

class NavigationItem {
  final String title;
  final IconData icon;
  final Widget Function(BuildContext, User) screenBuilder;
  final List<UserRole> roles;
  final String? routeName;
  final Widget Function(BuildContext, User)? iconBuilder;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.screenBuilder,
    required this.roles,
    this.routeName,
    this.iconBuilder,
  });
}

final List<NavigationItem> appNavigationItems = [
  NavigationItem(
    title: "ראשי",
    icon: Icons.dashboard_outlined,
    screenBuilder: (context, user) {
      switch (user.role) {
        case UserRole.client:
          return ClientHomeScreen(user: user);
        case UserRole.mentor:
          return MentorHomeScreen(user: user);
        case UserRole.staff:
          return StaffHomeScreen(user: user);
      }
    },
    roles: [UserRole.client, UserRole.mentor, UserRole.staff],
    routeName: "/home",
  ),

  NavigationItem(
    title: "יומן",
    icon: Icons.calendar_today_outlined,
    screenBuilder: (context, user) => RiverpodCalendarWrapper(user: user),
    roles: [UserRole.client, UserRole.mentor, UserRole.staff],
    routeName: "/calendar",
  ),

  // ✅ FIXED MESSAGES NAVIGATION
  NavigationItem(
    title: "הודעות",
    icon: Icons.message_outlined,
    screenBuilder: (context, user) => MessagesScreen(user: user),
    roles: [UserRole.client, UserRole.mentor, UserRole.staff],
    routeName: "/messages",
    iconBuilder: (context, user) {
      return Consumer(
        builder: (context, ref, child) {
          final unreadCount = ref.watch(unreadMessagesCountProvider(user.id));
          return NavigationBadge(
            count: unreadCount,
            child: const Icon(Icons.message_outlined),
          );
        },
      );
    },
  ),

  // ✅ ADD NOTIFICATIONS NAVIGATION
  NavigationItem(
    title: "ניהול משתמשים",
    icon: Icons.manage_accounts,
    screenBuilder: (context, user) => UserManagementScreen(currentUser: user),
    roles: [UserRole.staff],
    routeName: "/user_management",
  ),

  NavigationItem(
    title: "דוחות",
    icon: Icons.bar_chart_outlined,
    screenBuilder: (context, user) => ReportsScreen(user: user),
    roles: [UserRole.staff],
    routeName: "/reports",
  ),

  NavigationItem(
    title: "פרופיל",
    icon: Icons.account_circle_outlined,
    screenBuilder: (context, user) => ProfileScreen(user: user),
    roles: [UserRole.client, UserRole.mentor, UserRole.staff],
    routeName: "/profile",
  ),
];

List<NavigationItem> getNavigationItemsForRole(UserRole role) {
  return appNavigationItems.where((item) => item.roles.contains(role)).toList();
}
