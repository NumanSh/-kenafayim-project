import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/report.dart';
import '../../../data/models/user.dart';

class FilterCriteria {
  final DateTimeRange? dateRange;
  final List<String> selectedInstructors;
  final List<String> selectedArtists;
  final List<String> lessonStatuses;
  final List<ReportType> reportTypes;
  final bool includeRecurringOnly;
  final bool includeSeriesData;
  final RecurrenceType? recurrenceFilter;
  final int? minAttendance;
  final int? maxAttendance;
  final List<String> attendanceStatuses;
  final String? searchQuery;

  const FilterCriteria({
    this.dateRange,
    this.selectedInstructors = const [],
    this.selectedArtists = const [],
    this.lessonStatuses = const [],
    this.reportTypes = const [],
    this.includeRecurringOnly = false,
    this.includeSeriesData = false,
    this.recurrenceFilter,
    this.minAttendance,
    this.maxAttendance,
    this.attendanceStatuses = const [],
    this.searchQuery,
  });

  FilterCriteria copyWith({
    DateTimeRange? dateRange,
    List<String>? selectedInstructors,
    List<String>? selectedArtists,
    List<String>? lessonStatuses,
    List<ReportType>? reportTypes,
    bool? includeRecurringOnly,
    bool? includeSeriesData,
    RecurrenceType? recurrenceFilter,
    int? minAttendance,
    int? maxAttendance,
    List<String>? attendanceStatuses,
    String? searchQuery,
  }) {
    return FilterCriteria(
      dateRange: dateRange ?? this.dateRange,
      selectedInstructors: selectedInstructors ?? this.selectedInstructors,
      selectedArtists: selectedArtists ?? this.selectedArtists,
      lessonStatuses: lessonStatuses ?? this.lessonStatuses,
      reportTypes: reportTypes ?? this.reportTypes,
      includeRecurringOnly: includeRecurringOnly ?? this.includeRecurringOnly,
      includeSeriesData: includeSeriesData ?? this.includeSeriesData,
      recurrenceFilter: recurrenceFilter ?? this.recurrenceFilter,
      minAttendance: minAttendance ?? this.minAttendance,
      maxAttendance: maxAttendance ?? this.maxAttendance,
      attendanceStatuses: attendanceStatuses ?? this.attendanceStatuses,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters {
    return dateRange != null ||
        selectedInstructors.isNotEmpty ||
        selectedArtists.isNotEmpty ||
        lessonStatuses.isNotEmpty ||
        reportTypes.isNotEmpty ||
        includeRecurringOnly ||
        includeSeriesData ||
        recurrenceFilter != null ||
        minAttendance != null ||
        maxAttendance != null ||
        attendanceStatuses.isNotEmpty ||
        (searchQuery?.isNotEmpty ?? false);
  }

  int get activeFilterCount {
    int count = 0;
    if (dateRange != null) count++;
    if (selectedInstructors.isNotEmpty) count++;
    if (selectedArtists.isNotEmpty) count++;
    if (lessonStatuses.isNotEmpty) count++;
    if (reportTypes.isNotEmpty) count++;
    if (includeRecurringOnly) count++;
    if (includeSeriesData) count++;
    if (recurrenceFilter != null) count++;
    if (minAttendance != null || maxAttendance != null) count++;
    if (attendanceStatuses.isNotEmpty) count++;
    if (searchQuery?.isNotEmpty ?? false) count++;
    return count;
  }
}

class AdvancedFilterPanel extends ConsumerStatefulWidget {
  final FilterCriteria initialFilters;
  final Function(FilterCriteria) onFiltersChanged;
  final List<User> availableInstructors;
  final List<User> availableArtists;

  const AdvancedFilterPanel({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
    required this.availableInstructors,
    required this.availableArtists,
  });

  @override
  ConsumerState<AdvancedFilterPanel> createState() =>
      _AdvancedFilterPanelState();
}

class _AdvancedFilterPanelState extends ConsumerState<AdvancedFilterPanel>
    with TickerProviderStateMixin {
  late FilterCriteria _currentFilters;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAttendanceController =
      TextEditingController();
  final TextEditingController _maxAttendanceController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _tabController = TabController(length: 4, vsync: this);

    _searchController.text = _currentFilters.searchQuery ?? '';
    _minAttendanceController.text =
        _currentFilters.minAttendance?.toString() ?? '';
    _maxAttendanceController.text =
        _currentFilters.maxAttendance?.toString() ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _minAttendanceController.dispose();
    _maxAttendanceController.dispose();
    super.dispose();
  }

  void _updateFilters(FilterCriteria newFilters) {
    setState(() => _currentFilters = newFilters);
    widget.onFiltersChanged(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTabBar(),
          _buildTabContent(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.filter_list,
              color: Color(0xFF3b82f6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'מסנני חיפוש מתקדמים',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
          ),
          if (_currentFilters.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10b981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentFilters.activeFilterCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF3b82f6),
        unselectedLabelColor: const Color(0xFF6b7280),
        indicatorColor: const Color(0xFF3b82f6),
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'תאריכים'),
          Tab(text: 'אנשים'),
          Tab(text: 'שיעורים'),
          Tab(text: 'נוכחות'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildDateFilters(),
          _buildPeopleFilters(),
          _buildLessonFilters(),
          _buildAttendanceFilters(),
        ],
      ),
    );
  }

