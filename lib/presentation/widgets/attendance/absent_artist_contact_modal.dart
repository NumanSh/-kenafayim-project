import 'package:flutter/material.dart';
import '../../../data/models/user.dart';
import '../../../data/models/attendance_record.dart';
import '../../../data/models/lesson.dart';

class AbsentArtistContactModal extends StatefulWidget {
  final User artist;
  final AttendanceRecord attendanceRecord;
  final Lesson lesson;

  const AbsentArtistContactModal({
    Key? key,
    required this.artist,
    required this.attendanceRecord,
    required this.lesson,
  }) : super(key: key);

  @override
  State<AbsentArtistContactModal> createState() =>
      _AbsentArtistContactModalState();
}

class _AbsentArtistContactModalState extends State<AbsentArtistContactModal> {
  final TextEditingController _notesController = TextEditingController();
  bool _isContactAttempted = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_off, color: Color(0xFFef4444)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'תלמיד נעדר',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Text(
                        widget.artist.name,
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
            const SizedBox(height: 20),

            // Contact Information
            _buildContactInfo(),

            const SizedBox(height: 16),

            // Notes Section
            _buildNotesSection(),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'פרטי קשר:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),

          if (widget.artist.phoneNumber.isNotEmpty) ...[
            _buildContactRow(Icons.phone, 'טלפון', widget.artist.phoneNumber),
          ],

          if (widget.artist.emergencyContact?.isNotEmpty == true) ...[
            _buildContactRow(
              Icons.contact_emergency,
              'איש קשר חירום',
              widget.artist.emergencyContact!,
            ),
          ],

          if (widget.artist.emergencyContactPhone?.isNotEmpty == true) ...[
            _buildContactRow(
              Icons.phone_callback,
              'טלפון חירום',
              widget.artist.emergencyContactPhone!,
            ),
          ],

          if (widget.artist.emergencyContactRelation?.isNotEmpty == true) ...[
            _buildContactRow(
              Icons.family_restroom,
              'קרבה',
              widget.artist.emergencyContactRelation!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6b7280)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6b7280),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1f2937)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'הערות לגבי היעדרות:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'הכנס הערות לגבי שיחה עם התלמיד/הורה...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3b82f6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ביטול'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveContactAttempt,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('שמור'),
          ),
        ),
      ],
    );
  }

  void _saveContactAttempt() {
    final notes = _notesController.text.trim();

    // Return the notes to the parent
    Navigator.of(context).pop({'notes': notes, 'contactAttempted': true});
  }
}
