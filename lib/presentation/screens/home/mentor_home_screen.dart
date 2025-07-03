import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:knafayim_app/presentation/widgets/calendar/riverpod_calendar_wrapper.dart";
import "../../../data/models/user.dart";
import "../../widgets/common/app_drawer.dart";
import "../../widgets/common/app_logo.dart";
import "../../widgets/home/mentor_dashboard.dart";
import "../../navigation/navigation_items.dart";
import "../../widgets/profile/profile_screen.dart";
import "../../widgets/clients/clients_list_screen.dart";

class MentorHomeScreen extends ConsumerStatefulWidget {
  final User user;

  const MentorHomeScreen({super.key, required this.user});

  @override
  ConsumerState<MentorHomeScreen> createState() => _MentorHomeScreenState();
}

class _MentorHomeScreenState extends ConsumerState<MentorHomeScreen> {
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
    List<NavigationItem> roleSpecificNavItems = getNavigationItemsForRole(
      UserRole.mentor,
    );

    _navigationItems = [];
    _pages = [];

    // Add dashboard as first item
    _navigationItems!.add(
      NavigationItem(
        title: "ראשי",
        icon: Icons.dashboard_outlined,
        screenBuilder: (context, user) => MentorDashboard(user: widget.user),
        roles: [UserRole.mentor],
        routeName: "/home_mentor_dashboard",
      ),
    );
    _pages!.add(MentorDashboard(user: widget.user));

    // Add other navigation items
    for (var item in roleSpecificNavItems) {
      if (item.routeName == "/home") continue;

      Widget screen = _buildScreenForRoute(item);
      _pages!.add(screen);
      _navigationItems!.add(item);
    }
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
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
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
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
      ),
      drawer: AppDrawer(user: widget.user),
      body: IndexedStack(index: _selectedIndex, children: _pages!),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: Border(
            top: BorderSide(color: const Color(0xFFe5e7eb), width: 1),
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
      ),
    );
  }

  Widget _buildScreenForRoute(NavigationItem item) {
    switch (item.routeName) {
      case "/dashboard":
        return MentorDashboard(user: widget.user);
      case "/calendar":
        return RiverpodCalendarWrapper(user: widget.user);
      case "/messages":
        return item.screenBuilder(context, widget.user);
      case "/profile":
        return ProfileScreen(user: widget.user);
      case "/clients":
        return ClientsListScreen(mentorId: widget.user.id, isAdmin: false);
      default:
        return item.screenBuilder(context, widget.user);
    }
  }
}
