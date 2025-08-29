import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/working_hours.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';
import '../../providers/working_hours_providers.dart';

class LogHoursScreen extends ConsumerStatefulWidget {
  final User user;
  final Lesson? preSelectedLesson;

  const LogHoursScreen({Key? key, required this.user, this.preSelectedLesson})
    : super(key: key);

  @override
  ConsumerState<LogHoursScreen> createState() => _LogHoursScreenState();
}

class _LogHoursScreenState extends ConsumerState<LogHoursScreen> {
  final _formKey = GlobalKey<FormState>();
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();

  // Form controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _numberOfStudentsController =
      TextEditingController();

  // Form data
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(
    hour: TimeOfDay.now().hour + 1,
  );
  String _selectedDiscipline = 'plastic_arts';
  Lesson? _selectedLesson;
  File? _photoEvidence;
  bool _isLoading = false;

  // Available disciplines
  final List<Map<String, String>> _disciplines = [
    {'key': 'plastic_arts', 'name': 'אמנות פלסטית'},
    {'key': 'theater', 'name': 'תאטרון'},
    {'key': 'creative_writing', 'name': 'כתיבה יוצרת'},
    {'key': 'music', 'name': 'מוזיקה'},
    {'key': 'animation', 'name': 'אנימציה'},
    {'key': 'video_cinema', 'name': 'וידאו קולנוע'},
  ];

  List<Lesson> _availableLessons = [];

