import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/presentation/widgets/lessons/lesson_edit_modal.dart';
import 'package:knafayim_app/presentation/widgets/lessons/participant_management_modal.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/user.dart';
import '../../providers/lesson_providers.dart';

class LessonDetailsModal extends ConsumerStatefulWidget {
  final Lesson lesson;
  final User currentUser;

  const LessonDetailsModal({
    super.key,
    required this.lesson,
    required this.currentUser,
    required bool isRegistered,
    required User user,
    VoidCallback? onJoinClass,
  });

  @override
  ConsumerState<LessonDetailsModal> createState() => _LessonDetailsModalState();
}

class _LessonDetailsModalState extends ConsumerState<LessonDetailsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // FIXED: Set selected lesson for participants provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedLessonProvider.notifier).select(widget.lesson);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(
      lessonParticipantsProvider(widget.lesson.id),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildParticipantsTab(participantsAsync),
                _buildActionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3b82f6),
            const Color(0xFF3b82f6).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Lesson title and info
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lesson.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy • HH:mm',
                      ).format(widget.lesson.date),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'פרטים'),
          Tab(text: 'משתתפים'),
          Tab(text: 'פעולות'),
        ],
        labelColor: const Color(0xFF3b82f6),
        unselectedLabelColor: const Color(0xFF6b7280),
        indicatorColor: const Color(0xFF3b82f6),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard('מידע כללי', [
            _buildDetailRow('שם השיעור', widget.lesson.title),
            _buildDetailRow(
              'תאריך',
              DateFormat('dd/MM/yyyy').format(widget.lesson.date),
            ),
            _buildDetailRow(
              'שעה',
              DateFormat('HH:mm').format(widget.lesson.date),
            ),
            _buildDetailRow('משך זמן', '${widget.lesson.durationMinutes} דקות'),
            _buildDetailRow('סטטוס', _getStatusText(widget.lesson.status)),
          ]),
          const SizedBox(height: 20),
          _buildDetailCard('פרטי מנחה', [
            _buildDetailRow(
              'שם המנחה',
              widget.lesson.instructorName ?? 'לא צוין',
            ),
            _buildDetailRow(
              'אימייל',
              widget.lesson.instructorEmail ?? 'לא צוין',
            ),
          ]),
          const SizedBox(height: 20),
          _buildDetailCard('הגדרות', [
            _buildDetailRow(
              'קיבולת מקסימלית',
              widget.lesson.maxCapacity?.toString() ?? 'ללא הגבלה',
            ),
            _buildDetailRow(
              'משתתפים רשומים',
              '${widget.lesson.registeredArtistIds.length}',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(AsyncValue<List<User>> participantsAsync) {
    return participantsAsync.when(
      data: (participants) => participants.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Color(0xFF6b7280),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'אין משתתפים רשומים',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                return _buildParticipantCard(participant);
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('שגיאה בטעינת משתתפים: $error')),
    );
  }

  Widget _buildActionsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildActionCard(
            'עריכת שיעור',
            'ערוך את פרטי השיעור',
            Icons.edit,
            const Color(0xFF3b82f6),
            () => _editLesson(),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            'ניהול משתתפים',
            'הוסף או הסר משתתפים',
            Icons.people,
            const Color(0xFF10b981),
            () => _manageParticipants(),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            'מחיקת שיעור',
            'מחק את השיעור לצמיתות',
            Icons.delete,
            const Color(0xFFef4444),
            () => _deleteLesson(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFe2e8f0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'סגור',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6b7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1f2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(User participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF3b82f6).withOpacity(0.1),
            child: Text(
              participant.name.isNotEmpty
                  ? participant.name[0].toUpperCase()
                  : 'A',
              style: const TextStyle(
                color: Color(0xFF3b82f6),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  participant.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  void _editLesson() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonEditModal(
        lesson: widget.lesson,
        onLessonCreated:
            () async {}, // Provide an empty callback or your logic here
      ),
    ).then((result) {
      // If edit was successful, close the details modal too
      if (result == true) {
        Navigator.of(context).pop();
      }
    });
  }

  void _manageParticipants() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParticipantManagementModal(lesson: widget.lesson),
    ).then((result) {
      // FIXED: Force refresh participants when modal closes with success
      if (result == true) {
        ref.invalidate(lessonParticipantsProvider(widget.lesson.id));
        // Also refresh the lesson details count
        setState(() {}); // This will rebuild the details tab with updated count
      }
    });
  }

  void _deleteLesson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('מחיקת שיעור'),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את השיעור "${widget.lesson.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(lessonNotifierProvider.notifier)
            .deleteLesson(widget.lesson.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('השיעור נמחק בהצלחה'),
              backgroundColor: Color(0xFF10b981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('שגיאה במחיקת השיעור: $e')));
        }
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'מתוכנן';
      case 'completed':
        return 'הושלם';
      case 'cancelled':
        return 'בוטל';
      default:
        return status;
    }
  }
}
