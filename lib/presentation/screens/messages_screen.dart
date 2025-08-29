import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/user.dart';
import '../../data/models/message.dart';
import '../../services/message_service.dart';
import '../widgets/messages/message_composer_modal.dart';

// Riverpod providers for real-time updates
final messageServiceProvider = Provider((ref) => MessageService());

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

class MessagesScreen extends ConsumerStatefulWidget {
  final User user;

  const MessagesScreen({Key? key, required this.user}) : super(key: key);

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Only staff gets 2 tabs (Inbox + Sent), others get 1 tab (Inbox only)
    final tabCount = widget.user.role == UserRole.staff ? 2 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: Column(
        children: [
          _buildModernAppBar(isTablet),
          if (widget.user.role == UserRole.staff) _buildTabBar(isTablet),
          Expanded(
            child: widget.user.role == UserRole.staff
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInboxTab(isTablet),
                      _buildSentTab(isTablet),
                    ],
                  )
                : _buildInboxTab(isTablet), // Only inbox for artists/mentors
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(isTablet),
    );
  }

  Widget _buildModernAppBar(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3b82f6),
            const Color(0xFF3b82f6).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'הודעות',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final unreadCount = ref.watch(
                              unreadMessagesCountProvider(widget.user.id),
                            );
                            return Text(
                              unreadCount > 0
                                  ? '$unreadCount הודעות חדשות'
                                  : 'אין הודעות חדשות',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showSearch = !_showSearch;
                      });
                    },
                    icon: Icon(
                      _showSearch ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
              if (_showSearch) ...[
                const SizedBox(height: 16),
                _buildSearchBar(isTablet),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'חפש הודעות...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 16 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isTablet) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF3b82f6),
        unselectedLabelColor: const Color(0xFF6b7280),
        indicatorColor: const Color(0xFF3b82f6),
        indicatorWeight: 3,
        labelStyle: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.normal,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox),
                const SizedBox(width: 8),
                const Text('נכנסות'),
                Consumer(
                  builder: (context, ref, child) {
                    final unreadCount = ref.watch(
                      unreadMessagesCountProvider(widget.user.id),
                    );
                    if (unreadCount > 0) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.send), SizedBox(width: 8), Text('נשלחות')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxTab(bool isTablet) {
    return Consumer(
      builder: (context, ref, child) {
        final messagesAsync = ref.watch(messagesStreamProvider(widget.user.id));

        return messagesAsync.when(
          data: (messages) {
            // Filter for inbox messages (received by user)
            final inboxMessages = messages
                .where(
                  (msg) =>
                      (msg.recipientIds.contains(widget.user.id) ||
                          msg.recipientIds.isEmpty ||
                          msg.recipientEmail == widget.user.email) &&
                      msg.senderId != widget.user.id,
                )
                .toList();

            // Apply search filter
            final filteredMessages = _searchQuery.isEmpty
                ? inboxMessages
                : inboxMessages
                      .where(
                        (msg) =>
                            msg.title.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            msg.content.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();

            if (filteredMessages.isEmpty) {
              return _buildEmptyState(
                'אין הודעות נכנסות',
                Icons.inbox,
                isTablet,
              );
            }

            return _buildMessagesList(
              filteredMessages,
              isTablet,
              isInbox: true,
            );
          },
          loading: () => _buildLoadingState(isTablet),
          error: (error, stack) => _buildErrorState(error.toString(), isTablet),
        );
      },
    );
  }

  Widget _buildSentTab(bool isTablet) {
    return Consumer(
      builder: (context, ref, child) {
        final messagesAsync = ref.watch(messagesStreamProvider(widget.user.id));

        return messagesAsync.when(
          data: (messages) {
            // Filter for sent messages
            final sentMessages = messages
                .where((msg) => msg.senderId == widget.user.id)
                .toList();

            // Apply search filter
            final filteredMessages = _searchQuery.isEmpty
                ? sentMessages
                : sentMessages
                      .where(
                        (msg) =>
                            msg.title.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            msg.content.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();

            if (filteredMessages.isEmpty) {
              return _buildEmptyState(
                'אין הודעות נשלחות',
                Icons.send,
                isTablet,
              );
            }

            return _buildMessagesList(
              filteredMessages,
              isTablet,
              isInbox: false,
            );
          },
          loading: () => _buildLoadingState(isTablet),
          error: (error, stack) => _buildErrorState(error.toString(), isTablet),
        );
      },
    );
  }

  Widget _buildMessagesList(
    List<Message> messages,
    bool isTablet, {
    required bool isInbox,
  }) {
    return ListView.separated(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      itemCount: messages.length,
      separatorBuilder: (context, index) => SizedBox(height: isTablet ? 12 : 8),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUnread = isInbox && !message.isReadBy(widget.user.id);

        return _buildMessageCard(message, isTablet, isUnread, isInbox);
      },
    );
  }

  Widget _buildMessageCard(
    Message message,
    bool isTablet,
    bool isUnread,
    bool isInbox,
  ) {
    return Material(
      color: isUnread
          ? const Color(0xFF3b82f6).withOpacity(0.05)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isUnread ? 3 : 1,
      shadowColor: isUnread
          ? const Color(0xFF3b82f6).withOpacity(0.3)
          : Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => _showMessageDetails(message, isInbox),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFF3b82f6).withOpacity(0.3)
                  : const Color(0xFFe5e7eb),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3b82f6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      message.title,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: isUnread
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: const Color(0xFF1f2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 11,
                      color: const Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                message.content,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  color: const Color(0xFF6b7280),
                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: message.isBroadcast()
                          ? const Color(0xFFf59e0b).withOpacity(0.1)
                          : const Color(0xFF8b5cf6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      message.isBroadcast() ? 'הודעה כללית' : 'הודעה אישית',
                      style: TextStyle(
                        fontSize: isTablet ? 11 : 10,
                        fontWeight: FontWeight.w500,
                        color: message.isBroadcast()
                            ? const Color(0xFFf59e0b)
                            : const Color(0xFF8b5cf6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isTablet ? 80 : 64, color: const Color(0xFF9ca3af)),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            message,
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6b7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'טוען הודעות...',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: const Color(0xFF6b7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isTablet ? 64 : 48,
            color: const Color(0xFFef4444),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'שגיאה בטעינת הודעות',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFef4444),
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            error,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: const Color(0xFF6b7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isTablet) {
    // Only staff can compose messages
    if (widget.user.role != UserRole.staff) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _showComposeModal,
      backgroundColor: const Color(0xFF3b82f6),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.edit),
      label: Text(
        'הודעה חדשה',
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showMessageDetails(Message message, bool isInbox) {
    if (isInbox && !message.isReadBy(widget.user.id)) {
      // Mark as read
      ref.read(messageServiceProvider).markAsRead(message.id, widget.user.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(
                      child: Text(
                        message.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(message.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        message.content,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComposeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => MessageComposerModal(
          user: widget.user,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
