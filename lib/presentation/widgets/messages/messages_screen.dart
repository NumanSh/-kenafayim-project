import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/services/enhanced_message_service.dart';
import '../../../data/models/user.dart';
import '../../../data/models/message.dart';
import '../../../data/repositories/message_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../../../config/themes.dart';
import 'package:intl/intl.dart';

// Riverpod providers for real-time updates (PLACE THIS BEFORE THE CLASS)
final messageServiceProvider = Provider(
  (ref) => serviceLocator<EnhancedMessageService>(),
); // ✅ CHANGED

final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  userId,
) {
  final messageService = ref.watch(messageServiceProvider);
  return messageService.getMessagesForUser(userId, null);
});

final unreadMessagesCountProvider = Provider.family<int, String>((ref, userId) {
  final messagesAsync = ref.watch(messagesStreamProvider(userId));
  return messagesAsync.when(
    data: (messages) => messages
        .where((msg) => !msg.isReadBy(userId) && msg.senderId != userId)
        .length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

class MessagesScreen extends StatefulWidget {
  final User user;

  const MessagesScreen({super.key, required this.user});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageRepository _messageRepository =
      serviceLocator<MessageRepository>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  List<Message> _messages = [];
  Map<String, User> _users = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // שימוש בפונקציה המעודכנת שמחזירה הודעות למשתמש ספציפי (כולל הודעות כלליות)
      final messages = await _messageRepository.getMessagesForUser(
        widget.user.id,
        userEmail: widget.user.email,
      );

      // Get unique user IDs from messages
      final Set<String> userIds = {};
      for (final message in messages) {
        userIds.add(message.senderId);
        userIds.addAll(message.recipientIds);
      }
      userIds.remove(widget.user.id); // Remove current user

      // Load user data for all users in messages
      final Map<String, User> users = {};
      for (final userId in userIds) {
        try {
          final user = await _userRepository.getUserById(userId);
          users[userId] = user!;
        } catch (e) {
          // Skip users that couldn't be loaded
        }
      }

      setState(() {
        _messages = messages;
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בטעינת הודעות: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
          ? _buildEmptyState()
          : _buildMessagesList(),
      // הצגת כפתור הוספת הודעה רק לצוות
      floatingActionButton: widget.user.role == UserRole.staff
          ? FloatingActionButton(
              onPressed: () {
                _showAddMessageDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddMessageDialog(BuildContext context) {
    // בדיקה שהמשתמש הוא איש צוות
    if (widget.user.role != UserRole.staff) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('רק אנשי צוות רשאים להוסיף הודעות'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final recipientController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הוספת הודעה חדשה'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'כותרת',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: recipientController,
                decoration: const InputDecoration(
                  labelText: 'מזהה נמען (אופציונלי)',
                  border: OutlineInputBorder(),
                  hintText: 'השאר ריק להודעה לכל המשתמשים',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'כתובת מייל נמען (אופציונלי)',
                  border: OutlineInputBorder(),
                  hintText: 'לשיוך אוטומטי של הודעות למשתמש ספציפי',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'תוכן',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                try {
                  // הכנת רשימת הנמענים
                  List<String> recipientIds = [];
                  if (recipientController.text.isNotEmpty) {
                    recipientIds.add(recipientController.text);
                  }

                  // אם יש כתובת מייל, ננסה למצוא את המשתמש המתאים
                  String? recipientEmail;
                  if (emailController.text.isNotEmpty) {
                    recipientEmail = emailController.text;

                    // ניסיון למצוא את המשתמש לפי המייל
                    final userId = await _messageRepository.findUserIdByEmail(
                      recipientEmail,
                    );
                    if (userId != null && !recipientIds.contains(userId)) {
                      recipientIds.add(userId);
                    }
                  }

                  // יצירת הודעה חדשה
                  final now = DateTime.now();
                  final message = Message(
                    id: '', // Will be set by Firestore
                    title: titleController.text,
                    content: contentController.text,
                    createdAt: now,
                    createdBy: widget.user.id,
                    senderId: widget.user.id,
                    recipientIds: recipientIds,
                    timestamp: now,
                    isRead: false,
                    readBy: [],
                    recipientEmail: recipientEmail,
                  );

                  // שליחת ההודעה
                  await _messageRepository.sendMessage(
                    message,
                    widget.user.role,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ההודעה נשלחה בהצלחה'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // טעינה מחדש של ההודעות
                    _loadMessages();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('שגיאה בשליחת ההודעה: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('שלח'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.message, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'אין הודעות',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.role == UserRole.staff
                ? 'התחל שיחה חדשה עם הלחצן למטה'
                : 'אין הודעות להצגה כרגע',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    // Group messages by conversation
    final Map<String, Message> latestMessageByUser = {};

    for (final message in _messages) {
      final otherUserId = message.senderId == widget.user.id
          ? message.recipientIds.isNotEmpty
                ? message.recipientIds.first
                : "broadcast"
          : message.senderId;

      if (!latestMessageByUser.containsKey(otherUserId) ||
          latestMessageByUser[otherUserId]!.timestamp.isBefore(
            message.timestamp,
          )) {
        latestMessageByUser[otherUserId] = message;
      }
    }

    // Sort conversations by latest message timestamp
    final List<MapEntry<String, Message>> sortedConversations =
        latestMessageByUser.entries.toList()
          ..sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));

    return ListView.builder(
      itemCount: sortedConversations.length,
      itemBuilder: (context, index) {
        final otherUserId = sortedConversations[index].key;
        final latestMessage = sortedConversations[index].value;
        final otherUser = otherUserId == "broadcast"
            ? null
            : _users[otherUserId];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: otherUserId == "broadcast"
                  ? const Icon(Icons.campaign, size: 20, color: Colors.orange)
                  : otherUser?.profileImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        otherUser!.profileImageUrl!,
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
                  : Icon(Icons.person, size: 20, color: AppTheme.primaryColor),
            ),
            title: Text(
              otherUserId == "broadcast"
                  ? "הודעה לכל המשתמשים"
                  : otherUser?.name ?? 'משתמש לא ידוע',
              style: TextStyle(
                fontWeight: latestMessage.isRead
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latestMessage.content.length > 30
                      ? '${latestMessage.content.substring(0, 30)}...'
                      : latestMessage.content,
                  style: TextStyle(
                    fontWeight: latestMessage.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                if (latestMessage.recipientEmail != null)
                  Text(
                    'למייל: ${latestMessage.recipientEmail}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(latestMessage.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                if (!latestMessage.isRead &&
                    latestMessage.senderId != widget.user.id)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor,
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Mark message as read
              if (!latestMessage.isRead &&
                  latestMessage.senderId != widget.user.id) {
                _messageRepository.markMessageAsRead(
                  latestMessage.id,
                  widget.user.id,
                );
              }

              // Show message details
              _showMessageDetails(context, latestMessage);
            },
          ),
        );
      },
    );
  }

  void _showMessageDetails(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(message.timestamp),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (message.isBroadcast())
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'הודעה לכל המשתמשים',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (message.recipientEmail != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'נשלח למייל: ${message.recipientEmail}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              Text(message.content),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
          // הצגת כפתורי עריכה ומחיקה רק לצוות
          if (widget.user.role == UserRole.staff)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditMessageDialog(context, message);
              },
              child: const Text('ערוך'),
            ),
          if (widget.user.role == UserRole.staff)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(context, message);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('מחק'),
            ),
        ],
      ),
    );
  }

  // עריכת הודעה קיימת (רק לצוות)
  void _showEditMessageDialog(BuildContext context, Message message) {
    // בדיקה שהמשתמש הוא איש צוות
    if (widget.user.role != UserRole.staff) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('רק אנשי צוות רשאים לערוך הודעות'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController(text: message.title);
    final contentController = TextEditingController(text: message.content);
    final recipientController = TextEditingController(
      text: message.recipientIds.isNotEmpty
          ? message.recipientIds.join(', ')
          : '',
    );
    final emailController = TextEditingController(
      text: message.recipientEmail ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('עריכת הודעה'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'כותרת',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: recipientController,
                decoration: const InputDecoration(
                  labelText: 'מזהה נמען (אופציונלי)',
                  border: OutlineInputBorder(),
                  hintText: 'השאר ריק להודעה לכל המשתמשים',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'כתובת מייל נמען (אופציונלי)',
                  border: OutlineInputBorder(),
                  hintText: 'לשיוך אוטומטי של הודעות למשתמש ספציפי',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'תוכן',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                try {
                  // הכנת רשימת הנמענים
                  List<String> recipientIds = [];
                  if (recipientController.text.isNotEmpty) {
                    recipientIds = recipientController.text
                        .split(',')
                        .map((id) => id.trim())
                        .toList();
                  }

                  // הכנת נתוני העדכון
                  final updateData = {
                    'title': titleController.text,
                    'content': contentController.text,
                    'recipientIds': recipientIds,
                  };

                  if (emailController.text.isNotEmpty) {
                    updateData['recipientEmail'] = emailController.text;
                  } else {
                    // אם המייל ריק, נמחק את המפתח מהמילון במקום להגדיר null
                    updateData.remove('recipientEmail');
                  }

                  // עדכון ההודעה
                  await _messageRepository.updateMessage(
                    message.id,
                    updateData,
                    widget.user.role,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ההודעה עודכנה בהצלחה'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // טעינה מחדש של ההודעות
                    _loadMessages();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('שגיאה בעדכון ההודעה: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  // אישור מחיקת הודעה (רק לצוות)
  void _showDeleteConfirmation(BuildContext context, Message message) {
    // בדיקה שהמשתמש הוא איש צוות
    if (widget.user.role != UserRole.staff) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('רק אנשי צוות רשאים למחוק הודעות'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת הודעה'),
        content: const Text('האם אתה בטוח שברצונך למחוק הודעה זו?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _messageRepository.deleteMessage(
                  message.id,
                  widget.user.role,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ההודעה נמחקה בהצלחה'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // טעינה מחדש של ההודעות
                  _loadMessages();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('שגיאה במחיקת ההודעה: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }
}
