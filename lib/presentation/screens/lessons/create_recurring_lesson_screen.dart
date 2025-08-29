import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/lesson_series.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';
import '../../widgets/common/rtl_wrapper.dart';
import '../../widgets/lessons/recurrence_pattern_builder.dart';
import '../../widgets/lessons/smart_suggestions_panel.dart';
import '../../widgets/lessons/conflict_detection_widget.dart';

class CreateRecurringLessonScreen extends ConsumerStatefulWidget {
  final User user;
  final DateTime? initialDate;
  final Map<String, dynamic>? initialLessonData; // ✅ NEW: Accept lesson data

  const CreateRecurringLessonScreen({
    Key? key,
    required this.user,
    this.initialDate,
    this.initialLessonData, // ✅ NEW: Optional lesson data
  }) : super(key: key);

  @override
  ConsumerState<CreateRecurringLessonScreen> createState() =>
      _CreateRecurringLessonScreenState();
}

List<bool> _selectedDays = [
  false,
  false,
  false,
  false,
  false,
  false,
  false,
]; // Sun-Sat
final List<String> _dayNames = [
  'א',
  'ב',
  'ג',
  'ד',
  'ה',
  'ו',
  'ש',
]; // Hebrew day abbreviations
final List<String> _fullDayNames = [
  'ראשון',
  'שני',
  'שלישי',
  'רביעי',
  'חמישי',
  'שישי',
  'שבת',
];

// ✅ ADD: Dynamic lesson count
final TextEditingController _lessonCountController = TextEditingController(
  text: '12',
);
int _lessonCount = 12;

