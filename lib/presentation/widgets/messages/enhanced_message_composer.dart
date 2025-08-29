import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/presentation/screens/messages_screen.dart';
import 'package:knafayim_app/presentation/widgets/messages/user_selection_widget.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../services/message_service.dart';
import '../../../config/service_locator.dart';

class EnhancedMessageComposer extends ConsumerStatefulWidget {
  final User user;

  const EnhancedMessageComposer({Key? key, required this.user})
    : super(key: key);

  @override
  ConsumerState<EnhancedMessageComposer> createState() =>
      _EnhancedMessageComposerState();
}

class _EnhancedMessageComposerState
    extends ConsumerState<EnhancedMessageComposer> {
  List<User> _selectedUsers = [];
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  final TextEditingController _messageTitleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSendingMessage = false;
  List<User> _allUsers = []; // Add this to store all users

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _messageTitleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    try {
      final users = await _userRepository.getAllUsers();
      setState(() {
        _allUsers = users;
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  void _removeUser(User user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3b82f6),
                      const Color(0xFF3b82f6).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.campaign,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'מרכז תקשורת',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1f2937),
                      ),
                    ),
                    Text(
                      'שלח הודעות לצוות ולמשתתפים',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: const Color(0xFF6b7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _navigateToFullMessages(context),
                icon: Icon(Icons.open_in_new, size: isTablet ? 24 : 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFf1f5f9),
                  foregroundColor: const Color(0xFF64748b),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 24 : 16),

        // Enhanced message composer
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildRecipientSelector(isTablet),
                _buildMessageInput(isTablet),
                _buildMessageActions(isTablet),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientSelector(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFe2e8f0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 10 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.people,
                  color: const Color(0xFF3b82f6),
                  size: isTablet ? 24 : 20,
                ),
              ),
              SizedBox(width: isTablet ? 12 : 10),
              Text(
                'בחר נמענים:',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),

          // Selection Button + Selected Count
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 1,
            child: InkWell(
              onTap: () => _showUserSelectionModal(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedUsers.isEmpty
                        ? const Color(0xFFe5e7eb)
                        : const Color(0xFF3b82f6),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedUsers.isEmpty ? Icons.add : Icons.people,
                      color: _selectedUsers.isEmpty
                          ? const Color(0xFF9ca3af)
                          : const Color(0xFF3b82f6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedUsers.isEmpty
                            ? 'לחץ לבחירת נמענים...'
                            : 'נבחרו ${_selectedUsers.length} נמענים',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: _selectedUsers.isEmpty
                              ? const Color(0xFF9ca3af)
                              : const Color(0xFF1f2937),
                          fontWeight: _selectedUsers.isEmpty
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: const Color(0xFF9ca3af),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Selected Users Preview (if any)
          if (_selectedUsers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSelectedUsersPreview(isTablet),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedUsersPreview(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3b82f6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'נמענים נבחרים:',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3b82f6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedUsers.take(5).map((user) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF3b82f6).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 11,
                        color: const Color(0xFF1f2937),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeUser(user),
                      child: Icon(
                        Icons.close,
                        size: isTablet ? 14 : 12,
                        color: const Color(0xFF6b7280),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (_selectedUsers.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'ועוד ${_selectedUsers.length - 5} נוספים...',
                style: TextStyle(
                  fontSize: isTablet ? 11 : 10,
                  color: const Color(0xFF6b7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showUserSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => UserSelectionModal(
          allUsers: _allUsers,
          selectedUsers: _selectedUsers,
          onSelectionChanged: (users) {
            setState(() {
              _selectedUsers = users;
            });
          },
          scrollController: scrollController,
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isTablet ? 56 : 48,
            height: isTablet ? 56 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3b82f6),
                  const Color(0xFF3b82f6).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
            ),
            child: Center(
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase()
                    : 'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 20 : 18,
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFe2e8f0)),
                  ),
                  child: TextField(
                    controller: _messageTitleController,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                    decoration: InputDecoration(
                      hintText: 'כותרת ההודעה...',
                      hintStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 16 : 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFe2e8f0)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                    decoration: InputDecoration(
                      hintText: 'כתוב את ההודעה שלך...',
                      hintStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 16 : 12,
                      ),
                    ),
                    maxLines: isTablet ? 4 : 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageActions(bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'תמונה',
                  color: const Color(0xFF10b981),
                  onTap: _handlePhotoUpload,
                  isTablet: isTablet,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                _buildActionButton(
                  icon: Icons.attach_file_outlined,
                  label: 'קובץ',
                  color: const Color(0xFF3b82f6),
                  onTap: _handleFileUpload,
                  isTablet: isTablet,
                ),
              ],
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8b5cf6), Color(0xFFa855f7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8b5cf6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isSendingMessage ? null : _sendEnhancedMessage,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 28 : 24,
                    vertical: isTablet ? 16 : 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSendingMessage)
                        SizedBox(
                          width: isTablet ? 20 : 16,
                          height: isTablet ? 20 : 16,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      else
                        Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: isTablet ? 20 : 18,
                        ),
                      SizedBox(width: isTablet ? 10 : 8),
                      Text(
                        'שלח הודעה',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 12 : 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: isTablet ? 20 : 18),
                SizedBox(width: isTablet ? 8 : 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendEnhancedMessage() async {
    if (_messageTitleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא מלא כותרת ותוכן ההודעה'),
          backgroundColor: Color(0xFFef4444),
        ),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר לפחות נמען אחד'),
          backgroundColor: Color(0xFFef4444),
        ),
      );
      return;
    }

    setState(() => _isSendingMessage = true);

    try {
      final messageService = serviceLocator<MessageService>();
      final recipientIds = _selectedUsers.map((user) => user.id).toList();

      await messageService.addMessage(
        title: _messageTitleController.text.trim(),
        content: _messageController.text.trim(),
        createdBy: widget.user.id,
        senderId: widget.user.id,
        recipientIds: recipientIds,
        recipientEmail: null,
        senderRole: widget.user.role,
      );

      if (mounted) {
        _messageTitleController.clear();
        _messageController.clear();
        setState(() {
          _selectedUsers.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ההודעה נשלחה ל-${recipientIds.length} משתמשים בהצלחה',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10b981),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשליחת ההודעה: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingMessage = false);
      }
    }
  }

  void _navigateToFullMessages(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesScreen(user: widget.user),
      ),
    );
  }

  void _handlePhotoUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('פתיחת גלריית תמונות...'),
        backgroundColor: Color(0xFF10b981),
      ),
    );
  }

  void _handleFileUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('פתיחת מנהל קבצים...'),
        backgroundColor: Color(0xFF3b82f6),
      ),
    );
  }
}
