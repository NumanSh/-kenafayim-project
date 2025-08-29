import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/data/repositories/attendance_repository.dart';
import 'package:knafayim_app/presentation/widgets/attendance/absent_artist_contact_modal.dart';
import 'package:knafayim_app/services/attendance_reminder_service.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/user.dart';
import '../../../data/models/attendance_record.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../config/service_locator.dart';

class EnhancedMentorAttendanceScreen extends ConsumerStatefulWidget {
  final Lesson lesson;

  const EnhancedMentorAttendanceScreen({Key? key, required this.lesson})
    : super(key: key);

  @override
  ConsumerState<EnhancedMentorAttendanceScreen> createState() =>
      _EnhancedMentorAttendanceScreenState();
}

class _EnhancedMentorAttendanceScreenState
    extends ConsumerState<EnhancedMentorAttendanceScreen> {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, User> _artists = {};
  Map<String, AttendanceRecord> _attendanceRecords = {};
  String _filterStatus = 'all'; // all, present, absent, pending, late, excused

  @override
  void initState() {
    super.initState();
    _loadArtistData();
    _initializeAttendanceRecords();
  }

  void _initializeAttendanceRecords() {
    // Keep your existing logic but enhance it
    for (var record in widget.lesson.attendanceRecords) {
      _attendanceRecords[record.artistId] = record;
    }

    for (var artistId in widget.lesson.registeredArtistIds) {
      if (!_attendanceRecords.containsKey(artistId)) {
        _attendanceRecords[artistId] = AttendanceRecord(
          id: '${widget.lesson.id}_$artistId',
          artistId: artistId,
          lessonId: widget.lesson.id,
          date: widget.lesson.date,
          status: "pending",
        );
      }
    }
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
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final presentCount = _attendanceRecords.values
        .where((r) => r.status == 'present')
        .length;
    final totalCount = _attendanceRecords.length;

    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      title: Column(
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
      ],
    );
  }

  Widget _buildContent() {
    final filteredRecords = _getFilteredRecords();

    return Column(
      children: [
        // Lesson info card
        _buildLessonInfoCard(),

        // Quick stats
        _buildQuickStats(),

        // Bulk actions
        _buildBulkActions(),

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

  Widget _buildQuickStats() {
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

  Widget _buildBulkActions() {
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
      onTap: () {
        print(
          '🔥 BUTTON TAP: Status button tapped - $status for ${record.artistId}',
        );
        _updateAttendanceStatus(record.artistId, status);
      },
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

  Widget _buildBottomActions() {
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
          onPressed: _isSaving ? null : _saveAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3b82f6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'שמור נוכחות',
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
          const SizedBox(height: 8),
          const Text(
            'נסה לשנות את המסנן או לבדוק שיש תלמידים רשומים',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Keep your existing helper methods but enhance them
  List<AttendanceRecord> _getFilteredRecords() {
    final records = _attendanceRecords.values.toList();
    if (_filterStatus == 'all') return records;
    return records.where((record) => record.status == _filterStatus).toList();
  }

  Map<String, int> _calculateStats() {
    final records = _attendanceRecords.values;
    return {
      'present': records.where((r) => r.status == 'present').length,
      'absent': records.where((r) => r.status == 'absent').length,
      'late': records.where((r) => r.status == 'late').length,
      'excused': records.where((r) => r.status == 'excused').length,
      'pending': records.where((r) => r.status == 'pending').length,
    };
  }

  void _bulkUpdateAttendance(String status) {
    setState(() {
      for (var artistId in _attendanceRecords.keys) {
        _updateAttendanceStatus(artistId, status);
      }
    });
  }

  // ✅ ENHANCED: This is the main method that handles attendance updates
  // ✅ ENHANCED: Use AttendanceRepository directly with callback
  Future<void> _updateAttendanceStatus(String artistId, String status) async {
    print(
      '🔍 DEBUG: _updateAttendanceStatus called with artistId: $artistId, status: $status',
    );

    try {
      // Update attendance using repository with callback
      final success = await _attendanceRepository.updateLessonAttendance(
        lessonId: widget.lesson.id,
        artistId: artistId,
        status: status,
        onAbsentCallback: (String callbackArtistId, String callbackStatus) {
          print('🚨 CALLBACK: Received absent callback for $callbackArtistId');

          // Find artist and attendance record
          final artist = _artists[callbackArtistId];
          final attendanceRecord = _attendanceRecords[callbackArtistId];

          if (artist != null && attendanceRecord != null) {
            print('✅ CALLBACK: Showing contact modal for ${artist.name}');
            // Add delay to ensure UI is updated
            Future.delayed(const Duration(milliseconds: 200), () {
              _showAbsentArtistContactModal(artist, attendanceRecord);
            });
          } else {
            print(
              '❌ CALLBACK: Missing data - Artist: ${artist == null ? 'NULL' : 'OK'}, Record: ${attendanceRecord == null ? 'NULL' : 'OK'}',
            );
          }
        },
      );

      if (success) {
        print('✅ DEBUG: Attendance updated successfully in repository');

        // Update local state
        setState(() {
          if (_attendanceRecords.containsKey(artistId)) {
            _attendanceRecords[artistId] = _attendanceRecords[artistId]!
                .copyWith(status: status, updatedAt: DateTime.now());
            print('✅ DEBUG: Local state updated for $artistId');
          }
        });
      } else {
        print('❌ DEBUG: Failed to update attendance in repository');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update attendance')),
        );
      }
    } catch (e) {
      print('❌ DEBUG: Error in _updateAttendanceStatus: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating attendance: $e')));
    }
  }

  // ✅ ENHANCED: Contact modal with proper error handling
  void _showAbsentArtistContactModal(
    User artist,
    AttendanceRecord attendanceRecord,
  ) {
    print('🎭 DEBUG: _showAbsentArtistContactModal called for ${artist.name}');
    print('📞 DEBUG: Artist phone: ${artist.phoneNumber}');
    print('🚨 DEBUG: Emergency contact: ${artist.emergencyContact ?? 'None'}');

    if (!mounted) {
      print('❌ DEBUG: Widget not mounted, cannot show modal');
      return;
    }

    try {
      // Simple test dialog with enhanced functionality
      showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.person_off, color: Colors.red),
                  SizedBox(width: 8),
                  Text('אמן נעדר'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'שם: ${artist.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (artist.phoneNumber.isNotEmpty) ...[
                      Text('טלפון: ${artist.phoneNumber}'),
                      SizedBox(height: 4),
                    ],
                    if (artist.emergencyContact?.isNotEmpty == true) ...[
                      Text('איש קשר לחירום: ${artist.emergencyContact}'),
                      SizedBox(height: 4),
                    ],
                    if (artist.emergencyContactPhone?.isNotEmpty == true) ...[
                      Text('טלפון חירום: ${artist.emergencyContactPhone}'),
                      SizedBox(height: 4),
                    ],
                    if (artist.emergencyContactRelation?.isNotEmpty ==
                        true) ...[
                      Text('קרבה: ${artist.emergencyContactRelation}'),
                      SizedBox(height: 8),
                    ],
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('שיעור: ${widget.lesson.title}'),
                          Text(
                            'תאריך: ${widget.lesson.date.day}/${widget.lesson.date.month}/${widget.lesson.date.year}',
                          ),
                          Text(
                            'שעה: ${widget.lesson.date.hour}:${widget.lesson.date.minute.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    print('🔄 DEBUG: Close button pressed');
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('סגור'),
                ),
                ElevatedButton(
                  onPressed: () {
                    print('⏰ DEBUG: Remind Later button pressed');
                    Navigator.of(dialogContext).pop();

                    // Schedule reminder
                    try {
                      AttendanceReminderService().scheduleReminder(
                        attendanceRecord: attendanceRecord,
                        lesson: widget.lesson,
                        artist: artist,
                        context: context,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'תזכורת נקבעה ל-10 דקות לאחר סיום השיעור עבור ${artist.name}',
                            ),
                            backgroundColor: Color(0xFF10b981),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      print('❌ DEBUG: Error scheduling reminder: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('שגיאה בקביעת תזכורת'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3b82f6),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('תזכר לי מאוחר יותר'),
                ),
              ],
            ),
          )
          .then((value) {
            print('🎭 DEBUG: Modal closed');
          })
          .catchError((error) {
            print('❌ DEBUG: Modal error: $error');
          });
    } catch (e) {
      print('❌ DEBUG: Error showing modal: $e');
    }
  }

  Future<void> _saveAttendance() async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      List<AttendanceRecord> updatedRecords = _attendanceRecords.values
          .toList();

      Lesson updatedLesson = widget.lesson.copyWith(
        attendanceRecords: updatedRecords,
      );

      await _lessonRepository.updateLessonDetails(updatedLesson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('נוכחות נשמרה בהצלחה'),
              ],
            ),
            backgroundColor: Color(0xFF10b981),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת נוכחות: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
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
}
