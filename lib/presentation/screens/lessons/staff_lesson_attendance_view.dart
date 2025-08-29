import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/user.dart';
import '../../../data/models/attendance_record.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';

class StaffLessonAttendanceView extends ConsumerStatefulWidget {
  final Lesson lesson;

  const StaffLessonAttendanceView({Key? key, required this.lesson})
    : super(key: key);

  @override
  ConsumerState<StaffLessonAttendanceView> createState() =>
      _StaffLessonAttendanceViewState();
}

class _StaffLessonAttendanceViewState
    extends ConsumerState<StaffLessonAttendanceView> {
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  bool _isLoading = false;
  Map<String, User> _artists = {};
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    Map<String, User> artists = {};
    for (String artistId in widget.lesson.registeredArtistIds) {
      try {
        User? artist = await _userRepository.getUserById(artistId);
        if (artist != null) {
          artists[artistId] = artist;
        }
      } catch (e) {
        print("Error fetching artist $artistId: $e");
      }
    }

    if (mounted) {
      setState(() {
        _artists = artists;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final presentCount = widget.lesson.attendanceRecords
        .where((r) => r.status == 'present')
        .length;
    final totalCount = widget.lesson.registeredArtistIds.length;

    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'צפייה בנוכחות - ${widget.lesson.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          Text(
            '$presentCount/$totalCount נוכחים',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => setState(() => _filterStatus = value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'all', child: Text('הכל')),
            const PopupMenuItem(value: 'present', child: Text('נוכחים')),
            const PopupMenuItem(value: 'absent', child: Text('נעדרים')),
            const PopupMenuItem(value: 'pending', child: Text('ממתינים')),
            const PopupMenuItem(value: 'late', child: Text('מאחרים')),
            const PopupMenuItem(value: 'excused', child: Text('מוצדקים')),
          ],
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.filter_list, color: Color(0xFF6b7280)),
          ),
        ),
        IconButton(
          onPressed: _exportAttendance,
          icon: const Icon(Icons.download, color: Color(0xFF6b7280)),
          tooltip: 'ייצא נוכחות',
        ),
      ],
    );
  }

  Widget _buildContent() {
    final filteredRecords = _getFilteredAttendanceRecords();

    return Column(
      children: [
        // Lesson info card
        _buildLessonInfoCard(),

        // Attendance statistics
        _buildAttendanceStats(),

        // Students list
        Expanded(
          child: filteredRecords.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    final artist = _artists[record.artistId];
                    return _buildStudentCard(record, artist);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLessonInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8b5cf6), Color(0xFF7c3aed)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'מנחה: ${widget.lesson.instructorName ?? "לא צוין"}',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(widget.lesson.date),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                '${widget.lesson.durationMinutes} דקות',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final stats = _calculateStats();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              'נוכחים',
              stats['present']!,
              const Color(0xFF10b981),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatChip(
              'נעדרים',
              stats['absent']!,
              const Color(0xFFef4444),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatChip(
              'מאחרים',
              stats['late']!,
              const Color(0xFFf59e0b),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatChip(
              'מוצדקים',
              stats['excused']!,
              const Color(0xFF8b5cf6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildStudentCard(AttendanceRecord record, User? artist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getStatusColor(record.status).withOpacity(0.1),
              child: Text(
                artist?.name.isNotEmpty == true
                    ? artist!.name[0].toUpperCase()
                    : 'A',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(record.status),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist?.name ?? 'אמן לא ידוע',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  if (record.notes != null && record.notes!.isNotEmpty)
                    Text(
                      record.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6b7280),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(record.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(record.status),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(record.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('טוען נתוני נוכחות...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: const Color(0xFF6b7280).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'אין נתוני נוכחות להצגה',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'נסה לשנות את המסנן או לבדוק שהנוכחות נרשמה',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<AttendanceRecord> _getFilteredAttendanceRecords() {
    List<AttendanceRecord> allRecords = [];

    // Create attendance records for all registered artists
    for (String artistId in widget.lesson.registeredArtistIds) {
      final existingRecord = widget.lesson.attendanceRecords
          .where((r) => r.artistId == artistId)
          .firstOrNull;

      if (existingRecord != null) {
        allRecords.add(existingRecord);
      } else {
        // Create pending record for artists without attendance data
        allRecords.add(
          AttendanceRecord(
            id: '${widget.lesson.id}_$artistId',
            artistId: artistId,
            lessonId: widget.lesson.id,
            date: widget.lesson.date,
            status: "pending",
          ),
        );
      }
    }

    if (_filterStatus == 'all') return allRecords;
    return allRecords
        .where((record) => record.status == _filterStatus)
        .toList();
  }

  Map<String, int> _calculateStats() {
    final allRecords = _getFilteredAttendanceRecords();
    return {
      'present': allRecords.where((r) => r.status == 'present').length,
      'absent': allRecords.where((r) => r.status == 'absent').length,
      'late': allRecords.where((r) => r.status == 'late').length,
      'excused': allRecords.where((r) => r.status == 'excused').length,
      'pending': allRecords.where((r) => r.status == 'pending').length,
    };
  }

  void _exportAttendance() {
    // TODO: Implement attendance export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ייצוא נוכחות יהיה זמין בקרוב'),
        backgroundColor: Color(0xFF3b82f6),
      ),
    );
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
      case 'pending':
      default:
        return 'ממתין';
    }
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
      case 'pending':
      default:
        return const Color(0xFF6b7280);
    }
  }
}