  @override
  void initState() {
    super.initState();
    _selectedLesson = widget.preSelectedLesson;
    if (_selectedLesson != null) {
      _selectedDate = _selectedLesson!.date;
      _startTime = TimeOfDay.fromDateTime(_selectedLesson!.date);
      _endTime = TimeOfDay.fromDateTime(
        _selectedLesson!.date.add(
          Duration(minutes: _selectedLesson!.durationMinutes),
        ),
      );
      _numberOfStudentsController.text = _selectedLesson!
          .registeredArtistIds
          .length
          .toString();
    }
    _loadAvailableLessons();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _numberOfStudentsController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableLessons() async {
    try {
      final lessons = await _lessonRepository.getLessonsForMentor(
        widget.user.id,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );
      setState(() {
        _availableLessons = lessons;
      });
    } catch (e) {
      print('Error loading lessons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: Text(
          'רישום שעות עבודה',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1f2937),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveWorkingHours,
            child: _isLoading
                ? SizedBox(
                    width: isTablet ? 24 : 20,
                    height: isTablet ? 24 : 20,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'שמור',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8b5cf6),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              _buildLessonSection(),
              const SizedBox(height: 24),
              _buildDisciplineSection(),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildStudentsSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 24),
              _buildPhotoSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildDateTimeSection(),
        const SizedBox(height: 24),
        _buildLessonSection(),
        const SizedBox(height: 24),
        _buildDisciplineSection(),
        const SizedBox(height: 24),
        _buildStudentsSection(),
        const SizedBox(height: 24),
        _buildNotesSection(),
        const SizedBox(height: 24),
        _buildPhotoSection(),
        const SizedBox(height: 32),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return _buildSection(
      title: 'תאריך ושעות',
      icon: Icons.schedule,
      child: Column(
        children: [
          // Date picker
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFe2e8f0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF8b5cf6)),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time pickers
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  'שעת התחלה',
                  _startTime,
                  (time) => setState(() => _startTime = time),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePicker(
                  'שעת סיום',
                  _endTime,
                  (time) => setState(() => _endTime = time),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8b5cf6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Color(0xFF8b5cf6), size: 20),
                const SizedBox(width: 8),
                Text(
                  'משך: ${_calculateDuration()} שעות',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8b5cf6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonSection() {
    return _buildSection(
      title: 'שיעור (אופציונלי)',
      icon: Icons.school,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'קשר לשיעור ספציפי',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Lesson?>(
            value: _selectedLesson,
            decoration: InputDecoration(
              hintText: 'בחר שיעור (אופציונלי)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: [
              const DropdownMenuItem<Lesson?>(
                value: null,
                child: Text('ללא שיעור ספציפי'),
              ),
              ..._availableLessons.map((lesson) {
                return DropdownMenuItem<Lesson?>(
                  value: lesson,
                  child: Text(
                    '${lesson.title} - ${DateFormat('dd/MM HH:mm').format(lesson.date)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (lesson) {
              setState(() {
                _selectedLesson = lesson;
                if (lesson != null) {
                  _selectedDate = lesson.date;
                  _startTime = TimeOfDay.fromDateTime(lesson.date);
                  _endTime = TimeOfDay.fromDateTime(
                    lesson.date.add(Duration(minutes: lesson.durationMinutes)),
                  );
                  _numberOfStudentsController.text = lesson
                      .registeredArtistIds
                      .length
                      .toString();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineSection() {
    return _buildSection(
      title: 'תחום אמנות',
      icon: Icons.palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'בחר את תחום האמנות',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDiscipline,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _disciplines.map((discipline) {
              return DropdownMenuItem<String>(
                value: discipline['key'],
                child: Text(discipline['name']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDiscipline = value!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'אנא בחר תחום אמנות';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsSection() {
    return _buildSection(
      title: 'מספר תלמידים',
      icon: Icons.people,
      child: TextFormField(
        controller: _numberOfStudentsController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'הכנס מספר תלמידים',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'אנא הכנס מספר תלמידים';
          }
          final number = int.tryParse(value);
          if (number == null || number < 0) {
            return 'אנא הכנס מספר חוקי';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      title: 'הערות (אופציונלי)',
      icon: Icons.note,
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'הערות נוספות על השיעור...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return _buildSection(
      title: 'תמונת אישור (אופציונלי)',
      icon: Icons.camera_alt,
      child: Column(
        children: [
          if (_photoEvidence != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_photoEvidence!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    _photoEvidence != null ? 'שנה תמונה' : 'הוסף תמונה',
                  ),
                ),
              ),
              if (_photoEvidence != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => setState(() => _photoEvidence = null),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveWorkingHours,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8b5cf6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'שמור שעות עבודה',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8b5cf6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF8b5cf6), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(time, onChanged),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFe2e8f0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF8b5cf6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime(
    TimeOfDay currentTime,
    Function(TimeOfDay) onChanged,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    if (time != null) {
      onChanged(time);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _photoEvidence = File(pickedFile.path);
      });
    }
  }

  String _calculateDuration() {
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final duration = endDateTime.difference(startDateTime);
    final hours = duration.inMinutes / 60.0;
    return hours.toStringAsFixed(1);
  }

  int _calculateDurationMinutes() {
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    return endDateTime.difference(startDateTime).inMinutes;
  }

  Future<String?> _uploadPhoto() async {
    if (_photoEvidence == null) return null;

    try {
      final fileName =
          'working_hours_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('working_hours_photos')
          .child(fileName);

      await storageRef.putFile(_photoEvidence!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  Future<void> _saveWorkingHours() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate time
    final durationMinutes = _calculateDurationMinutes();
    if (durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שעת הסיום חייבת להיות אחרי שעת ההתחלה'),
          backgroundColor: Color(0xFFef4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload photo if exists
      final photoUrl = await _uploadPhoto();

      // Create working hours object
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final workingHours = WorkingHours(
        id: '', // Will be set by Firestore
        mentorId: widget.user.id,
        mentorName: widget.user.name,
        date: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        durationMinutes: durationMinutes,
        lessonId: _selectedLesson?.id,
        lessonTitle: _selectedLesson?.title,
        discipline: _selectedDiscipline,
        numberOfStudents: int.parse(_numberOfStudentsController.text),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        photoEvidenceUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      // Use Riverpod actions instead of direct repository call
      final actions = ref.read(workingHoursActionsProvider);
      await actions.addWorkingHours(workingHours);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('שעות העבודה נשמרו בהצלחה!'),
              ],
            ),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת שעות העבודה: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
