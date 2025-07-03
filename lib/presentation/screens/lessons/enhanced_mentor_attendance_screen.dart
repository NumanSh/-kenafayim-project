import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/data/repositories/lesson_repository.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/user.dart';
import '../../../data/models/attendance_record.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';
import '../../providers/attendance_providers.dart';
import '../../widgets/attendance/absent_artist_contact_modal.dart';
import '../../../services/attendance_reminder_service.dart';

class EnhancedMentorAttendanceScreen extends ConsumerStatefulWidget {
  final Lesson lesson;

  const EnhancedMentorAttendanceScreen({super.key, required this.lesson});

  @override
  ConsumerState<EnhancedMentorAttendanceScreen> createState() =>
      _EnhancedMentorAttendanceScreenState();
}

class _EnhancedMentorAttendanceScreenState
    extends ConsumerState<EnhancedMentorAttendanceScreen> {
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
  @override
  Widget build(BuildContext context) {
    // 🔥 CRITICAL FIX: Watch the real-time attendance provider
    final attendanceAsync = ref.watch(
      lessonAttendanceProvider(widget.lesson.id),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: _buildAppBar(attendanceAsync),
      body: attendanceAsync.when(
        data: (attendanceRecords) => _isLoading
            ? _buildLoadingState()
            : _buildContent(attendanceRecords),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
      bottomNavigationBar: attendanceAsync.when(
        data: (attendanceRecords) => _buildBottomActions(attendanceRecords),
        loading: () => null,
        error: (error, stack) => null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AsyncValue<List<AttendanceRecord>> attendanceAsync,
  ) {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: attendanceAsync.when(
        data: (attendanceRecords) {
          // Create complete attendance records for all registered artists
          final allRecords = _createCompleteAttendanceRecords(
            attendanceRecords,
          );
          final presentCount = allRecords
              .where((r) => r.status == 'present')
              .length;
          final totalCount = widget.lesson.registeredArtistIds.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'נוכחות - ${widget.lesson.title}',
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
          );
        },
        loading: () => const Text('טוען...'),
        error: (error, stack) => const Text('שגיאה'),
      ),
      actions: [
        // Manual refresh button
        IconButton(
          onPressed: () {
            ref.invalidate(lessonAttendanceProvider(widget.lesson.id));
          },
          icon: const Icon(Icons.refresh, color: Color(0xFF6b7280)),
        ),
        // Debug button (temporary)
        IconButton(
          onPressed: () async {
            print('🔍 DEBUG: Testing immediate save...');
            final actions = ref.read(attendanceActionsProvider);
            final success = await actions.updateSingleAttendance(
              widget.lesson,
              'OkUNA8LCxyaFAxYpCRiea2BUKBp2', // Ken's ID
              'present',
            );
            print('🔍 DEBUG: Save result: $success');
          },
          icon: const Icon(Icons.bug_report, color: Colors.red),
        ),
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
      ],
    );
  }

  Widget _buildContent(List<AttendanceRecord> attendanceRecords) {
    final allRecords = _createCompleteAttendanceRecords(attendanceRecords);
    final filteredRecords = _getFilteredRecords(allRecords);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(lessonAttendanceProvider(widget.lesson.id));
      },
      child: Column(
        children: [
          _buildLessonInfoCard(),
          _buildQuickStats(allRecords),
          _buildBulkActions(allRecords),
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
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getStatusColor(
                    record.status,
                  ).withOpacity(0.1),
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
                      Text(
                        _getStatusText(record.status),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getStatusColor(record.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (record.notes != null && record.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            record.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6b7280),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(record.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(record.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(record.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Attendance action buttons
            Row(
              children: [
                Expanded(
                  child: _buildStatusButton(
                    'present',
                    'נוכח',
                    Icons.check_circle,
                    record,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusButton(
                    'late',
                    'מאחר',
                    Icons.schedule,
                    record,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusButton(
                    'absent',
                    'נעדר',
                    Icons.cancel,
                    record,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusButton(
                    'excused',
                    'מוצדק',
                    Icons.verified,
                    record,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String status,
    String label,
    IconData icon,
    AttendanceRecord record,
  ) {
    final isSelected = record.status == status;
    final color = _getStatusColor(status);

    return InkWell(
      onTap: () => _updateAttendanceStatus(record.artistId, status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFe5e7eb),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : const Color(0xFF6b7280),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color : const Color(0xFF6b7280),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 KEY FIX: Use your existing providers for immediate updates
  Future<void> _updateAttendanceStatus(String artistId, String status) async {
    print('🔍 DEBUG: Updating attendance for $artistId to $status');

    try {
      // If status is absent, show contact modal first
      if (status == 'absent') {
        final artist = _artists[artistId];

        if (artist != null) {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => AbsentArtistContactModal(
              artist: artist,
              attendanceRecord: AttendanceRecord(
                id: '${widget.lesson.id}_$artistId',
                artistId: artistId,
                lessonId: widget.lesson.id,
                date: widget.lesson.date,
                status: 'pending',
              ),
              lesson: widget.lesson,
            ),
          );

          String? notes;
          if (result != null && result['notes'] != null) {
            notes = result['notes'];
          }

          // Update with notes from modal
          await _performAttendanceUpdate(artistId, status, notes: notes);
        }
      } else {
        // Update without modal
        await _performAttendanceUpdate(artistId, status);
      }
    } catch (e) {
      print('❌ DEBUG: Error updating attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בעדכון נוכחות: $e')));
      }
    }
  }

  Future<void> _performAttendanceUpdate(
    String artistId,
    String status, {
    String? notes,
  }) async {
    try {
      print('💾 UPDATING: Starting attendance update for $artistId to $status');

      // Use your existing actions provider
      final actions = ref.read(attendanceActionsProvider);

      final success = await actions.updateSingleAttendance(
        widget.lesson,
        artistId,
        status,
        notes: notes,
      );

      if (success) {
        print('✅ UPDATING: Attendance saved successfully');

        // Force immediate refresh of the provider
        ref.invalidate(lessonAttendanceProvider(widget.lesson.id));

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('נוכחות עודכנה בהצלחה'),
              duration: Duration(seconds: 1),
              backgroundColor: Color(0xFF10b981),
            ),
          );
        }
      } else {
        print('❌ UPDATING: Attendance save failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('שגיאה בשמירת נוכחות'),
              backgroundColor: Color(0xFFef4444),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ UPDATING: Error in attendance update: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  // Add all your other existing methods here...
  Widget _buildLessonInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3b82f6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 24),
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
                  '${widget.lesson.date.day}/${widget.lesson.date.month}/${widget.lesson.date.year} • ${widget.lesson.date.hour}:${widget.lesson.date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<AttendanceRecord> attendanceRecords) {
    final stats = _calculateStats(attendanceRecords);

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
              'ממתינים',
              stats['pending']!,
              const Color(0xFF6b7280),
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

  Widget _buildBulkActions(List<AttendanceRecord> attendanceRecords) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _bulkUpdateAttendance('present'),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('סמן הכל נוכח'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10b981),
                side: const BorderSide(color: Color(0xFF10b981)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _bulkUpdateAttendance('absent'),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('סמן הכל נעדר'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFef4444),
                side: const BorderSide(color: Color(0xFFef4444)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(List<AttendanceRecord> attendanceRecords) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3b82f6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'סיום',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
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
          Text('טוען נתוני תלמידים...'),
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
            'אין תלמידים להצגה',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFef4444)),
          const SizedBox(height: 16),
          const Text('שגיאה בטעינת נוכחות'),
          const SizedBox(height: 8),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(lessonAttendanceProvider(widget.lesson.id)),
            child: const Text('נסה שוב'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<AttendanceRecord> _getFilteredRecords(
    List<AttendanceRecord> allRecords,
  ) {
    if (_filterStatus == 'all') return allRecords;
    return allRecords
        .where((record) => record.status == _filterStatus)
        .toList();
  }

  Map<String, int> _calculateStats(List<AttendanceRecord> attendanceRecords) {
    final allRecords = _getFilteredRecords(attendanceRecords);
    return {
      'present': allRecords.where((r) => r.status == 'present').length,
      'absent': allRecords.where((r) => r.status == 'absent').length,
      'late': allRecords.where((r) => r.status == 'late').length,
      'excused': allRecords.where((r) => r.status == 'excused').length,
      'pending': allRecords.where((r) => r.status == 'pending').length,
    };
  }

  Future<void> _bulkUpdateAttendance(String status) async {
    final actions = ref.read(attendanceActionsProvider);
    final artistIds = widget.lesson.registeredArtistIds;

    final success = await actions.bulkUpdateAttendance(
      widget.lesson,
      status,
      artistIds,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('כל התלמידים סומנו כ${_getStatusText(status)}'),
          backgroundColor: const Color(0xFF10b981),
        ),
      );
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

  // Add this debug method
  Future<void> _debugAttendanceFlow() async {
    print('🔍 DEBUG: Starting attendance flow debug...');

    try {
      // Test repository directly
      final lessonRepo = serviceLocator<LessonRepository>();
      final lesson = await lessonRepo.getLessonById(widget.lesson.id);
      print('🔍 DEBUG: Lesson from repo: ${lesson?.title}');
      print(
        '🔍 DEBUG: Attendance records in lesson: ${lesson?.attendanceRecords.length}',
      );

      // Test if lesson exists in Firestore
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore
          .collection('lessons')
          .doc(widget.lesson.id)
          .get();
      print('🔍 DEBUG: Lesson exists in Firestore: ${doc.exists}');
      if (doc.exists) {
        final data = doc.data();
        print(
          '🔍 DEBUG: Firestore attendance records: ${data?['attendanceRecords']?.length ?? 0}',
        );
      }
    } catch (e) {
      print('🔍 DEBUG: Error in debug flow: $e');
    }
  }

  // Add this helper method to your class
  List<AttendanceRecord> _createCompleteAttendanceRecords(
    List<AttendanceRecord> existingRecords,
  ) {
    List<AttendanceRecord> allRecords = [];

    // Create attendance records for all registered artists
    for (String artistId in widget.lesson.registeredArtistIds) {
      final existingRecord = existingRecords
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

    return allRecords;
  }
}
