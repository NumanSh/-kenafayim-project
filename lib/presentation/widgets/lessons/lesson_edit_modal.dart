import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/config/service_locator.dart';
import 'package:knafayim_app/data/repositories/lesson_repository.dart';
import 'package:knafayim_app/presentation/providers/lesson_providers.dart';
import 'package:knafayim_app/presentation/widgets/common/lesson_image_picker.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/user.dart';
import '../../providers/lesson_edit_providers.dart';

class LessonEditModal extends ConsumerStatefulWidget {
  final Lesson lesson;

  const LessonEditModal({
    super.key,
    required this.lesson,
    required Future<Null> Function() onLessonCreated,
  });

  @override
  ConsumerState<LessonEditModal> createState() => _LessonEditModalState();
}

class _LessonEditModalState extends ConsumerState<LessonEditModal> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _instructorNameController;
  late final TextEditingController _instructorEmailController;
  late final TextEditingController _maxCapacityController;
  final TextEditingController _artistSearchController = TextEditingController();

  // Form state
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _durationMinutes;
  List<User> _filteredArtists = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with lesson data
    _titleController = TextEditingController(text: widget.lesson.title);
    _instructorNameController = TextEditingController(
      text: widget.lesson.instructorName ?? '',
    );
    _instructorEmailController = TextEditingController(
      text: widget.lesson.instructorEmail ?? '',
    );
    _maxCapacityController = TextEditingController(
      text: widget.lesson.maxCapacity?.toString() ?? '',
    );

    // Initialize date/time
    _selectedDate = widget.lesson.date;
    _selectedTime = TimeOfDay.fromDateTime(widget.lesson.date);
    _durationMinutes = widget.lesson.durationMinutes;

    // Initialize edit state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(lessonEditNotifierProvider.notifier)
          .initializeEdit(widget.lesson);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructorNameController.dispose();
    _instructorEmailController.dispose();
    _maxCapacityController.dispose();
    _artistSearchController.dispose();
    super.dispose();
  }

  void _filterArtists(String query) {
    final editState = ref.read(lessonEditNotifierProvider);
    setState(() {
      if (query.isEmpty) {
        _filteredArtists = editState.availableArtists;
      } else {
        _filteredArtists = editState.availableArtists
            .where(
              (artist) =>
                  artist.name.toLowerCase().contains(query.toLowerCase()) ||
                  artist.email.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _toggleArtistSelection(User artist) {
    final currentSelection = ref
        .read(lessonEditNotifierProvider)
        .selectedArtistIds;
    final newSelection = List<String>.from(currentSelection);

    if (newSelection.contains(artist.id)) {
      newSelection.remove(artist.id);
    } else {
      newSelection.add(artist.id);
    }

    ref
        .read(lessonEditNotifierProvider.notifier)
        .updateSelectedArtists(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(lessonEditNotifierProvider);

    // Update filtered artists when available artists change
    if (_filteredArtists.isEmpty && editState.availableArtists.isNotEmpty) {
      _filteredArtists = editState.availableArtists;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: editState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : editState.error != null
                ? _buildErrorState(editState.error!)
                : _buildEditForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3b82f6),
            const Color(0xFF3b82f6).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header content
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'עריכת שיעור',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ערוך את פרטי השיעור והמשתתפים',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFef4444)),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(lessonEditNotifierProvider.notifier)
                    .initializeEdit(widget.lesson);
              },
              child: const Text('נסה שוב'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('פרטי השיעור'),
            const SizedBox(height: 16),
            _buildLessonNameField(),
            const SizedBox(height: 20),

            _buildSectionTitle('תאריך ושעה'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDateField()),
                const SizedBox(width: 12),
                Expanded(child: _buildTimeField()),
              ],
            ),
            const SizedBox(height: 16),
            _buildDurationField(),
            const SizedBox(height: 20),

            _buildSectionTitle('פרטי מנחה'),
            const SizedBox(height: 16),
            _buildInstructorNameField(),
            const SizedBox(height: 16),
            _buildInstructorEmailField(),
            const SizedBox(height: 20),

            // ✅ ADD THIS: Image section
            _buildImageSection(),
            const SizedBox(height: 20),

            _buildSectionTitle('בחירת אמנים'),
            const SizedBox(height: 16),
            _buildArtistSelectionSection(),
            const SizedBox(height: 20),

            _buildSectionTitle('הגדרות נוספות'),
            const SizedBox(height: 16),
            _buildMaxCapacityField(),
            const SizedBox(height: 32),

            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1f2937),
      ),
    );
  }

  Widget _buildLessonNameField() {
    return Container(
      decoration: _buildFieldDecoration(),
      child: TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'שם השיעור',
          prefixIcon: Icon(Icons.school, color: Color(0xFF3b82f6)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'נא להזין שם לשיעור';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: _buildFieldDecoration(),
      child: InkWell(
        onTap: _selectDate,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'תאריך',
            prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF3b82f6)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
          child: Text(
            DateFormat('dd/MM/yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1f2937)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return Container(
      decoration: _buildFieldDecoration(),
      child: InkWell(
        onTap: _selectTime,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'שעה',
            prefixIcon: Icon(Icons.access_time, color: Color(0xFF8b5cf6)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
          child: Text(
            _selectedTime.format(context),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1f2937)),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationField() {
    return Container(
      decoration: _buildFieldDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.timer, color: Color(0xFF06b6d4)),
                SizedBox(width: 12),
                Text(
                  'משך (דקות)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 30,
                    max: 180,
                    divisions: 10,
                    activeColor: const Color(0xFF06b6d4),
                    label: '$_durationMinutes דקות',
                    onChanged: (value) {
                      setState(() {
                        _durationMinutes = value.round();
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06b6d4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_durationMinutes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF06b6d4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorNameField() {
    return Container(
      decoration: _buildFieldDecoration(),
      child: TextFormField(
        controller: _instructorNameController,
        decoration: const InputDecoration(
          labelText: 'שם מנחה',
          prefixIcon: Icon(Icons.person, color: Color(0xFFf59e0b)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildInstructorEmailField() {
    return Container(
      decoration: _buildFieldDecoration(),
      child: TextFormField(
        controller: _instructorEmailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'אימייל מנחה',
          prefixIcon: Icon(Icons.email, color: Color(0xFFef4444)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value != null && value.isNotEmpty && !value.contains('@')) {
            return 'נא להזין כתובת אימייל תקינה';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildArtistSelectionSection() {
    final editState = ref.watch(lessonEditNotifierProvider);
    final selectedArtists = editState.availableArtists
        .where((artist) => editState.selectedArtistIds.contains(artist.id))
        .toList();

    return Container(
      decoration: _buildFieldDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF8b5cf6)),
                const SizedBox(width: 12),
                const Text(
                  'אמנים משתתפים',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8b5cf6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${editState.selectedArtistIds.length} נבחרו',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8b5cf6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFf1f5f9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _artistSearchController,
                decoration: const InputDecoration(
                  hintText: 'חפש אמן...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF6b7280)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: _filterArtists,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Selected artists chips
          if (selectedArtists.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'אמנים נבחרים:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedArtists.map((artist) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8b5cf6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF8b5cf6).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: const Color(0xFF8b5cf6),
                              child: Text(
                                artist.name.isNotEmpty
                                    ? artist.name[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              artist.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8b5cf6),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _toggleArtistSelection(artist),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFF8b5cf6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Available artists list
          if (_filteredArtists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'לא נמצאו אמנים',
                  style: TextStyle(color: Color(0xFF6b7280)),
                ),
              ),
            )
          else
            Container(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredArtists.length,
                itemBuilder: (context, index) {
                  final artist = _filteredArtists[index];
                  final isSelected = editState.selectedArtistIds.contains(
                    artist.id,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _toggleArtistSelection(artist),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8b5cf6).withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8b5cf6)
                                : const Color(0xFFe2e8f0),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isSelected
                                  ? const Color(0xFF8b5cf6)
                                  : const Color(0xFFe2e8f0),
                              child: Text(
                                artist.name.isNotEmpty
                                    ? artist.name[0].toUpperCase()
                                    : 'A',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF6b7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artist.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF8b5cf6)
                                          : const Color(0xFF1f2937),
                                    ),
                                  ),
                                  Text(
                                    artist.email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6b7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF8b5cf6),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMaxCapacityField() {
    return Container(
      decoration: _buildFieldDecoration(),
      child: TextFormField(
        controller: _maxCapacityController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'קיבולת מקסימלית (אופציונלי)',
          prefixIcon: Icon(Icons.groups, color: Color(0xFF8b5cf6)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final capacity = int.tryParse(value);
            if (capacity == null || capacity <= 0) {
              return 'נא להזין מספר תקין';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    final editState = ref.watch(lessonEditNotifierProvider);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: editState.isLoading ? null : _saveLesson,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: editState.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'שמור שינויים',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              ref.read(lessonEditNotifierProvider.notifier).clear();
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6b7280),
              side: const BorderSide(color: Color(0xFFe2e8f0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'ביטול',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _buildFieldDecoration() {
    return BoxDecoration(
      color: const Color(0xFFf9fafb),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFe2e8f0)),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF3b82f6)),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF8b5cf6)),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    final lessonDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final maxCapacity = _maxCapacityController.text.trim().isEmpty
        ? null
        : int.tryParse(_maxCapacityController.text);

    final success = await ref
        .read(lessonEditNotifierProvider.notifier)
        .saveLesson(
          title: _titleController.text.trim(),
          date: lessonDateTime,
          durationMinutes: _durationMinutes,
          instructorName: _instructorNameController.text.trim().isEmpty
              ? null
              : _instructorNameController.text.trim(),
          instructorEmail: _instructorEmailController.text.trim().isEmpty
              ? null
              : _instructorEmailController.text.trim(),
          maxCapacity: maxCapacity,
        );

    if (success && mounted) {
      ref.read(lessonEditNotifierProvider.notifier).clear();
      Navigator.of(context).pop(true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('השיעור עודכן בהצלחה'),
          backgroundColor: Color(0xFF10b981),
        ),
      );
    } else if (mounted) {
      final error = ref.read(lessonEditNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'שגיאה בעדכון השיעור'),
          backgroundColor: const Color(0xFFef4444),
        ),
      );
    }
  }

  // Add this to your existing LessonEditModal
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('תמונת רקע'),
        const SizedBox(height: 16),
        LessonImagePicker(
          initialImagePath: widget.lesson.backgroundImagePath,
          lessonId: widget.lesson.id,
          onImageChanged: (imagePath) {
            // Update the lesson image immediately
            _updateLessonImage(imagePath);
          },
          showIcon: true,
        ),
      ],
    );
  }

  // ✅ ADD THIS: Method to handle image updates
  Future<void> _updateLessonImage(String? imagePath) async {
    try {
      final lessonRepository = serviceLocator<LessonRepository>();
      final updatedLesson = widget.lesson.copyWith(
        backgroundImagePath: imagePath,
      );

      await lessonRepository.updateLessonDetails(updatedLesson);

      // Update the provider
      ref.read(lessonNotifierProvider.notifier).updateLesson(updatedLesson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('תמונת הרקע עודכנה בהצלחה'),
              ],
            ),
            backgroundColor: Color(0xFF10b981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('שגיאה בעדכון התמונה: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFef4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
