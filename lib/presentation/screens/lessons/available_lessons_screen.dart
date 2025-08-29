import 'package:flutter/material.dart';
import '../../../data/models/user.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';
import '../../screens/lessons/lesson_details_screen_for_client.dart';

class AvailableLessonsScreen extends StatefulWidget {
  final User user;

  const AvailableLessonsScreen({Key? key, required this.user}) : super(key: key);

  @override
  _AvailableLessonsScreenState createState() => _AvailableLessonsScreenState();
}

class _AvailableLessonsScreenState extends State<AvailableLessonsScreen> {
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  List<Lesson> _availableLessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableLessons();
  }

  Future<void> _loadAvailableLessons() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final lessons = await _lessonRepository.getAvailableLessonsForArtist(widget.user.id);
      if (mounted) {
        setState(() {
          _availableLessons = lessons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת שיעורים זמינים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registerForLesson(Lesson lesson) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final success = await _lessonRepository.registerArtistForLesson(
        lesson.id,
        widget.user.id,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('נרשמת לשיעור בהצלחה!')),
          );
          _loadAvailableLessons(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('שגיאה בהרשמה לשיעור. ייתכן שהשיעור מלא או שכבר נרשמת אליו.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהרשמה לשיעור: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('שיעורים זמינים'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailableLessons,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _availableLessons.isEmpty
                ? const Center(child: Text('אין שיעורים זמינים כרגע'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _availableLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = _availableLessons[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.school,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text('מנחה: ${lesson.instructorName ?? 'טרם נקבע'}'),
                                  Text('תאריך: ${lesson.date.day}/${lesson.date.month}/${lesson.date.year}'),
                                  Text('שעה: ${lesson.date.hour}:${lesson.date.minute.toString().padLeft(2, '0')}'),
                                  Text('משך: ${lesson.durationMinutes} דקות'),
                                  if (lesson.maxCapacity != null)
                                    Text('מקומות פנויים: ${lesson.maxCapacity! - lesson.registeredArtistIds.length}/${lesson.maxCapacity}'),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LessonDetailsScreenForClient(lesson: lesson),
                                  ),
                                ).then((_) => _loadAvailableLessons());
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _registerForLesson(lesson),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('הירשם לשיעור'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