class _CreateRecurringLessonScreenState
    extends ConsumerState<CreateRecurringLessonScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _lessonRepository = serviceLocator<LessonRepository>();

  void _updateLessonPreview() {
    // This method will be called whenever days or lesson count changes
    // You can add logic here to update the preview of lesson dates
    setState(() {
      // Update any preview-related state
    });
  }

  // Form controllers
  final _titleController = TextEditingController();
  final _instructorNameController = TextEditingController();
  final _instructorEmailController = TextEditingController();
  final _maxCapacityController = TextEditingController();

  // Form state
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  int _durationMinutes = 120;
  RecurrencePattern _recurrencePattern = const RecurrencePattern(
    type: RecurrenceType.weekly,
    maxOccurrences: 12,
  );
  String? _selectedInstructorId;
  List<String> _registeredArtistIds = [];
  String? _backgroundImagePath;
  bool _isLoading = false;
  bool _showAdvancedOptions = false;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _slideController.forward();
    _fadeController.forward();
  }

  void _initializeForm() {
    if (widget.initialDate != null) {
      _startDate = widget.initialDate!;
    }

    // ✅ NEW: Initialize from passed lesson data
    if (widget.initialLessonData != null) {
      final data = widget.initialLessonData!;

      _titleController.text = data['title'] ?? '';
      _startDate = data['date'] ?? DateTime.now();
      _startTime = data['time'] ?? const TimeOfDay(hour: 10, minute: 0);
      _durationMinutes = data['duration'] ?? 120;
      _instructorNameController.text = data['instructorName'] ?? '';
      _instructorEmailController.text = data['instructorEmail'] ?? '';

      if (data['maxCapacity'] != null) {
        _maxCapacityController.text = data['maxCapacity'].toString();
      }

      _backgroundImagePath = data['backgroundImagePath'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructorNameController.dispose();
    _instructorEmailController.dispose();
    _maxCapacityController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RTLTextDirectionWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFf8fafc),
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF8b5cf6),
      title: Text(
        widget.initialLessonData != null
            ? 'הגדרת סדרת שיעורים' // When coming from first screen
            : 'יצירת סדרת שיעורים', // When coming directly
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8b5cf6), Color(0xFF7c3aed)],
          ),
        ),
      ),
      toolbarHeight: 120,
    );
  }

  Widget _buildBody() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Main form content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ✅ Summary card (if data passed) OR lesson details card (if manual entry)
                    _buildLessonSummaryCard(),
                    _buildLessonDetailsCard(),
                    const SizedBox(height: 16),
                    _buildRecurrenceCard(),
                    const SizedBox(height: 16),
                    _buildSmartSuggestionsCard(),
                    if (_showAdvancedOptions) ...[
                      const SizedBox(height: 16),
                      _buildAdvancedOptionsCard(),
                    ],
                    const SizedBox(height: 16),
                    _buildConflictDetectionCard(),
                    const SizedBox(height: 100), // Bottom padding
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonDetailsCard() {
    // ✅ REMOVE THIS ENTIRE CARD when data is passed from first screen
    if (widget.initialLessonData != null) {
      return const SizedBox.shrink(); // Don't show duplicate fields
    }

    // Only show this card if user came directly to this screen (no passed data)
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
                    color: const Color(0xFF0c7ff2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFF0c7ff2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'פרטי השיעור',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'נא למלא את פרטי השיעור תחילה במסך הקודם',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceCard() {
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8b5cf6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.repeat,
                    color: Color(0xFF8b5cf6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'דפוס חזרה',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ NEW: Day selector
            _buildDaySelector(),
            const SizedBox(height: 16),

            // ✅ NEW: Dynamic lesson count
            _buildDynamicLessonCount(),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSuggestionsCard() {
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Color(0xFF10b981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'הצעות חכמות',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Smart suggestions panel
            SmartSuggestionsPanel(
              startDate: _startDate,
              startTime: _startTime,
              recurrencePattern: _recurrencePattern,
              onSuggestionApplied: _applySuggestion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6b7280).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF6b7280),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'אפשרויות מתקדמות',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Instructor field
            TextFormField(
              controller: _instructorNameController,
              decoration: InputDecoration(
                labelText: 'שם המנחה',
                hintText: 'שם המנחה לסדרת השיעורים',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Max capacity field
            TextFormField(
              controller: _maxCapacityController,
              decoration: InputDecoration(
                labelText: 'מספר משתתפים מקסימלי',
                hintText: 'לדוגמה: 12',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
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
          ],
        ),
      ),
    );
  }

  Widget _buildConflictDetectionCard() {
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf59e0b).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber,
                    color: Color(0xFFf59e0b),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'זיהוי התנגשויות',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Conflict detection widget
            ConflictDetectionWidget(
              startDate: _startDate,
              startTime: _startTime,
              durationMinutes: _durationMinutes,
              recurrencePattern: _recurrencePattern,
              instructorId: _selectedInstructorId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFe5e7eb)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6b7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF0c7ff2)),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1f2937),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'משך השיעור',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildDurationOption(60, '60 דקות')),
            const SizedBox(width: 8),
            Expanded(child: _buildDurationOption(90, '90 דקות')),
            const SizedBox(width: 8),
            Expanded(child: _buildDurationOption(120, '120 דקות')),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationOption(int minutes, String label) {
    final isSelected = _durationMinutes == minutes;

    return InkWell(
      onTap: () => setState(() => _durationMinutes = minutes),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0c7ff2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0c7ff2)
                : const Color(0xFFe5e7eb),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
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
        child: Row(
          children: [
            // Preview button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previewSeries,
                icon: const Icon(Icons.preview),
                label: const Text('תצוגה מקדימה'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF0c7ff2)),
                  foregroundColor: const Color(0xFF0c7ff2),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Create button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createRecurringSeries,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.add_circle),
                label: Text(_isLoading ? 'יוצר...' : 'צור סדרת שיעורים'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0c7ff2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _toggleAdvancedOptions() {
    setState(() {
      _showAdvancedOptions = !_showAdvancedOptions;
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('he', 'IL'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  void _applySuggestion(Map<String, dynamic> suggestion) {
    // Apply smart suggestion to form
    setState(() {
      if (suggestion.containsKey('startTime')) {
        _startTime = suggestion['startTime'];
      }
      if (suggestion.containsKey('duration')) {
        _durationMinutes = suggestion['duration'];
      }
      if (suggestion.containsKey('instructor')) {
        _instructorNameController.text = suggestion['instructor'];
      }
    });
  }

  void _previewSeries() {
    if (!_formKey.currentState!.validate()) return;

    // Show preview modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPreviewModal(),
    );
  }

  Widget _buildPreviewModal() {
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    // Calculate lesson dates for preview
    final lessonDates = _calculatePreviewDates(
      startDateTime,
      _recurrencePattern,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFe5e7eb),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.preview, color: Color(0xFF0c7ff2)),
                const SizedBox(width: 12),
                const Text(
                  'תצוגה מקדימה - סדרת שיעורים',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Preview content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: lessonDates.length,
              itemBuilder: (context, index) {
                final lessonDate = lessonDates[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFe5e7eb)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0c7ff2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0c7ff2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_titleController.text} - שיעור ${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('EEEE, dd/MM/yyyy').format(lessonDate)} • ${_startTime.format(context)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6b7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createRecurringSeries() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final maxCapacity = _maxCapacityController.text.isNotEmpty
          ? int.parse(_maxCapacityController.text)
          : null;

      final lessons = await _lessonRepository.createRecurringLessonSeries(
        title: _titleController.text.trim(),
        startDate: startDateTime,
        durationMinutes: _durationMinutes,
        recurrence: _recurrencePattern,
        instructorName: _instructorNameController.text.trim().isEmpty
            ? null
            : _instructorNameController.text.trim(),
        instructorEmail: _instructorEmailController.text.trim().isEmpty
            ? null
            : _instructorEmailController.text.trim(),
        assignedInstructorId: _selectedInstructorId,
        maxCapacity: maxCapacity,
        registeredArtistIds: _registeredArtistIds,
        backgroundImagePath: _backgroundImagePath,
        seriesMetadata: {
          'createdBy': widget.user.id,
          'createdByName': widget.user.name,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.of(context).pop(lessons);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('נוצרו ${lessons.length} שיעורים בסדרה בהצלחה!'),
            backgroundColor: const Color(0xFF10b981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת סדרת השיעורים: $e'),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DateTime> _calculatePreviewDates(
    DateTime startDate,
    RecurrencePattern recurrence,
  ) {
    // Simplified version of the repository calculation for preview
    final List<DateTime> dates = [];
    DateTime currentDate = startDate;

    for (int i = 0; i < recurrence.maxOccurrences && i < 20; i++) {
      if (!recurrence.excludeDates.any(
        (excludeDate) => _isSameDay(currentDate, excludeDate),
      )) {
        dates.add(currentDate);
      }

      switch (recurrence.type) {
        case RecurrenceType.weekly:
          currentDate = currentDate.add(
            Duration(days: 7 * recurrence.interval),
          );
          break;
        case RecurrenceType.biweekly:
          currentDate = currentDate.add(
            Duration(days: 14 * recurrence.interval),
          );
          break;
        case RecurrenceType.monthly:
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + recurrence.interval,
            currentDate.day,
            currentDate.hour,
            currentDate.minute,
          );
          break;
        default:
          break;
      }
    }

    return dates;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildLessonSummaryCard() {
    // Only show if we have lesson data from first screen
    if (widget.initialLessonData == null) return const SizedBox.shrink();

    final data = widget.initialLessonData!;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10b981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.3),
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'פרטי השיעור שנבחרו',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Back to edit button
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'ערוך',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lesson details (READ-ONLY)
            _buildSummaryRow(
              Icons.title,
              'שם השיעור',
              data['title']?.toString() ?? '',
            ),
            _buildSummaryRow(
              Icons.calendar_today,
              'תאריך התחלה',
              DateFormat('dd/MM/yyyy').format(data['date'] as DateTime),
            ),
            _buildSummaryRow(
              Icons.access_time,
              'שעת התחלה',
              (data['time'] as TimeOfDay).format(context),
            ),
            _buildSummaryRow(
              Icons.timer,
              'משך השיעור',
              '${data['duration']} דקות',
            ),
            if (data['instructorName']?.toString().isNotEmpty == true)
              _buildSummaryRow(
                Icons.person,
                'מנחה',
                data['instructorName'].toString(),
              ),
            if (data['maxCapacity'] != null)
              _buildSummaryRow(
                Icons.group,
                'קיבולת מקסימלית',
                '${data['maxCapacity']} משתתפים',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSummaryField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDateField() {
    return InkWell(
      onTap: _selectStartDate,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'תאריך',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_startDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTimeField() {
    return InkWell(
      onTap: _selectStartTime,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'שעה',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _startTime.format(context),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableDurationField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: Colors.white.withOpacity(0.8), size: 16),
          const SizedBox(width: 8),
          Text(
            'משך: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildDurationChip(60, '60 דק'),
                const SizedBox(width: 4),
                _buildDurationChip(90, '90 דק'),
                const SizedBox(width: 4),
                _buildDurationChip(120, '120 דק'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = _durationMinutes == minutes;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _durationMinutes = minutes),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: Colors.white.withOpacity(0.5))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_week,
                color: const Color(0xFF8b5cf6),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'בחר ימים בשבוע',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Days grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDays[index] = !_selectedDays[index];
                    _updateLessonPreview();
                  });
                },
                borderRadius: BorderRadius.circular(25),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8b5cf6)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8b5cf6)
                          : Colors.grey.shade300,
                      width: 2,
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
                      _dayNames[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Selected days summary
          if (_selectedDays.any((selected) => selected)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8b5cf6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF8b5cf6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'נבחרו: ${_getSelectedDaysText()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8b5cf6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSelectedDaysText() {
    List<String> selectedDayNames = [];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selectedDayNames.add(_fullDayNames[i]);
      }
    }
    return selectedDayNames.join(', ');
  }

  Widget _buildDynamicLessonCount() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.numbers, color: const Color(0xFF8b5cf6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'מספר שיעורים',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic input with +/- buttons
          Row(
            children: [
              // Decrease button
              InkWell(
                onTap: _lessonCount > 1
                    ? () {
                        setState(() {
                          _lessonCount--;
                          _lessonCountController.text = _lessonCount.toString();
                          _updateLessonPreview();
                        });
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _lessonCount > 1
                        ? const Color(0xFF8b5cf6).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _lessonCount > 1
                          ? const Color(0xFF8b5cf6)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: _lessonCount > 1
                        ? const Color(0xFF8b5cf6)
                        : Colors.grey.shade400,
                  ),
                ),
              ),

              // Number input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _lessonCountController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF8b5cf6),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      final count = int.tryParse(value) ?? 1;
                      if (count >= 1 && count <= 100) {
                        setState(() {
                          _lessonCount = count;
                          _updateLessonPreview();
                        });
                      }
                    },
                  ),
                ),
              ),

              // Increase button
              InkWell(
                onTap: _lessonCount < 100
                    ? () {
                        setState(() {
                          _lessonCount++;
                          _lessonCountController.text = _lessonCount.toString();
                          _updateLessonPreview();
                        });
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _lessonCount < 100
                        ? const Color(0xFF8b5cf6).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _lessonCount < 100
                          ? const Color(0xFF8b5cf6)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: _lessonCount < 100
                        ? const Color(0xFF8b5cf6)
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),

          // Quick selection buttons
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [8, 12, 16, 20, 24].map((count) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _lessonCount = count;
                    _lessonCountController.text = count.toString();
                    _updateLessonPreview();
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _lessonCount == count
                        ? const Color(0xFF8b5cf6)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _lessonCount == count
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
