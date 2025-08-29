import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "package:knafayim_app/presentation/screens/booking/staff_room_management_screen.dart";
import "package:knafayim_app/presentation/screens/lessons/staff_attendance_overview_screen.dart";
import "package:knafayim_app/presentation/screens/messages_screen.dart";
import "package:knafayim_app/presentation/screens/profile_screen.dart";
import "package:knafayim_app/presentation/screens/reports_screen.dart";
import "package:knafayim_app/presentation/utils/test_data_screen.dart";
import "package:knafayim_app/presentation/widgets/hours/hours_dashboard_screen.dart";
import "package:knafayim_app/presentation/widgets/hours/staff_hours_approval_screen.dart";

import "../../../config/service_locator.dart";
import "../../../config/themes.dart";
import "../../../data/models/user.dart";
import "../../../services/custom_auth_service.dart";
import "../../navigation/navigation_items.dart";
import "../../screens/auth/login_screen.dart";
import "wave_clipper.dart";
import '../../screens/booking/room_selection_screen.dart';

class AppDrawer extends StatelessWidget {
  final User user;

  const AppDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final List<NavigationItem> drawerItems = getNavigationItemsForRole(
      user.role,
    );

    return Drawer(
      child: Container(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Optimized for Redmi Note 13 Pro and all devices
            final availableHeight = constraints.maxHeight;
            final isVerySmallScreen = availableHeight < 500;
            final isSmallScreen = availableHeight < 600;

            // More aggressive height calculation
            final headerHeight = isVerySmallScreen
                ? availableHeight *
                      0.28 // 28% for very small screens
                : isSmallScreen
                ? availableHeight *
                      0.32 // 32% for small screens
                : availableHeight * 0.35; // 35% for normal screens

            return Column(
              children: [
                // User Profile Section with Wave Clip - ULTRA RESPONSIVE
                ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    height: headerHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                          AppTheme.accentColor,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(
                          isVerySmallScreen
                              ? 12
                              : isSmallScreen
                              ? 16
                              : 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: isVerySmallScreen
                                  ? 5
                                  : isSmallScreen
                                  ? 8
                                  : 15,
                            ),

                            // Profile Picture - Ultra responsive
                            Container(
                              width: isVerySmallScreen
                                  ? 45
                                  : isSmallScreen
                                  ? 55
                                  : 70,
                              height: isVerySmallScreen
                                  ? 45
                                  : isSmallScreen
                                  ? 55
                                  : 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: isVerySmallScreen
                                    ? 22
                                    : isSmallScreen
                                    ? 27
                                    : 35,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage:
                                    user.profileImageUrl != null &&
                                        user.profileImageUrl!.isNotEmpty
                                    ? NetworkImage(user.profileImageUrl!)
                                    : null,
                                child:
                                    (user.profileImageUrl == null ||
                                        user.profileImageUrl!.isEmpty)
                                    ? Text(
                                        user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : "U",
                                        style: TextStyle(
                                          fontSize: isVerySmallScreen
                                              ? 18
                                              : isSmallScreen
                                              ? 22
                                              : 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),

                            SizedBox(
                              height: isVerySmallScreen
                                  ? 4
                                  : isSmallScreen
                                  ? 6
                                  : 10,
                            ),

                            // User Name - Ultra compact
                            Flexible(
                              child: Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: isVerySmallScreen
                                      ? 14
                                      : isSmallScreen
                                      ? 16
                                      : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            SizedBox(
                              height: isVerySmallScreen
                                  ? 2
                                  : isSmallScreen
                                  ? 3
                                  : 6,
                            ),

                            // User Role Badge - Ultra compact
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmallScreen
                                    ? 6
                                    : isSmallScreen
                                    ? 8
                                    : 12,
                                vertical: isVerySmallScreen
                                    ? 2
                                    : isSmallScreen
                                    ? 3
                                    : 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _getRoleText(user.role),
                                style: TextStyle(
                                  fontSize: isVerySmallScreen
                                      ? 9
                                      : isSmallScreen
                                      ? 10
                                      : 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(
                              height: isVerySmallScreen
                                  ? 2
                                  : isSmallScreen
                                  ? 4
                                  : 6,
                            ),

                            // User Email - Ultra compact
                            Flexible(
                              child: Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: isVerySmallScreen
                                      ? 9
                                      : isSmallScreen
                                      ? 10
                                      : 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Menu Items Section - Guaranteed scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isVerySmallScreen
                            ? 8
                            : isSmallScreen
                            ? 12
                            : 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Navigation Items
                          ...drawerItems.map(
                            (item) =>
                                _buildMenuItem(context, item, isSmallScreen),
                          ),

                          if (user.isStaff) ...[
                            _buildStaffHoursApprovalMenuItem(
                              context,
                              isSmallScreen,
                            ),
                            const SizedBox(height: 8),
                            _buildStaffRoomManagementMenuItem(
                              context,
                              isSmallScreen,
                            ),
                            const SizedBox(height: 8),
                            _buildStaffAttendanceMenuItem(
                              context,
                              isSmallScreen,
                            ), // ADD THIS LINE
                            const SizedBox(height: 8),
                            _buildStaffReportsMenuItem(
                              context,
                              isSmallScreen,
                              user,
                            ), // ADD REPORTS MENU ITEM
                            const SizedBox(height: 8),
                          ],

                          // Working Hours Menu Item (for mentors only)
                          if (user.isMentor) ...[
                            _buildWorkingHoursMenuItem(context, isSmallScreen),
                          ],
                          if (user.isMentor) ...[
                            _buildRoomBookingMenuItem(context, isSmallScreen),
                            const SizedBox(height: 8),
                          ],
                          // Divider
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: isVerySmallScreen ? 6 : 8,
                            ),
                            height: 1,
                            color: AppTheme.slate200,
                          ),

                          // Settings
                          _buildMenuItem(
                            context,
                            NavigationItem(
                              title: "הגדרות",
                              icon: Icons.settings_outlined,
                              screenBuilder: (context, user) => Container(),
                              roles: [],
                            ),
                            isSmallScreen,
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("הגדרות יהיו זמינות בקרוב"),
                                ),
                              );
                            },
                          ),
                          if (kDebugMode) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(
                                Icons.bug_report,
                                color: Colors.orange,
                              ),
                              title: const Text('נתוני בדיקה'),
                              subtitle: const Text('כלי פיתוח'),
                              onTap: () {
                                Navigator.pop(context); // Close drawer
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TestDataScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                          // Logout Button
                          Container(
                            margin: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                            child: _buildLogoutButton(context, isSmallScreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoomBookingMenuItem(BuildContext context, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isSmallScreen ? 1 : 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomSelectionScreen(user: user),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isSmallScreen ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3b82f6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.meeting_room,
                    color: const Color(0xFF3b82f6),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 14),
                Expanded(
                  child: Text(
                    'הזמנת סטודיואים',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1f2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9ca3af),
                  size: isSmallScreen ? 16 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffRoomManagementMenuItem(
    BuildContext context,
    bool isSmallScreen,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isSmallScreen ? 1 : 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StaffRoomManagementScreen(user: user),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isSmallScreen ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.settings,
                    color: const Color(0xFF6366f1),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 14),
                Expanded(
                  child: Text(
                    'ניהול סטודיואים',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1f2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9ca3af),
                  size: isSmallScreen ? 16 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    NavigationItem item,
    bool isSmallScreen, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isSmallScreen ? 1 : 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              onTap ??
              () {
                Navigator.pop(context);
                final currentRouteName = ModalRoute.of(context)?.settings.name;
                if (item.routeName != null &&
                    item.routeName == currentRouteName) {
                  return;
                }

                // DEBUG: Print navigation info
                print("DEBUG DRAWER: Navigating to ${item.title}");
                print("DEBUG DRAWER: User: ${user.name}");

                // Check if this is the profile screen
                if (item.title == "פרופיל" || item.routeName == "/profile") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        print(
                          "DEBUG DRAWER: Creating ProfileScreen with user: ${user.name}",
                        );
                        return ProfileScreen(user: user);
                      },
                      settings: RouteSettings(
                        name: item.routeName,
                        arguments: user,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => item.screenBuilder(context, user),
                      settings: RouteSettings(
                        name: item.routeName,
                        arguments: user,
                      ),
                    ),
                  );
                }
              },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isSmallScreen ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: AppTheme.primaryColor,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.slate400,
                  size: isSmallScreen ? 16 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleLogout(context),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_outlined,
                  color: Colors.red[600],
                  size: isSmallScreen ? 18 : 20,
                ),
                SizedBox(width: isSmallScreen ? 6 : 10),
                Text(
                  "התנתקות",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("התנתקות"),
        content: const Text("האם אתה בטוח שברצונך להתנתק?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("ביטול"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("התנתקות"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final authService = serviceLocator<CustomAuthService>();
        await authService.signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("שגיאה בהתנתקות: ${e.toString()}")),
          );
        }
      }
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.client:
        return "אמן";
      case UserRole.mentor:
        return "מנחה";
      case UserRole.staff:
        return "צוות";
    }
  }

  Widget _buildWorkingHoursMenuItem(BuildContext context, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isSmallScreen ? 1 : 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HoursDashboardScreen(user: user),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isSmallScreen ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8b5cf6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: const Color(0xFF8b5cf6),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 14),
                Expanded(
                  child: Text(
                    'שעות עבודה',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1f2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9ca3af),
                  size: isSmallScreen ? 16 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffHoursApprovalMenuItem(
    BuildContext context,
    bool isSmallScreen,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isSmallScreen ? 1 : 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StaffHoursApprovalScreen(user: user),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isSmallScreen ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.approval,
                    color: const Color(0xFF10b981),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 14),
                Expanded(
                  child: Text(
                    'אישור שעות עבודה',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1f2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9ca3af),
                  size: isSmallScreen ? 16 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffAttendanceMenuItem(
    BuildContext context,
    bool isSmallScreen,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isSmallScreen ? 1 : 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StaffAttendanceOverviewScreen(),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isSmallScreen ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8b5cf6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.how_to_reg,
                    color: const Color(0xFF8b5cf6),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 14),
                Expanded(
                  child: Text(
                    'צפייה בנוכחות',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1f2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9ca3af),
                  size: isSmallScreen ? 16 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

  Widget _buildStaffReportsMenuItem(
    BuildContext context,
    bool isSmallScreen,
    User user,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isSmallScreen ? 1 : 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportsScreen(user: user),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isSmallScreen ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3b82f6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bar_chart_outlined,
                    color: const Color(0xFF3b82f6),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 14),
                Expanded(
                  child: Text(
                    'דוחות',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1f2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9ca3af),
                  size: isSmallScreen ? 16 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

