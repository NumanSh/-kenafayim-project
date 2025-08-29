import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/message.dart';
import '../../services/enhanced_message_service.dart'; // ✅ NOW EXISTS
import '../../config/service_locator.dart';

// ✅ Enhanced message service provider
final enhancedMessageServiceProvider = Provider<EnhancedMessageService>((ref) {
  return serviceLocator<EnhancedMessageService>();
});

// ✅ Messages stream provider using enhanced service
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  userId,
) {
  final messageService = ref.read(enhancedMessageServiceProvider);
  return messageService.getMessagesForUser(userId, null);
});

// Unread messages count provider
final unreadMessagesCountProvider = Provider.family<int, String>((ref, userId) {
  final messagesAsync = ref.watch(messagesStreamProvider(userId));
  return messagesAsync.when(
    data: (messages) =>
        messages.where((m) => !m.isRead && m.senderId != userId).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
