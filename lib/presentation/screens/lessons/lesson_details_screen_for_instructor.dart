import "package:flutter/material.dart";
import "package:knafayim_app/presentation/screens/lessons/mentor_lesson_attendance_screen.dart";
import "../../../data/models/lesson.dart";
import "../../../data/models/user.dart";
import "../../../data/models/attendance_record.dart";
import "../../../data/repositories/lesson_repository.dart";
import "../../../data/repositories/user_repository.dart";
import "../../../config/service_locator.dart";
import "package:intl/intl.dart"; // For date formatting

class LessonDetailsScreenForInstructor extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailsScreenForInstructor({Key? key, required this.lesson})
    : super(key: key);

  @override
  _LessonDetailsScreenForInstructorState createState() =>
      _LessonDetailsScreenForInstructorState();
}

class _LessonDetailsScreenForInstructorState
    extends State<LessonDetailsScreenForInstructor> {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  late List<AttendanceRecord> _currentAttendanceRecords;
  Map<String, User> _registeredArtistsDetails =
      {}; // Store fetched artist details
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLessonCompleted = false;

  @override
  void initState() {
    super.initState();
    _isLessonCompleted = widget.lesson.status == "completed";
    // Initialize with a deep copy to allow local modifications before saving
    _currentAttendanceRecords = widget.lesson.attendanceRecords
        .map((ar) => AttendanceRecord.fromMap(ar.toMap()))
        .toList();
    _fetchRegisteredArtistDetails();
  }

  Future<void> _fetchRegisteredArtistDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch the latest lesson details to ensure status is up-to-date
      final freshLesson = await _lessonRepository.getLessonById(
        widget.lesson.id,
      );
      if (freshLesson != null) {
        if (mounted) {
          setState(() {
            widget.lesson.status =
                freshLesson.status; // Update the local lesson's status
            _isLessonCompleted = freshLesson.status == "completed";
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("שגיאה: השיעור לא נמצא.")),
          );
          Navigator.of(context).pop();
          return;
        }
      }

      Map<String, User> details = {};
      for (String artistId in widget.lesson.registeredArtistIds) {
        // Ensure attendance record exists for every registered artist
        if (!_currentAttendanceRecords.any((ar) => ar.artistId == artistId)) {
          _currentAttendanceRecords.add(
            AttendanceRecord(
              id: UniqueKey().toString(), // or use a proper unique id generator
              lessonId: widget.lesson.id,
              artistId: artistId,
              status: "pending",
              date: widget.lesson.date,
            ),
          );
        }
        final user = await _userRepository.getUserById(
          artistId,
        ); // Assuming this method exists
        if (user != null) {
          details[artistId] = user;
        }
      }
      if (mounted) {
        setState(() {
          _registeredArtistsDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("שגיאה בטעינת פרטי הנרשמים: $e")),
        );
      }
    }
  }

  void _updateAttendanceStatus(String artistId, String newStatus) {
    // if (_isLessonCompleted) return; // Allow updating status for now
    setState(() {
      final recordIndex = _currentAttendanceRecords.indexWhere(
        (ar) => ar.artistId == artistId,
      );
      if (recordIndex != -1) {
        _currentAttendanceRecords[recordIndex].status = newStatus;
      } else {
        _currentAttendanceRecords.add(
          AttendanceRecord(
            id: UniqueKey().toString(), // or use a proper unique id generator
            lessonId: widget.lesson.id,
            artistId: artistId,
            status: newStatus,
            date: widget.lesson.date,
          ),
        );
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (!mounted || _isLessonCompleted) return;
    setState(() {
      _isSaving = true;
    });
    try {
      bool success = await _lessonRepository.updateLessonAttendance(
        widget.lesson.id,
        _currentAttendanceRecords,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("הנוכחות עודכנה בהצלחה!")),
          );
          Navigator.of(
            context,
          ).pop(true); // Indicate success to refresh previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("שגיאה בעדכון הנוכחות.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("שגיאה בשמירת הנוכחות: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("פרטי שיעור: ${widget.lesson.title}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isSaving
                ? null
                : _fetchRegisteredArtistDetails,
            tooltip: "רענן רשימת נרשמים",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "תאריך: ${DateFormat("dd/MM/yyyy").format(widget.lesson.date)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        "שעה: ${DateFormat.Hm("he_IL").format(widget.lesson.date)} (משך: ${widget.lesson.durationMinutes} דקות)",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_isLessonCompleted)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "שיעור זה הושלם. לא ניתן לעדכן נוכחות.",
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        "נרשמים (${widget.lesson.registeredArtistIds.length}):",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: widget.lesson.registeredArtistIds.isEmpty
                      ? const Center(child: Text("אין אמנים רשומים לשיעור זה."))
                      : ListView.builder(
                          itemCount: widget.lesson.registeredArtistIds.length,
                          itemBuilder: (context, index) {
                            final artistId =
                                widget.lesson.registeredArtistIds[index];
                            final artist = _registeredArtistsDetails[artistId];
                            final attendanceRecord = _currentAttendanceRecords
                                .firstWhere(
                                  (ar) => ar.artistId == artistId,
                                  orElse: () => AttendanceRecord(
                                    id: UniqueKey()
                                        .toString(), // or use a proper unique id generator
                                    lessonId: widget.lesson.id,
                                    artistId: artistId,
                                    status: "pending",
                                    date: widget.lesson.date,
                                  ),
                                );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        artist?.name ??
                                            "אמן לא ידוע (ID: $artistId)",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ChoiceChip(
                                          label: const Text("נוכח/ת"),
                                          selected:
                                              attendanceRecord.status ==
                                              "present",
                                          onSelected: _isLessonCompleted
                                              ? null
                                              : (selected) {
                                                  if (selected)
                                                    _updateAttendanceStatus(
                                                      artistId,
                                                      "present",
                                                    );
                                                },
                                          selectedColor: Colors.green[100],
                                          checkmarkColor: Colors.green,
                                          disabledColor: Colors.grey[300],
                                        ),
                                        const SizedBox(width: 8),
                                        ChoiceChip(
                                          label: const Text("נעדר/ת"),
                                          selected:
                                              attendanceRecord.status ==
                                              "absent",
                                          onSelected: _isLessonCompleted
                                              ? null
                                              : (selected) {
                                                  if (selected)
                                                    _updateAttendanceStatus(
                                                      artistId,
                                                      "absent",
                                                    );
                                                },
                                          selectedColor: Colors.red[100],
                                          checkmarkColor: Colors.red,
                                          disabledColor: Colors.grey[300],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // SINGLE ATTENDANCE BUTTONS SECTION (Removed Duplicates)
                if (!_isLoading && widget.lesson.registeredArtistIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Enhanced Attendance Button (always available)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EnhancedMentorAttendanceScreen(
                                      lesson: widget.lesson,
                                    ),
                              ),
                            );

                            // Refresh the lesson data if attendance was updated
                            if (result == true) {
                              _fetchRegisteredArtistDetails();
                            }
                          },
                          icon: const Icon(Icons.how_to_reg),
                          label: const Text('נוכחות מתקדמת'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3b82f6),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),

                        // Quick Save Button (only if lesson not completed)
                        if (!_isLessonCompleted) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveAttendance,
                            icon: const Icon(Icons.save),
                            label: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('שמור נוכחות מהיר'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10b981),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],

                        // View Only Message (if lesson completed)
                        if (_isLessonCompleted)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'שיעור זה הושלם. ניתן לצפות בנוכחות אך לא לערוך.',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
