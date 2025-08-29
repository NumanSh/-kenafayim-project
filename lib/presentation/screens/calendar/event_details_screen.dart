import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/calendar_event.dart';
import '../../../data/models/user.dart';

class EventDetailsScreen extends StatelessWidget {
  final CalendarEvent event;
  final User? user;

  const EventDetailsScreen({Key? key, required this.event, this.user})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          'פרטי אירוע',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        actions: [
          if (user?.isStaff == true)
            IconButton(
              onPressed: () => _showEditOptions(context),
              icon: const Icon(Icons.more_vert, color: Color(0xFF3b82f6)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEventHeader(),
            const SizedBox(height: 24),
            _buildEventDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            event.getEventColor(),
            event.getEventColor().withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: event.getEventColor().withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getEventIcon(), color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.getTypeDisplayName(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              Icons.calendar_today,
              'תאריך',
              DateFormat('EEEE, dd MMMM yyyy', 'he_IL').format(event.startTime),
            ),
            if (!event.isAllDay) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.access_time,
                'שעה',
                '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.timer,
                'משך',
                '${event.durationInMinutes} דקות',
              ),
            ],
            if (event.locationOrLink != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(Icons.location_on, 'מקום', event.locationOrLink!),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(Icons.person, 'נוצר על ידי', event.createdByName),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.priority_high,
              'עדיפות',
              event.getPriorityDisplayName(),
            ),
            if (event.participantIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.people,
                'משתתפים',
                '${event.participantIds.length} משתתפים',
              ),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.schedule,
              'נוצר',
              DateFormat('dd/MM/yyyy HH:mm').format(event.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFf8fafc),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6b7280), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6b7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getEventIcon() {
    switch (event.type) {
      case EventType.holiday:
        return Icons.celebration;
      case EventType.meeting:
        return Icons.meeting_room;
      case EventType.workshop:
        return Icons.school;
      case EventType.special_event:
        return Icons.event;
      case EventType.announcement:
        return Icons.campaign;
      case EventType.therapy:
        return Icons.healing;
      case EventType.other:
        return Icons.event_note;
    }
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFe5e7eb),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'פעולות על האירוע',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF3b82f6)),
                title: const Text('עריכת אירוע'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to edit screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFef4444)),
                title: const Text('מחיקת אירוע'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('מחיקת אירוע'),
        content: Text('האם אתה בטוח שברצונך למחוק את האירוע "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete event
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
