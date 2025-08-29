import 'package:flutter/material.dart';
import 'package:knafayim_app/presentation/widgets/messages/user_selection_widget.dart';
import 'package:knafayim_app/services/enhanced_message_service.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../services/message_service.dart';
import '../../../config/service_locator.dart';

class MessageComposerModal extends StatefulWidget {
  final User user;
  final ScrollController scrollController;

  const MessageComposerModal({
    super.key,
    required this.user,
    required this.scrollController,
  });

  @override
  State<MessageComposerModal> createState() => _MessageComposerModalState();
}

class _MessageComposerModalState extends State<MessageComposerModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // New variables for user selection
  List<User> _selectedUsers = [];
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  bool _isSending = false;
  List<User> _allUsers = []; // Add this to store all users

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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

          // Enhanced Header
          Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF64748b)),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'הודעה חדשה',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1f2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedUsers.isNotEmpty)
                        Text(
                          'נבחרו ${_selectedUsers.length} נמענים',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: const Color(0xFF3b82f6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
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
                      onTap: _isSending ? null : _sendMessage,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                          vertical: isTablet ? 12 : 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSending)
                              SizedBox(
                                width: isTablet ? 18 : 16,
                                height: isTablet ? 18 : 16,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: isTablet ? 18 : 16,
                              ),
                            SizedBox(width: isTablet ? 8 : 6),
                            Text(
                              'שלח',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Recipient selection
                  _buildRecipientSection(isTablet),
                  SizedBox(height: isTablet ? 28 : 24),

                  // Enhanced Title field
                  _buildTextField(
                    controller: _titleController,
                    label: 'נושא',
                    hint: 'כתוב את נושא ההודעה...',
                    icon: Icons.subject,
                    isTablet: isTablet,
                  ),
                  SizedBox(height: isTablet ? 20 : 16),

                  // Enhanced Content field
                  _buildTextField(
                    controller: _contentController,
                    label: 'תוכן ההודעה',
                    hint: 'כתוב את תוכן ההודעה...',
                    maxLines: isTablet ? 6 : 5,
                    icon: Icons.message,
                    isTablet: isTablet,
                  ),

                  SizedBox(height: isTablet ? 32 : 24),

                  // Send button (mobile only - tablet has it in header)
                  if (!isTablet) _buildMobileSendButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientSection(bool isTablet) {
    return Column(
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isTablet,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 8 : 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8b5cf6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8b5cf6),
                size: isTablet ? 20 : 18,
              ),
            ),
            SizedBox(width: isTablet ? 10 : 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: const Color(0xFF1f2937),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: const Color(0xFF9ca3af),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF3b82f6),
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 16 : 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSendButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8b5cf6), Color(0xFFa855f7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8b5cf6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSending ? null : _sendMessage,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSending)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  _isSending ? 'שולח הודעה...' : 'שלח הודעה',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    // Validation
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showErrorSnackBar('אנא מלא את כל השדות');
      return;
    }

    if (_selectedUsers.isEmpty) {
      _showErrorSnackBar('אנא בחר לפחות נמען אחד');
      return;
    }

    setState(() => _isSending = true);

    try {
      final messageService = serviceLocator<EnhancedMessageService>();
      final recipientIds = _selectedUsers.map((user) => user.id).toList();

      await messageService.addMessage(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdBy: widget.user.id,
        senderId: widget.user.id,
        recipientIds: recipientIds,
        recipientEmail: null,
        senderRole: widget.user.role,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ההודעה נשלחה ל-${recipientIds.length} משתמשים בהצלחה!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10b981),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('שגיאה בשליחת ההודעה: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFef4444),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