  Widget _buildDateFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('טווח תאריכים'),
          const SizedBox(height: 12),
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          _buildSectionTitle('מסנני זמן מהירים'),
          const SizedBox(height: 12),
          _buildQuickDateFilters(),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range, size: 20, color: Color(0xFF6b7280)),
              const SizedBox(width: 8),
              Text(
                _currentFilters.dateRange != null
                    ? '${DateFormat('dd/MM/yyyy').format(_currentFilters.dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_currentFilters.dateRange!.end)}'
                    : 'בחר טווח תאריכים',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const Spacer(),
              TextButton(onPressed: _selectDateRange, child: const Text('שנה')),
            ],
          ),
          if (_currentFilters.dateRange != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  _updateFilters(_currentFilters.copyWith(dateRange: null)),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('נקה'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFef4444),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickDateFilters() {
    final quickFilters = [
      {'label': 'השבוע', 'days': 7},
      {'label': 'החודש', 'days': 30},
      {'label': '3 חודשים', 'days': 90},
      {'label': 'השנה', 'days': 365},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickFilters.map((filter) {
        return FilterChip(
          label: Text(filter['label'] as String),
          selected: _isQuickDateSelected(filter['days'] as int),
          onSelected: (selected) {
            if (selected) {
              _applyQuickDateFilter(filter['days'] as int);
            }
          },
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFF3b82f6).withOpacity(0.1),
          checkmarkColor: const Color(0xFF3b82f6),
        );
      }).toList(),
    );
  }

  Widget _buildPeopleFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('מנחים'),
          const SizedBox(height: 12),
          _buildInstructorSelector(),
          const SizedBox(height: 24),
          _buildSectionTitle('אמנים'),
          const SizedBox(height: 12),
          _buildArtistSelector(),
        ],
      ),
    );
  }

  Widget _buildInstructorSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 20, color: Color(0xFF6b7280)),
              const SizedBox(width: 8),
              Text(
                _currentFilters.selectedInstructors.isEmpty
                    ? 'כל המנחים'
                    : '${_currentFilters.selectedInstructors.length} מנחים נבחרו',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showInstructorSelector,
                child: const Text('בחר'),
              ),
            ],
          ),
          if (_currentFilters.selectedInstructors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _currentFilters.selectedInstructors.map((instructorId) {
                final instructor =
                    widget.availableInstructors
                        .where((i) => i.id == instructorId)
                        .firstOrNull ??
                    User(
                      id: instructorId,
                      name: 'לא ידוע',
                      email: '',
                      role: UserRole.mentor,
                      phoneNumber: '',
                      createdAt: DateTime.now(),
                    );

                return Chip(
                  label: Text(instructor.name),
                  onDeleted: () => _removeInstructor(instructorId),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: const Color(0xFF3b82f6).withOpacity(0.1),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3b82f6),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArtistSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette, size: 20, color: Color(0xFF6b7280)),
              const SizedBox(width: 8),
              Text(
                _currentFilters.selectedArtists.isEmpty
                    ? 'כל האמנים'
                    : '${_currentFilters.selectedArtists.length} אמנים נבחרו',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showArtistSelector,
                child: const Text('בחר'),
              ),
            ],
          ),
          if (_currentFilters.selectedArtists.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _currentFilters.selectedArtists.take(5).map((artistId) {
                final artist =
                    widget.availableArtists
                        .where((a) => a.id == artistId)
                        .firstOrNull ??
                    User(
                      id: artistId,
                      name: 'לא ידוע',
                      email: '',
                      role: UserRole.client,
                      phoneNumber: '',
                      createdAt: DateTime.now(),
                    );

                return Chip(
                  label: Text(artist.name),
                  onDeleted: () => _removeArtist(artistId),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: const Color(0xFF10b981).withOpacity(0.1),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10b981),
                  ),
                );
              }).toList(),
            ),
            if (_currentFilters.selectedArtists.length > 5)
              Text(
                '+${_currentFilters.selectedArtists.length - 5} נוספים',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('חיפוש טקסט'),
          const SizedBox(height: 12),
          _buildSearchField(),
          const SizedBox(height: 24),
          _buildSectionTitle('סטטוס שיעורים'),
          const SizedBox(height: 12),
          _buildStatusFilters(),
          const SizedBox(height: 24),
          _buildSectionTitle('שיעורים חוזרים'),
          const SizedBox(height: 12),
          _buildRecurrenceFilters(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'חפש לפי שם שיעור, מנחה או תיאור...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _updateFilters(_currentFilters.copyWith(searchQuery: ''));
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe5e7eb)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3b82f6)),
        ),
      ),
      onChanged: (value) {
        _updateFilters(
          _currentFilters.copyWith(searchQuery: value.isEmpty ? null : value),
        );
      },
    );
  }

  Widget _buildStatusFilters() {
    final statuses = [
      {
        'value': 'scheduled',
        'label': 'מתוכנן',
        'color': const Color(0xFF3b82f6),
      },
      {
        'value': 'completed',
        'label': 'הושלם',
        'color': const Color(0xFF10b981),
      },
      {'value': 'cancelled', 'label': 'בוטל', 'color': const Color(0xFFef4444)},
      {
        'value': 'in_progress',
        'label': 'בביצוע',
        'color': const Color(0xFFf59e0b),
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {
        final isSelected = _currentFilters.lessonStatuses.contains(
          status['value'],
        );
        return FilterChip(
          label: Text(status['label'] as String),
          selected: isSelected,
          onSelected: (selected) =>
              _toggleLessonStatus(status['value'] as String),
          backgroundColor: Colors.white,
          selectedColor: (status['color'] as Color).withOpacity(0.1),
          checkmarkColor: status['color'] as Color,
        );
      }).toList(),
    );
  }

  Widget _buildRecurrenceFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _currentFilters.includeRecurringOnly,
              onChanged: (value) => _updateFilters(
                _currentFilters.copyWith(includeRecurringOnly: value ?? false),
              ),
            ),
            const Text('שיעורים חוזרים בלבד'),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _currentFilters.includeSeriesData,
              onChanged: (value) => _updateFilters(
                _currentFilters.copyWith(includeSeriesData: value ?? false),
              ),
            ),
            const Text('כלול נתוני סדרות'),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'סוג חזרה:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RecurrenceType.values.map((type) {
            final isSelected = _currentFilters.recurrenceFilter == type;
            return FilterChip(
              label: Text(_getRecurrenceTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) => _updateFilters(
                _currentFilters.copyWith(
                  recurrenceFilter: selected ? type : null,
                ),
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF8b5cf6).withOpacity(0.1),
              checkmarkColor: const Color(0xFF8b5cf6),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttendanceFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('טווח נוכחות'),
          const SizedBox(height: 12),
          _buildAttendanceRangeSelector(),
          const SizedBox(height: 24),
          _buildSectionTitle('סטטוס נוכחות'),
          const SizedBox(height: 12),
          _buildAttendanceStatusFilters(),
        ],
      ),
    );
  }

  Widget _buildAttendanceRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'מספר משתתפים:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAttendanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'מינימום',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    final min = int.tryParse(value);
                    _updateFilters(
                      _currentFilters.copyWith(minAttendance: min),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxAttendanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'מקסימום',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    final max = int.tryParse(value);
                    _updateFilters(
                      _currentFilters.copyWith(maxAttendance: max),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatusFilters() {
    final statuses = [
      {'value': 'present', 'label': 'נוכח', 'color': const Color(0xFF10b981)},
      {'value': 'absent', 'label': 'נעדר', 'color': const Color(0xFFef4444)},
      {'value': 'late', 'label': 'איחור', 'color': const Color(0xFFf59e0b)},
      {'value': 'excused', 'label': 'מוצדק', 'color': const Color(0xFF8b5cf6)},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {
        final isSelected = _currentFilters.attendanceStatuses.contains(
          status['value'],
        );
        return FilterChip(
          label: Text(status['label'] as String),
          selected: isSelected,
          onSelected: (selected) =>
              _toggleAttendanceStatus(status['value'] as String),
          backgroundColor: Colors.white,
          selectedColor: (status['color'] as Color).withOpacity(0.1),
          checkmarkColor: status['color'] as Color,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFe5e7eb))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAllFilters,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFe5e7eb)),
              ),
              child: const Text('נקה הכל'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3b82f6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _currentFilters.hasActiveFilters
                    ? 'החל מסננים (${_currentFilters.activeFilterCount})'
                    : 'סגור',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1f2937),
      ),
    );
  }

  // Helper methods
  String _getRecurrenceTypeLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'ללא';
      case RecurrenceType.weekly:
        return 'שבועי';
      case RecurrenceType.biweekly:
        return 'דו-שבועי';
      case RecurrenceType.monthly:
        return 'חודשי';
      case RecurrenceType.custom:
        return 'מותאם';
    }
  }

  bool _isQuickDateSelected(int days) {
    if (_currentFilters.dateRange == null) return false;
    final now = DateTime.now();
    final expectedStart = now.subtract(Duration(days: days));
    final actualStart = _currentFilters.dateRange!.start;
    return actualStart.difference(expectedStart).inDays.abs() <= 1;
  }

  void _applyQuickDateFilter(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    _updateFilters(
      _currentFilters.copyWith(
        dateRange: DateTimeRange(start: start, end: now),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _currentFilters.dateRange,
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

    if (picked != null) {
      _updateFilters(_currentFilters.copyWith(dateRange: picked));
    }
  }

  void _showInstructorSelector() {
    showDialog(
      context: context,
      builder: (context) => _MultiSelectDialog<User>(
        title: 'בחר מנחים',
        items: widget.availableInstructors,
        selectedItems: widget.availableInstructors
            .where((i) => _currentFilters.selectedInstructors.contains(i.id))
            .toList(),
        itemBuilder: (instructor) => ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF3b82f6),
            child: Text(
              instructor.name.isNotEmpty
                  ? instructor.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(instructor.name),
          subtitle: Text(instructor.email),
        ),
        onSelectionChanged: (selected) {
          _updateFilters(
            _currentFilters.copyWith(
              selectedInstructors: selected.map((i) => i.id).toList(),
            ),
          );
        },
      ),
    );
  }

  void _showArtistSelector() {
    showDialog(
      context: context,
      builder: (context) => _MultiSelectDialog<User>(
        title: 'בחר אמנים',
        items: widget.availableArtists,
        selectedItems: widget.availableArtists
            .where((a) => _currentFilters.selectedArtists.contains(a.id))
            .toList(),
        itemBuilder: (artist) => ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF10b981),
            child: Text(
              artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(artist.name),
          subtitle: Text(artist.email),
        ),
        onSelectionChanged: (selected) {
          _updateFilters(
            _currentFilters.copyWith(
              selectedArtists: selected.map((a) => a.id).toList(),
            ),
          );
        },
      ),
    );
  }

  void _removeInstructor(String instructorId) {
    final updated = List<String>.from(_currentFilters.selectedInstructors)
      ..remove(instructorId);
    _updateFilters(_currentFilters.copyWith(selectedInstructors: updated));
  }

  void _removeArtist(String artistId) {
    final updated = List<String>.from(_currentFilters.selectedArtists)
      ..remove(artistId);
    _updateFilters(_currentFilters.copyWith(selectedArtists: updated));
  }

  void _toggleLessonStatus(String status) {
    final updated = List<String>.from(_currentFilters.lessonStatuses);
    if (updated.contains(status)) {
      updated.remove(status);
    } else {
      updated.add(status);
    }
    _updateFilters(_currentFilters.copyWith(lessonStatuses: updated));
  }

  void _toggleAttendanceStatus(String status) {
    final updated = List<String>.from(_currentFilters.attendanceStatuses);
    if (updated.contains(status)) {
      updated.remove(status);
    } else {
      updated.add(status);
    }
    _updateFilters(_currentFilters.copyWith(attendanceStatuses: updated));
  }

  void _clearAllFilters() {
    _searchController.clear();
    _minAttendanceController.clear();
    _maxAttendanceController.clear();

    _updateFilters(const FilterCriteria());
  }
}

class _MultiSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> selectedItems;
  final Widget Function(T) itemBuilder;
  final Function(List<T>) onSelectionChanged;

  const _MultiSelectDialog({
    required this.title,
    required this.items,
    required this.selectedItems,
    required this.itemBuilder,
    required this.onSelectionChanged,
  });

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> _selectedItems;
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
    _filteredItems = List.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          // For User objects, check name and email
          if (item is User) {
            final user = item as User;
            return user.name.toLowerCase().contains(query.toLowerCase()) ||
                user.email.toLowerCase().contains(query.toLowerCase());
          }
          // Fallback to toString
          final itemText = item.toString().toLowerCase();
          return itemText.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'חפש...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterItems,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final isSelected = _selectedItems.contains(item);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedItems.add(item);
                        } else {
                          _selectedItems.remove(item);
                        }
                      });
                    },
                    title: widget.itemBuilder(item),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${_selectedItems.length} נבחרו',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ביטול'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onSelectionChanged(_selectedItems);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3b82f6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('אישור'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
