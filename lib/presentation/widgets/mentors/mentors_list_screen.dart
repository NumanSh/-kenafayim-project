import 'package:flutter/material.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../../../config/themes.dart';
import '../../screens/auth/register_screen.dart';

class MentorsListScreen extends StatefulWidget {
  const MentorsListScreen({Key? key}) : super(key: key);

  @override
  State<MentorsListScreen> createState() => _MentorsListScreenState();
}

class _MentorsListScreenState extends State<MentorsListScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  List<User> _mentors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMentors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMentors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mentors = await _userRepository.getUsersByRole(UserRole.mentor);

      setState(() {
        _mentors = mentors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בטעינת מנחים: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  List<User> get _filteredMentors {
    if (_searchQuery.isEmpty) {
      return _mentors;
    }

    return _mentors.where((mentor) {
      return mentor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          mentor.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mentors.isEmpty
                    ? _buildEmptyState()
                    : _buildMentorsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to RegisterScreen to add new mentor, exactly like the artist tab
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RegisterScreen(initialRole: UserRole.mentor),
            ),
          ).then((_) {
            // Refresh the list after returning from registration
            _loadMentors();
          });
        },
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'חיפוש מנחים...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'אין מנחים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'לחץ על הכפתור למטה כדי להוסיף מנחה חדש',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorsList() {
    final mentors = _filteredMentors;

    if (mentors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'לא נמצאו תוצאות',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: mentors.length,
      itemBuilder: (context, index) {
        final mentor = mentors[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: mentor.profileImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        mentor.profileImageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
            ),
            title: Text(mentor.name),
            subtitle: Text(mentor.email),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('ערוך'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('מחק'),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  // Navigate to edit mentor
                } else if (value == 'delete') {
                  // Show delete confirmation
                  _showDeleteConfirmation(mentor);
                }
              },
            ),
            onTap: () {
              // Navigate to mentor details
            },
          ),
        );
      },
    );
  }
  
  void _showDeleteConfirmation(User mentor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת מנחה'),
        content: Text('האם אתה בטוח שברצונך למחוק את ${mentor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _userRepository.deleteUser(mentor.id);
                _loadMentors(); // Refresh the list
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('המנחה נמחק בהצלחה'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('שגיאה במחיקת המנחה: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('מחק', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
