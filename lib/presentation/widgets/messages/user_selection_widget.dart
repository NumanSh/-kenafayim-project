import 'package:flutter/material.dart';
import '../../../data/models/user.dart';

class UserSelectionModal extends StatefulWidget {
  final List<User> allUsers;
  final List<User> selectedUsers;
  final Function(List<User>) onSelectionChanged;
  final ScrollController scrollController;

  const UserSelectionModal({
    Key? key,
    required this.allUsers,
    required this.selectedUsers,
    required this.onSelectionChanged,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<UserSelectionModal> createState() => _UserSelectionModalState();
}

class _UserSelectionModalState extends State<UserSelectionModal> {
  List<User> selectedUsers = [];
  String searchQuery = '';
  UserRole? filterRole; // For filtering (show only specific role)
  UserRole? highlightRole; // For highlighting (highlight specific role)

  @override
  void initState() {
    super.initState();
    selectedUsers = List.from(widget.selectedUsers);
  }

  List<User> get filteredUsers {
    List<User> filtered = widget.allUsers;

    // Apply role filter (show only specific role)
    if (filterRole != null) {
      filtered = filtered.where((user) => user.role == filterRole).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (user) =>
                user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                user.email.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFe5e7eb),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'בחירת נמענים',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: const Color(0xFF6b7280),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onSelectionChanged(selectedUsers);
                    Navigator.pop(context);
                  },
                  child: const Text('אישור'),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
            child: Container(
              height: isTablet ? 56 : 48,
              decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFe5e7eb)),
              ),
              child: TextField(
                textDirection: TextDirection.rtl,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                style: TextStyle(fontSize: isTablet ? 18 : 16),
                decoration: InputDecoration(
                  hintText: 'חפש לפי שם או אימייל...',
                  hintStyle: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: const Color(0xFF9ca3af),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: isTablet ? 28 : 24,
                    color: const Color(0xFF9ca3af),
                  ),
                  suffixIcon: searchQuery.isNotEmpty || filterRole != null
                      ? IconButton(
                          onPressed: _clearFilters,
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF9ca3af),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 16 : 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Enhanced Quick Actions with Filter & Highlight
          _buildEnhancedQuickActions(isTablet),

          const SizedBox(height: 16),

          // Users List
          Expanded(child: _buildUsersList(isTablet)),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (filterRole != null) {
      final roleText = _getRoleText(filterRole!);
      final filteredCount = widget.allUsers
          .where((u) => u.role == filterRole)
          .length;
      return 'מציג $filteredCount $roleText | נבחרו ${selectedUsers.length}';
    }

    if (highlightRole != null) {
      final roleText = _getRoleText(highlightRole!);
      return 'מודגש $roleText | נבחרו ${selectedUsers.length} מתוך ${widget.allUsers.length}';
    }

    return 'נבחרו ${selectedUsers.length} מתוך ${widget.allUsers.length}';
  }

