import "package:flutter/material.dart";
import "../../../data/models/lesson.dart";
import "../../../data/models/user.dart"; // Assuming User model is available for current user context
import "../../../data/repositories/lesson_repository.dart";
import "../../../config/service_locator.dart";
import "../../../services/auth_service.dart"; // To get current user
import "package:intl/intl.dart"; // For date formatting

class LessonDetailsScreenForClient extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailsScreenForClient({Key? key, required this.lesson}) : super(key: key);

  @override
  _LessonDetailsScreenForClientState createState() => _LessonDetailsScreenForClientState();
}

class _LessonDetailsScreenForClientState extends State<LessonDetailsScreenForClient> {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  final AuthService _authService = serviceLocator<AuthService>();
  User? _currentUser;
  bool _isRegistered = false;
  bool _isLoading = true;
  bool _isProcessingRegistration = false;
  late Lesson _currentLessonState; // To hold the mutable state of the lesson being viewed

  @override
  void initState() {
    super.initState();
    _currentLessonState = widget.lesson; // Initialize with the passed lesson
    _loadCurrentUserAndRegistrationStatus();
  }

  Future<void> _loadCurrentUserAndRegistrationStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      _currentUser = _authService.currentUser; // Corrected to use getter
      if (_currentUser != null) {
        // Fetch the latest lesson details to ensure registration status and capacity are up-to-date
        final freshLesson = await _lessonRepository.getLessonById(widget.lesson.id);
        if (freshLesson != null) {
          _currentLessonState = freshLesson;
          _isRegistered = _currentLessonState.registeredArtistIds.contains(_currentUser!.id);
        } else {
          // Lesson not found, maybe show an error or pop
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("שגיאה: השיעור לא נמצא.")),
            );
            Navigator.of(context).pop();
            return;
          }
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("שגיאה בטעינת פרטי משתמש: $e")),
        );
      }
    }
  }

  Future<void> _toggleRegistration() async {
    if (_currentUser == null || _isProcessingRegistration) return;

    setState(() {
      _isProcessingRegistration = true;
    });

    bool success = false;
    try {
      if (_isRegistered) {
        success = await _lessonRepository.unregisterArtistFromLesson(_currentLessonState.id, _currentUser!.id);
      } else {
        if (_currentLessonState.maxCapacity != null && _currentLessonState.registeredArtistIds.length >= _currentLessonState.maxCapacity!) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("השיעור מלא, לא ניתן להירשם.")),
            );
            setState(() { _isProcessingRegistration = false; });
            return;
          }
        }
        success = await _lessonRepository.registerArtistForLesson(_currentLessonState.id, _currentUser!.id);
      }

      if (mounted) {
        if (success) {
          // Refresh lesson details and registration status
          final updatedLesson = await _lessonRepository.getLessonById(_currentLessonState.id);
          if (updatedLesson != null) {
            setState(() {
              _currentLessonState = updatedLesson;
              _isRegistered = _currentLessonState.registeredArtistIds.contains(_currentUser!.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isRegistered ? "נרשמת בהצלחה!" : "הרישום בוטל.")),
              );
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("פעולה נכשלה. נסה שוב.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("שגיאה בעיבוד הרישום: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingRegistration = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentLessonState.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _currentLessonState.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.calendar_today, "תאריך", DateFormat("dd/MM/yyyy", "he_IL").format(_currentLessonState.date)),
                  _buildInfoRow(Icons.access_time, "שעה", DateFormat.Hm("he_IL").format(_currentLessonState.date)),
                  _buildInfoRow(Icons.timelapse, "משך", "${_currentLessonState.durationMinutes} דקות"),
                  _buildInfoRow(Icons.person_outline, "מנחה", _currentLessonState.instructorName ?? _currentLessonState.instructorEmail ?? "טרם נקבע"),
                  const SizedBox(height: 8),
                  Text(
                    "נרשמו: ${_currentLessonState.registeredArtistIds.length}${_currentLessonState.maxCapacity != null ? " / ${_currentLessonState.maxCapacity}" : ""}",
                    style: theme.textTheme.titleMedium,
                  ),
                  if (_currentLessonState.maxCapacity != null && _currentLessonState.registeredArtistIds.length >= _currentLessonState.maxCapacity! && !_isRegistered)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "השיעור מלא",
                        style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_currentUser != null)
                    ElevatedButton(
                      onPressed: (_isProcessingRegistration || (_currentLessonState.maxCapacity != null && _currentLessonState.registeredArtistIds.length >= _currentLessonState.maxCapacity! && !_isRegistered))
                          ? null
                          : _toggleRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRegistered ? Colors.red[400] : theme.primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isProcessingRegistration
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isRegistered ? "בטל רישום" : "הירשם לשיעור",
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  const SizedBox(height: 16),
                  // Placeholder for more lesson description or details if available
                  // Text("תיאור השיעור...", style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text("$label: ", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.titleSmall)),
        ],
      ),
    );
  }
}

