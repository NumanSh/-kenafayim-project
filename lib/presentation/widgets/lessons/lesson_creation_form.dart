import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:knafayim_app/presentation/providers/lesson_providers.dart';
import 'package:knafayim_app/presentation/widgets/common/lesson_image_picker.dart';
import 'package:knafayim_app/services/image_service.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user.dart';

enum LessonCreationStep { basicInfo, advancedSettings, artistRegistration }

class LessonCreationForm extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onLessonCreated;
  final User user;

  const LessonCreationForm({
    super.key,
    required this.scrollController,
    required this.onLessonCreated,
    required this.user,
  });

  @override
  ConsumerState<LessonCreationForm> createState() => _LessonCreationFormState();
}

class _LessonCreationFormState extends ConsumerState<LessonCreationForm>
    with TickerProviderStateMixin {
  final _basicFormKey = GlobalKey<FormState>();
  final _advancedFormKey = GlobalKey<FormState>();
  final LessonRepository _lessonRepository = serviceLocator<LessonRepository>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  // Current step
  LessonCreationStep _currentStep = LessonCreationStep.basicInfo;

  // Day selection and lesson count properties
  List<bool> _selectedDays = [false, false, false, false, false, false, false];
  int _lessonCount = 12;

  // Controllers
  final _titleController = TextEditingController();
  final _instructorNameController = TextEditingController();
  final _instructorEmailController = TextEditingController();
  final _maxCapacityController = TextEditingController();
  final _artistSearchController = TextEditingController();
  String? _selectedImagePath;

  // Form state
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationMinutes = 60;
  bool _isLoading = false;

  // Artist selection state
  List<User> _availableArtists = [];
  List<User> _selectedArtists = [];
  List<User> _filteredArtists = [];
  bool _isLoadingArtists = false;

  // Recurring lesson state
  bool _isRecurring = false;
  bool _isCreating = false;

  // Animation controllers
  late AnimationController _toggleController;
  late Animation<double> _toggleAnimation;
  late AnimationController _stepController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadAvailableArtists();

    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toggleAnimation = CurvedAnimation(
      parent: _toggleController,
      curve: Curves.easeInOut,
    );

    _stepController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _stepController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructorNameController.dispose();
    _instructorEmailController.dispose();
    _maxCapacityController.dispose();
    _artistSearchController.dispose();
    _toggleController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableArtists() async {
    setState(() => _isLoadingArtists = true);

    try {
      final allUsers = await _userRepository.getAllUsers();
      final artists = allUsers
          .where((user) => user.role == UserRole.client)
          .toList();

      if (mounted) {
        setState(() {
          _availableArtists = artists;
          _filteredArtists = artists;
          _isLoadingArtists = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת אמנים: $e')));
      }
    }
  }

  void _filterArtists(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredArtists = _availableArtists;
      } else {
        _filteredArtists = _availableArtists
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
    setState(() {
      if (_selectedArtists.contains(artist)) {
        _selectedArtists.remove(artist);
      } else {
        _selectedArtists.add(artist);
      }
    });
  }

  bool _validateBasicInfo() {
    if (!_basicFormKey.currentState!.validate()) return false;
    
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('נא לבחור תאריך ושעה'),
          backgroundColor: Color(0xFFef4444),
        ),
      );
      return false;
    }
    
    return true;
  }

  void _nextStep() {
    if (_currentStep == LessonCreationStep.basicInfo) {
      if (_validateBasicInfo()) {
        setState(() {
          _currentStep = LessonCreationStep.advancedSettings;
        });
        _stepController.forward();
      }
    } else if (_currentStep == LessonCreationStep.advancedSettings) {
      if (_advancedFormKey.currentState!.validate()) {
        setState(() {
          _currentStep = LessonCreationStep.artistRegistration;
        });
        _stepController.forward();
      }
    }
  }

  void _previousStep() {
    if (_currentStep == LessonCreationStep.artistRegistration) {
      setState(() {
        _currentStep = LessonCreationStep.advancedSettings;
      });
      _stepController.reverse();
    } else if (_currentStep == LessonCreationStep.advancedSettings) {
      setState(() {
        _currentStep = LessonCreationStep.basicInfo;
      });
      _stepController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFe5e7eb),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header with step indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Text(
                'יצירת שיעור חדש',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 16),
              _buildStepIndicator(),
            ],
          ),
        ),

        // Form content
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentStep == LessonCreationStep.basicInfo
                  ? _buildBasicInfoStep()
                  : _currentStep == LessonCreationStep.advancedSettings
                      ? _buildAdvancedSettingsStep()
                      : _buildArtistRegistrationStep(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Row(
        children: [
          _buildStepItem(
            stepNumber: 1,
            title: 'פרטי בסיס',
            isActive: _currentStep == LessonCreationStep.basicInfo,
            isCompleted: _currentStep == LessonCreationStep.advancedSettings || _currentStep == LessonCreationStep.artistRegistration,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _currentStep == LessonCreationStep.advancedSettings || _currentStep == LessonCreationStep.artistRegistration
                    ? const Color(0xFF10b981)
                    : const Color(0xFFe2e8f0),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _buildStepItem(
            stepNumber: 2,
            title: 'הגדרות מתקדמות',
            isActive: _currentStep == LessonCreationStep.advancedSettings,
            isCompleted: _currentStep == LessonCreationStep.artistRegistration,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _currentStep == LessonCreationStep.artistRegistration
                    ? const Color(0xFF10b981)
                    : const Color(0xFFe2e8f0),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _buildStepItem(
            stepNumber: 3,
            title: 'רישום אמנים',
            isActive: _currentStep == LessonCreationStep.artistRegistration,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? const Color(0xFF10b981)
                : const Color(0xFFe2e8f0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF6b7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive || isCompleted
                ? const Color(0xFF10b981)
                : const Color(0xFF6b7280),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _basicFormKey,
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
         const SizedBox(height: 32),
          _buildContinueButton(),
          const SizedBox(height: 12),
          _buildCancelButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsStep() {
    return Form(
      key: _advancedFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _buildSectionTitle('פרטי מנחה'),
          const SizedBox(height: 16),
          _buildInstructorNameField(),
          const SizedBox(height: 16),
          _buildInstructorEmailField(),
          const SizedBox(height: 20),

          
          _buildSectionTitle('תמונת רקע'),
          const SizedBox(height: 16),
          _buildImageSection(),
          const SizedBox(height: 32),

          _buildContinueButton(),
          const SizedBox(height: 12),
          _buildCancelButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildArtistRegistrationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("רישום אמנים לשיעור"),
        const SizedBox(height: 16),
        TextField(
          controller: _artistSearchController,
          decoration: InputDecoration(
            labelText: "חפש אמן",
            hintText: "הזן שם או אימייל של אמן",
            prefixIcon: const Icon(Icons.search, color: Color(0xFF10b981)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFf3f4f6),
          ),
          onChanged: _filterArtists,
        ),
        const SizedBox(height: 16),
        _isLoadingArtists
            ? const Center(child: CircularProgressIndicator())
            : _filteredArtists.isEmpty
                ? const Center(child: Text("לא נמצאו אמנים."))
                : SizedBox(
                    height: 300, // Fixed height for the artist list
                    child: SingleChildScrollView(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredArtists.length,
                        itemBuilder: (context, index) {
                          final artist = _filteredArtists[index];
                          final isSelected = _selectedArtists.contains(artist);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFFe5e7eb),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF10b981),
                                child: Text(
                                  artist.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(artist.name),
                              subtitle: Text(artist.email),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Color(0xFF10b981))
                                  : const Icon(Icons.radio_button_unchecked),
                              onTap: () => _toggleArtistSelection(artist),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
        const SizedBox(height: 32),
        _buildActionButtons(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10b981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'המשך',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
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
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createLesson,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _isRecurring
                            ? 'הוסף סדרת $_lessonCount שיעורים'
                            : 'הוספת שיעור',
                        style: const TextStyle(
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
            onPressed: _previousStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6b7280),
              side: const BorderSide(color: Color(0xFFe2e8f0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, size: 20),
                SizedBox(width: 8),
                Text(
                  'חזור',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
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
          hintText: 'הזן שם לשיעור',
          prefixIcon: Icon(Icons.school, color: Color(0xFF10b981)),
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
            _selectedDate != null
                ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                : 'בחר תאריך',
            style: TextStyle(
              fontSize: 16,
              color: _selectedDate != null
                  ? const Color(0xFF1f2937)
                  : const Color(0xFF6b7280),
            ),
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
            _selectedTime != null ? _selectedTime!.format(context) : 'בחר שעה',
            style: TextStyle(
              fontSize: 16,
              color: _selectedTime != null
                  ? const Color(0xFF1f2937)
                  : const Color(0xFF6b7280),
            ),
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
          hintText: 'הזן שם המנחה (אופציונלי)',
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
          hintText: 'הזן אימייל לשיוך אוטומטי (אופציונלי)',
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

 
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonImagePicker(
          initialImagePath: _selectedImagePath,
          lessonId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          onImageChanged: (imagePath) {
            setState(() {
              _selectedImagePath = imagePath;
            });
          },
          showIcon: true,
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
      initialDate: _selectedDate ?? DateTime.now(),
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
      initialTime: _selectedTime ?? TimeOfDay.now(),
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

  void _toggleRecurringMode() {
    setState(() {
      _isRecurring = !_isRecurring;
      if (_isRecurring) {
        _toggleController.forward();
      } else {
        _toggleController.reverse();
      }
    });
  }

  Widget _buildDayChip(
    String dayShort,
    String dayFull,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8b5cf6)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8b5cf6)
                : const Color(0xFFe2e8f0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8b5cf6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            dayShort,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF6b7280),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _createLesson() async {
    if (_selectedArtists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("נא לבחור אמנים לשיעור"),
          backgroundColor: Color(0xFFef4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isRecurring) {
       
      } else {
        await _createSingleLesson();
      }

      widget.onLessonCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("שגיאה ביצירת השיעור: $e"),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createSingleLesson() async {
    final lessonDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final maxCapacity = _maxCapacityController.text.trim().isEmpty
        ? null
        : int.tryParse(_maxCapacityController.text);

    String? imageUrl;
    if (_selectedImagePath != null) {
      imageUrl = await serviceLocator<ImageService>()
          .uploadImage(_selectedImagePath!);
    }

    await ref
        .read(lessonNotifierProvider.notifier)
        .createLesson(
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
          registeredArtistIds: _selectedArtists
              .map((artist) => artist.id)
              .toList(),
          backgroundImagePath: imageUrl,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('השיעור נוצר בהצלחה!'),
          backgroundColor: Color(0xFF10b981),
        ),
      );
    }
  }


}

