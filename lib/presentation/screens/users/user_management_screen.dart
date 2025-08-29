import 'package:flutter/material.dart';
import 'package:knafayim_app/presentation/screens/lessons/add_artist_screen.dart';
import 'package:knafayim_app/presentation/screens/profile/edit_profile_screen.dart';
import 'package:knafayim_app/presentation/screens/users/change_role_screen.dart';
import 'package:knafayim_app/presentation/screens/users/user_profile_screen.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../../../config/themes.dart';
import 'package:flutter/foundation.dart';

class UserManagementScreen extends StatefulWidget {
  final User currentUser; // ✅ ADD: Current user parameter

  const UserManagementScreen({super.key, required this.currentUser});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  List<User> _users = [];
  bool _isLoading = true;
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userRepository.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת משתמשים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<User> _getFilteredUsers(UserRole role) {
    return _users
        .where((user) => user.role == role)
        .where(
          (user) =>
              _searchQuery.isEmpty ||
              user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת משתמש'),
        content: Text('האם אתה בטוח שברצונך למחוק את ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      if (kDebugMode) {
        print('Deleting user: ${user.id}, ${user.name}');
      }

      final success = await _userRepository.deleteUser(user.id);

      if (success) {
        await _loadUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('המשתמש נמחק בהצלחה'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('מחיקת המשתמש נכשלה');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה במחיקת המשתמש: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _editUserProfile(User user) async {
    if (kDebugMode) {
      print('Editing user profile: ${user.id}, ${user.name}');
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _changeUserRole(User user) async {
    if (kDebugMode) {
      print(
        'Changing user role: ${user.id}, ${user.name}, current role: ${user.role}',
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangeRoleScreen(user: user)),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _addNewArtist() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddArtistScreen()),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewArtist,
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab bar section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFf1f5f9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'אמנים'),
                    Tab(text: 'מנחים'),
                    Tab(text: 'צוות'),
                  ],
                  indicator: BoxDecoration(
                    color: const Color(0xFF3b82f6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748b),
                  dividerColor: Colors.transparent,
                ),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'חיפוש משתמשים',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF64748b)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUserList(_getFilteredUsers(UserRole.client)),
                        _buildUserList(_getFilteredUsers(UserRole.mentor)),
                        _buildUserList(_getFilteredUsers(UserRole.staff)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<User> users) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'אין משתמשים להצגה',
          style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Container(
            margin: const EdgeInsets.only(
              bottom: 12,
            ), // ✅ REDUCED: from 16 to 12
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                // ✅ ADD: Navigate to profile on tap
                onTap: () => _navigateToUserProfile(user),
                child: Padding(
                  padding: const EdgeInsets.all(12), // ✅ REDUCED: from 16 to 12
                  child: Row(
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 24, // ✅ REDUCED: from 28 to 24
                        backgroundColor: const Color(
                          0xFF3b82f6,
                        ).withOpacity(0.1),
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
                                    : '?',
                                style: const TextStyle(
                                  color: Color(0xFF3b82f6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16, // ✅ REDUCED: from 18 to 16
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12), // ✅ REDUCED: from 16 to 12
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 15, // ✅ REDUCED: from 16 to 15
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                            const SizedBox(height: 2), // ✅ REDUCED: from 4 to 2
                            // ID (User ID)
                            Text(
                              'מזהה: ${user.idNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6b7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            // Phone number
                            if (user.phoneNumber.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 12,
                                    color: Color(0xFF6b7280),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.phoneNumber,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6b7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Role badge
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                  user.role,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getRoleDisplayName(user.role),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getRoleColor(user.role),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action menu
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF6b7280),
                          size: 20,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editUserProfile(user);
                              break;
                            case 'role':
                              _changeUserRole(user);
                              break;
                            case 'delete':
                              _deleteUser(user);
                              break;
                            case 'profile':
                              _navigateToUserProfile(user);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Color(0xFF3b82f6),
                                ),
                                SizedBox(width: 8),
                                Text('פרופיל'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Color(0xFF10b981),
                                ),
                                SizedBox(width: 8),
                                Text('עריכה'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'role',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.swap_horiz,
                                  size: 16,
                                  color: Color(0xFFf59e0b),
                                ),
                                SizedBox(width: 8),
                                Text('שינוי תפקיד'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 16,
                                  color: Color(0xFFef4444),
                                ),
                                SizedBox(width: 8),
                                Text('מחיקה'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ ADD: Navigate to user profile
  void _navigateToUserProfile(User user) {
    print('🔍 DEBUG: Navigating to profile for user: ${user.id}');
    print('🔍 DEBUG: User name: ${user.name}');
    print('🔍 DEBUG: User email: ${user.email}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserProfileScreen(user: user, currentUser: widget.currentUser),
      ),
    ).then((value) {
      // ✅ This runs when returning from profile screen
      print('🔄 Returned from profile screen, refreshing user list...');

      // Refresh the screen state
      setState(() {
        _isLoading = true;
      });

      // Reload users from database
      _loadUsers()
          .then((_) {
            print('✅ User list refreshed successfully');
          })
          .catchError((error) {
            print('❌ Error refreshing user list: $error');
          });
    });
  }

  // ✅ ADD: Get role color
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.client:
        return const Color(0xFF10b981); // Green for artists
      case UserRole.mentor:
        return const Color(0xFF3b82f6); // Blue for mentors
      case UserRole.staff:
        return const Color(0xFFf59e0b); // Orange for staff
    }
  }

  // ✅ ADD: Get role display name
  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.client:
        return 'אמן';
      case UserRole.mentor:
        return 'מנחה';
      case UserRole.staff:
        return 'צוות';
    }
  }
}
