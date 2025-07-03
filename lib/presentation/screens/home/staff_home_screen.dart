import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:knafayim_app/presentation/screens/lessons/staff_attendance_overview_screen.dart";
import "package:knafayim_app/presentation/screens/users/user_management_screen.dart";
import "package:knafayim_app/presentation/widgets/calendar/enhanced_calendar_view.dart";
import "package:knafayim_app/presentation/widgets/calendar/riverpod_calendar_wrapper.dart";
import "package:knafayim_app/presentation/widgets/home/mentor_dashboard.dart";
import "../../../data/models/user.dart";
import "../../widgets/common/app_drawer.dart";
import "../../widgets/common/app_logo.dart";
import "../../widgets/home/modern_staff_dashboard.dart";
import "../../navigation/navigation_items.dart";
import "../../widgets/messages/messages_screen.dart";
import "../../widgets/profile/profile_screen.dart";
import "../../widgets/clients/clients_list_screen.dart";
import "../../widgets/mentors/mentors_list_screen.dart";
import "../../widgets/reports/reports_screen.dart";
import "../../widgets/common/navigation_badge.dart";
import "../messages_screen.dart" show unreadMessagesCountProvider;

class StaffHomeScreen extends ConsumerStatefulWidget {
  final User user;

  const StaffHomeScreen({super.key, required this.user});

  @override
  ConsumerState<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends ConsumerState<StaffHomeScreen> {
  int _selectedIndex = 0;
  List<NavigationItem>? _navigationItems; // ✅ MADE NULLABLE
  List<Widget>? _pages; // ✅ MADE NULLABLE

  @override
  void initState() {
    super.initState();
    // ✅ DON'T ACCESS PROVIDERS HERE
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ INITIALIZE ONLY ONCE
    if (_navigationItems == null) {
      _initializeNavigation();
    }
  }

  void _initializeNavigation() {
    _navigationItems = _buildNavigationItems();
    _pages = _buildPages();
  }

  List<NavigationItem> _buildNavigationItems() {
    return [
      NavigationItem(
        title: "לוח בקרה",
        icon: Icons.dashboard_outlined,
        screenBuilder: (context, user) =>
            ModernStaffDashboard(user: widget.user),
        roles: [UserRole.staff],
        routeName: "/dashboard",
      ),
      ...getNavigationItemsForRole(
        UserRole.staff,
      ).where((item) => item.routeName != "/home"),
    ];
  }

  List<Widget> _buildPages() {
    return _navigationItems!.map((item) => _buildScreenForRoute(item)).toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SHOW LOADING WHILE INITIALIZING
    if (_navigationItems == null || _pages == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      drawer: AppDrawer(user: widget.user),
      body: IndexedStack(index: _selectedIndex, children: _pages!),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _navigationItems![_selectedIndex].title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const AppLogo(width: 60, height: 40, margin: EdgeInsets.zero),
        ],
      ),
      centerTitle: false,
      automaticallyImplyLeading: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF374151)),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFFe5e7eb), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: _navigationItems!.map((item) {
          return BottomNavigationBarItem(
            icon: item.iconBuilder != null
                ? item.iconBuilder!(context, widget.user)
                : Icon(item.icon),
            label: item.title,
          );
        }).toList(),
        selectedItemColor: const Color(0xFF3b82f6),
        unselectedItemColor: const Color(0xFF6b7280),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildScreenForRoute(NavigationItem item) {
    switch (item.routeName) {
      case "/dashboard":
        return ModernStaffDashboard(user: widget.user);
      case "/calendar":
        return RiverpodCalendarWrapper(user: widget.user);
      case "/messages":
        return item.screenBuilder(context, widget.user);
      case "/profile":
        return ProfileScreen(user: widget.user);
      // In your _buildScreenForRoute method, add this case:
      // case "/attendance_overview":
      //   return const StaffAttendanceOverviewScreen();

      case "/user_management":
        return UserManagementScreen(currentUser: widget.user);
      case "/reports":
        return ReportsScreen(user: widget.user);
      default:
        return item.screenBuilder(context, widget.user);
    }
  }
}
