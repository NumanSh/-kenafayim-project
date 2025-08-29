import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date/time formatting
import 'package:knafayim_app/presentation/screens/lessons/create_recurring_lesson_screen.dart';
import 'package:knafayim_app/services/image_service.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';
import '../../../data/repositories/user_repository.dart'; // For mentor email resolution
import '../../../data/models/user.dart'; // For User model

class AddLessonScreen extends StatefulWidget {
  final User user;
  const AddLessonScreen({Key? key, required this.user}) : super(key: key);

  @override
  _AddLessonScreenState createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  late TextEditingController _titleController;
  late TextEditingController _instructorNameController;
  late TextEditingController _instructorEmailController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _durationController;
  late TextEditingController _maxCapacityController;

  String? _selectedImageUrl;
  bool _isUploadingImage = false;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isRecurring = false;
  int _recurringWeeks = 4; // Default number of weeks for recurring lessons

  // Added for day of week selection
  int? _selectedDayOfWeek;
  final List<String> _daysOfWeek = [
    'ראשון',
    'שני',
    'שלישי',
    'רביעי',
    'חמישי',
    'שישי',
    'שבת',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _instructorNameController = TextEditingController();
    _instructorEmailController = TextEditingController();
    _dateController = TextEditingController();
    _timeController = TextEditingController();
    _durationController = TextEditingController(text: "60"); // Default duration
    _maxCapacityController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructorNameController.dispose();
    _instructorEmailController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _maxCapacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: "בחר תאריך לשיעור",
      confirmText: "אישור",
      cancelText: "ביטול",
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat("dd/MM/yyyy").format(picked);

        // Update selected day of week when date changes
        if (_isRecurring) {
          _selectedDayOfWeek =
              picked.weekday % 7; // 0 = Sunday, 1 = Monday, etc.
        }
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: "בחר שעת התחלה",
      confirmText: "אישור",
      cancelText: "ביטול",
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("אנא בחר תאריך ושעה לשיעור.")),
        );
        return;
      }

      // For recurring lessons, validate day of week selection
      if (_isRecurring && _selectedDayOfWeek == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("אנא בחר יום קבוע לשיעור השבועי.")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final DateTime lessonDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final int duration = int.tryParse(_durationController.text) ?? 60;
      final int? maxCapacity = int.tryParse(_maxCapacityController.text);

      try {
        if (_isRecurring) {
          // Create recurring weekly lessons with selected day of week
          List<Lesson?> createdLessons = [];

          // Get the first occurrence of the selected day of week
          DateTime firstLessonDate = lessonDateTime;

          // If user selected a different day than the initially picked date,
          // calculate the first occurrence of that day
          if (_selectedDayOfWeek != lessonDateTime.weekday % 7) {
            // Calculate days to add to reach the selected day of week
            int daysToAdd =
                (_selectedDayOfWeek! - (lessonDateTime.weekday % 7) + 7) % 7;
            if (daysToAdd == 0) daysToAdd = 7; // If same day, go to next week

            firstLessonDate = lessonDateTime.add(Duration(days: daysToAdd));
          }

          // ✅ FIX: Add backgroundImagePath parameter to recurring lesson
          final lesson = await _lessonRepository.addLesson(
            title: _titleController.text,
            date: firstLessonDate,
            durationMinutes: duration,
            instructorName: _instructorNameController.text.isEmpty
                ? null
                : _instructorNameController.text,
            instructorEmail: _instructorEmailController.text.isEmpty
                ? null
                : _instructorEmailController.text,
            maxCapacity: maxCapacity,
            backgroundImagePath: _selectedImageUrl, // ✅ ADD THIS LINE
          );

          createdLessons.add(lesson);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "נוצר שיעור שבועי קבוע ביום ${_daysOfWeek[_selectedDayOfWeek!]} בהצלחה!",
                ),
              ),
            );
            Navigator.of(context).pop(true); // Indicate success
          }
        } else {
          // Create a single lesson
          await _lessonRepository.addLesson(
            title: _titleController.text,
            date: lessonDateTime,
            durationMinutes: duration,
            instructorName: _instructorNameController.text.isEmpty
                ? null
                : _instructorNameController.text,
            instructorEmail: _instructorEmailController.text.isEmpty
                ? null
                : _instructorEmailController.text,
            maxCapacity: maxCapacity,
            backgroundImagePath: _selectedImageUrl, // Add this line
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("השיעור נוסף בהצלחה!")),
            );
            Navigator.of(context).pop(true); // Indicate success
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("שגיאה בהוספת השיעור: $e")));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("הוספת שיעור חדש")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildRecurringLessonOption(),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "שם השיעור",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "אנא הזן שם לשיעור";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "תאריך השיעור",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _pickDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "אנא בחר תאריך";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: "שעת התחלה",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => _pickTime(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "אנא בחר שעת התחלה";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: "משך השיעור (בדקות)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "אנא הזן משך שיעור";
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return "אנא הזן מספר דקות תקין";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructorNameController,
                decoration: const InputDecoration(
                  labelText: "שם המנחה (אופציונלי)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructorEmailController,
                decoration: const InputDecoration(
                  labelText: "אימייל המנחה (לשיוך אוטומטי)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !value.contains("@")) {
                    return "אנא הזן כתובת אימייל תקינה או השאר ריק";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxCapacityController,
                decoration: const InputDecoration(
                  labelText: "קיבולת מקסימלית (אופציונלי)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return "אנא הזן מספר תקין או השאר ריק";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("שיעור שבועי קבוע"),
                subtitle: const Text("יצירת שיעור קבוע ביום מסוים בשבוע"),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                    if (value && _selectedDate != null) {
                      // Initialize day of week from selected date when enabling recurring
                      _selectedDayOfWeek = _selectedDate!.weekday % 7;
                    }
                  });
                },
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: "יום קבוע בשבוע",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedDayOfWeek,
                  items: List.generate(7, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(_daysOfWeek[index]),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedDayOfWeek = value;
                    });
                  },
                  validator: (value) {
                    if (_isRecurring && value == null) {
                      return "אנא בחר יום קבוע לשיעור השבועי";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  "יצירת שיעור שבועי קבוע ביום ${_selectedDayOfWeek != null ? _daysOfWeek[_selectedDayOfWeek!] : ''}",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 16),
              _buildImageSelector(),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isRecurring ? "הוסף שיעור שבועי קבוע" : "הוסף שיעור",
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() => _isUploadingImage = true);

    try {
      // Generate temporary lesson ID for upload
      final tempLessonId = DateTime.now().millisecondsSinceEpoch.toString();

      final String? imageUrl = await ImageService.pickAndSaveImage(
        lessonId: tempLessonId,
        uploadToCloud: true, // Upload to cloud for cross-device sync
      );

      if (imageUrl != null) {
        setState(() {
          _selectedImageUrl = imageUrl;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('תמונה נבחרה בהצלחה'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      } else {
        setState(() => _isUploadingImage = false);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בבחירת תמונה: $e'),
          backgroundColor: const Color(0xFFef4444),
        ),
      );
    }
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'תמונת רקע (אופציונלי)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _selectedImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _selectedImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.error));
                    },
                  ),
                )
              : _isUploadingImage
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('מעלה תמונה...'),
                    ],
                  ),
                )
              : InkWell(
                  onTap: _pickImage,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'הוסף תמונת רקע',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
        ),

        if (_selectedImageUrl != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.edit),
                  label: const Text('שנה תמונה'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedImageUrl = null),
                  icon: const Icon(Icons.delete),
                  label: const Text('הסר תמונה'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Add this method to your AddLessonScreen class
  Widget _buildRecurringLessonOption() {
    // Only show if basic fields are filled
    final bool canConvert =
        _titleController.text.isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: canConvert ? 4 : 1,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: canConvert
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8b5cf6), Color(0xFF7c3aed)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                  ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: canConvert ? _navigateToRecurringSeries : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          canConvert ? Icons.repeat : Icons.repeat_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'צור סדרת שיעורים',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              canConvert
                                  ? 'המשך עם הפרטים שמילאת ליצירת סדרה'
                                  : 'מלא תחילה את פרטי השיעור הבסיסיים',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    ],
                  ),
                  if (canConvert) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'כל הפרטים שמילאת יישמרו ויועברו לדף יצירת הסדרה',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRecurringSeries() async {
    // Validate basic fields before navigation
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("נא להזין שם לשיעור")));
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("נא לבחור תאריך ושעה")));
      return;
    }

    // Create lesson data object to pass
    final lessonData = {
      'title': _titleController.text,
      'date': _selectedDate!,
      'time': _selectedTime!,
      'duration': int.tryParse(_durationController.text) ?? 60,
      'instructorName': _instructorNameController.text,
      'instructorEmail': _instructorEmailController.text,
      'maxCapacity': int.tryParse(_maxCapacityController.text),
      'backgroundImagePath': _selectedImageUrl,
    };

    // Navigate to recurring screen with data
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CreateRecurringLessonScreen(
              user: widget.user,
              initialLessonData: lessonData,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    // Handle result if series was created
    if (result != null && result is List<Lesson>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('נוצרו ${result.length} שיעורים בסדרה בהצלחה!'),
          backgroundColor: const Color(0xFF10b981),
        ),
      );
      Navigator.of(context).pop(true); // Return to previous screen
    }
  }
}
