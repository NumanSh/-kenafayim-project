import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/user.dart';
import '../../../data/models/attendance_record.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';

class LessonAttendanceScreen extends ConsumerStatefulWidget {
  final Lesson lesson;
  final User mentor;

  const LessonAttendanceScreen({
    Key? key,
    required this.lesson,
    required this.mentor,
  }) : super(key: key);

  @override
  ConsumerState<LessonAttendanceScreen> createState() =>
      _LessonAttendanceScreenState();
}

class _LessonAttendanceScreenState
    extends ConsumerState<LessonAttendanceScreen> {
  final AttendanceRepository _attendanceRepository =
      serviceLocator<AttendanceRepository>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  List<User> _registeredArtists = [];
  Map<String, AttendanceRecord> _attendanceRecords = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRegisteredArtists();
  }

  Future<void> _loadRegisteredArtists() async {
    setState(() => _isLoading = true);

    try {
      // Load all registered artists for this lesson
      final artists = <User>[];
      for (final artistId in widget.lesson.registeredArtistIds) {
        final user = await _userRepository.getUserById(artistId);
        if (user != null) {
          artists.add(user);
        }
      }

      // Initialize attendance records
      final attendanceMap = <String, AttendanceRecord>{};
      for (final record in widget.lesson.attendanceRecords) {
        attendanceMap[record.artistId] = record;
      }

      // Create pending records for artists without attendance
      for (final artist in artists) {
        if (!attendanceMap.containsKey(artist.id)) {
          attendanceMap[artist.id] = AttendanceRecord(
            id: '${widget.lesson.id}_${artist.id}',
            artistId: artist.id,
            lessonId: widget.lesson.id,
            date: widget.lesson.date,
            status: 'pending',
          );
        }
      }

      setState(() {
        _registeredArtists = artists;
        _attendanceRecords = attendanceMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת רשימת האמנים: $e')));
    }
  }

  Future<void> _updateAttendance(
    String artistId,
    String status, {
    String? notes,
  }) async {
    final record = _attendanceRecords[artistId];
    if (record == null) return;

    final updatedRecord = record.copyWith(
      status: status,
      notes: notes,
      markedBy: widget.mentor.id,
      checkedInAt: status == 'present' ? DateTime.now() : null,
    );

    setState(() {
      _attendanceRecords[artistId] = updatedRecord;
    });

    // Update in Firestore
    try {
      await _attendanceRepository.updateLessonAttendance(
        lessonId: widget.lesson.id,
        artistId: artistId,
        status: status,
        notes: notes,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה בעדכון נוכחות: $e')));
    }
  }

  Future<void> _markAllPresent() async {
    setState(() => _isSaving = true);

    for (final artist in _registeredArtists) {
      await _updateAttendance(artist.id, 'present');
    }

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('כל האמנים סומנו כנוכחים'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: Text(
          'נוכחות - ${widget.lesson.title}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _registeredArtists.isNotEmpty)
            TextButton.icon(
              onPressed: _isSaving ? null : _markAllPresent,
              icon: const Icon(Icons.done_all),
              label: const Text('סמן הכל כנוכח'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF10b981),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Lesson info header
                _buildLessonInfoHeader(),

                // Attendance summary
                _buildAttendanceSummary(),

                // Artists list
                Expanded(child: _buildArtistsList()),
              ],
            ),
    );
  }

  Widget _buildLessonInfoHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFF3b82f6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lesson.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(widget.lesson.date),
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
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.schedule,
                '${widget.lesson.durationMinutes} דקות',
                const Color(0xFF8b5cf6),
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.people,
                '${_registeredArtists.length} אמנים',
                const Color(0xFF10b981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    final presentCount = _attendanceRecords.values
        .where((r) => r.isPresent)
        .length;
    final absentCount = _attendanceRecords.values
        .where((r) => r.isAbsent)
        .length;
    final pendingCount = _attendanceRecords.values
        .where((r) => r.isPending)
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'נוכחים',
              presentCount.toString(),
              const Color(0xFF10b981),
              Icons.check_circle,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'נעדרים',
              absentCount.toString(),
              const Color(0xFFef4444),
              Icons.cancel,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'ממתינים',
              pendingCount.toString(),
              const Color(0xFFf59e0b),
              Icons.schedule,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
        ),
      ],
    );
  }

  Widget _buildArtistsList() {
    if (_registeredArtists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'אין אמנים רשומים לשיעור זה',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _registeredArtists.length,
      itemBuilder: (context, index) {
        final artist = _registeredArtists[index];
        final record = _attendanceRecords[artist.id];

        return _buildArtistCard(artist, record);
      },
    );
  }

  Widget _buildArtistCard(User artist, AttendanceRecord? record) {
    final status = record?.status ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Artist avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getStatusColor(status),
                  child: Text(
                    artist.name.isNotEmpty ? artist.name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Artist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'נוכח',
                    Icons.check_circle,
                    const Color(0xFF10b981),
                    status == 'present',
                    () => _updateAttendance(artist.id, 'present'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'נעדר',
                    Icons.cancel,
                    const Color(0xFFef4444),
                    status == 'absent',
                    () => _updateAttendance(artist.id, 'absent'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'מאחר',
                    Icons.schedule,
                    const Color(0xFFf59e0b),
                    status == 'late',
                    () => _updateAttendance(artist.id, 'late'),
                  ),
                ),
              ],
            ),

            // Notes section
            if (record?.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFf8fafc),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'הערה: ${record!.notes}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.white,
        foregroundColor: isSelected ? Colors.white : color,
        elevation: 0,
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF10b981);
      case 'absent':
        return const Color(0xFFef4444);
      case 'late':
        return const Color(0xFFf59e0b);
      case 'excused':
        return const Color(0xFF8b5cf6);
      default:
        return const Color(0xFF6b7280);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'נוכח';
      case 'absent':
        return 'נעדר';
      case 'late':
        return 'מאחר';
      case 'excused':
        return 'מוצדק';
      default:
        return 'ממתין';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'ינואר',
      'פברואר',
      'מרץ',
      'אפריל',
      'מאי',
      'יוני',
      'יולי',
      'אוגוסט',
      'ספטמבר',
      'אוקטובר',
      'נובמבר',
      'דצמבר',
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} בשעה ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
