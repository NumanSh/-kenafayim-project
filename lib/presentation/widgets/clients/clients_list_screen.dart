import 'package:flutter/material.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../../../config/themes.dart';
import '../../screens/auth/register_screen.dart';

class ClientsListScreen extends StatefulWidget {
  final String? mentorId;
  final bool isAdmin;

  const ClientsListScreen({
    Key? key,
    this.mentorId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  List<User> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<User> clients;

      if (widget.mentorId != null) {
        // In a real app, you would get clients assigned to this mentor
        // For now, we'll just get all clients
        clients = await _userRepository.getUsersByRole(UserRole.client);
      } else {
        clients = await _userRepository.getUsersByRole(UserRole.client);
      }

      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בטעינת אמנים: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  List<User> get _filteredClients {
    if (_searchQuery.isEmpty) {
      return _clients;
    }

    return _clients.where((client) {
      return client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client.email.toLowerCase().contains(_searchQuery.toLowerCase());
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
                : _clients.isEmpty
                    ? _buildEmptyState()
                    : _buildClientsList(),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to registration screen to add new artist
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                ).then((_) {
                  // Refresh the list after returning from registration
                  _loadClients();
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'חיפוש אמנים...',
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
            Icons.people,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'אין אמנים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isAdmin
                ? 'לחץ על הכפתור למטה כדי להוסיף אמן חדש'
                : 'אין אמנים מוקצים כרגע',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    final clients = _filteredClients;

    if (clients.isEmpty) {
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
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: client.profileImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        client.profileImageUrl!,
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
            title: Text(client.name),
            subtitle: Text(client.email),
            trailing: widget.isAdmin
                ? PopupMenuButton(
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
                        // Navigate to edit client
                      } else if (value == 'delete') {
                        // Show delete confirmation
                      }
                    },
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to client details
            },
          ),
        );
      },
    );
  }
}