  Widget _buildEnhancedQuickActions(bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
      child: Column(
        children: [
          // Row 1: Selection Actions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionButton(
                  'כל הצוות',
                  Icons.groups,
                  const Color(0xFF3b82f6),
                  () => _selectAll(),
                  isTablet,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  'נקה הכל',
                  Icons.clear_all,
                  const Color(0xFFef4444),
                  () => _clearAll(),
                  isTablet,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Row 2: Filter & Highlight Actions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton(
                  'אמנים',
                  Icons.palette,
                  const Color(0xFF8b5cf6),
                  UserRole.client,
                  isTablet,
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  'מנחים',
                  Icons.school,
                  const Color(0xFF10b981),
                  UserRole.mentor,
                  isTablet,
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  'צוות',
                  Icons.admin_panel_settings,
                  const Color(0xFFf59e0b),
                  UserRole.staff,
                  isTablet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    String label,
    IconData icon,
    Color color,
    UserRole role,
    bool isTablet,
  ) {
    final isFiltered = filterRole == role;
    final isHighlighted = highlightRole == role;
    final isActive = isFiltered || isHighlighted;

    return Material(
      color: isActive ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      elevation: isActive ? 2 : 0,
      child: InkWell(
        onTap: () => _handleRoleAction(role),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isActive ? Border.all(color: color, width: 2) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? Colors.white : color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Icon(
                  isFiltered ? Icons.filter_list : Icons.highlight,
                  color: Colors.white,
                  size: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleRoleAction(UserRole role) {
    setState(() {
      if (filterRole == role) {
        // If already filtering this role, switch to highlight mode
        filterRole = null;
        highlightRole = role;
      } else if (highlightRole == role) {
        // If already highlighting this role, clear both
        highlightRole = null;
        filterRole = null;
      } else {
        // Start with filter mode
        filterRole = role;
        highlightRole = null;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      searchQuery = '';
      filterRole = null;
      highlightRole = null;
    });
  }

  Widget _buildUsersList(bool isTablet) {
    final users = filteredUsers;

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filterRole != null ? Icons.filter_list_off : Icons.search_off,
              size: 64,
              color: const Color(0xFF9ca3af),
            ),
            const SizedBox(height: 16),
            Text(
              filterRole != null
                  ? 'לא נמצאו ${_getRoleText(filterRole!)} במערכת'
                  : 'לא נמצאו משתמשים',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (filterRole != null || searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('נקה מסננים'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      controller: widget.scrollController,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = users[index];
        final isSelected = selectedUsers.contains(user);
        final shouldHighlight =
            highlightRole != null && user.role == highlightRole;

        return _buildUserListItem(user, isSelected, shouldHighlight, isTablet);
      },
    );
  }

  Widget _buildUserListItem(
    User user,
    bool isSelected,
    bool shouldHighlight,
    bool isTablet,
  ) {
    Color backgroundColor;
    Color borderColor;
    double elevation;

    if (isSelected) {
      backgroundColor = const Color(0xFF3b82f6).withOpacity(0.1);
      borderColor = const Color(0xFF3b82f6);
      elevation = 2;
    } else if (shouldHighlight) {
      backgroundColor = _getRoleColor(user.role).withOpacity(0.15);
      borderColor = _getRoleColor(user.role);
      elevation = 1;
    } else {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFe5e7eb);
      elevation = 1;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      elevation: elevation,
      shadowColor: shouldHighlight
          ? _getRoleColor(user.role).withOpacity(0.3)
          : Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => _toggleUser(user),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: (isSelected || shouldHighlight) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar with role indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: isTablet ? 28 : 24,
                    backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(user.role),
                      ),
                    ),
                  ),
                  if (shouldHighlight && !isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: isTablet ? 16 : 14,
                        height: isTablet ? 16 : 14,
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.highlight,
                          color: Colors.white,
                          size: isTablet ? 10 : 8,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(width: isTablet ? 16 : 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1f2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: const Color(0xFF6b7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(
                          user.role,
                        ).withOpacity(shouldHighlight ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: shouldHighlight
                            ? Border.all(
                                color: _getRoleColor(user.role),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Text(
                        _getRoleText(user.role),
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 11,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(user.role),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              Container(
                width: isTablet ? 32 : 28,
                height: isTablet ? 32 : 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3b82f6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3b82f6)
                        : shouldHighlight
                        ? _getRoleColor(user.role)
                        : const Color(0xFFd1d5db),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: isTablet ? 20 : 18,
                      )
                    : shouldHighlight
                    ? Icon(
                        Icons.highlight,
                        color: _getRoleColor(user.role),
                        size: isTablet ? 16 : 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleUser(User user) {
    setState(() {
      if (selectedUsers.contains(user)) {
        selectedUsers.remove(user);
      } else {
        selectedUsers.add(user);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selectedUsers = List.from(widget.allUsers);
    });
  }

  void _clearAll() {
    setState(() {
      selectedUsers.clear();
    });
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.client:
        return const Color(0xFF8b5cf6);
      case UserRole.mentor:
        return const Color(0xFF10b981);
      case UserRole.staff:
        return const Color(0xFFf59e0b);
    }
  }

  String _getRoleText(UserRole role) {
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
