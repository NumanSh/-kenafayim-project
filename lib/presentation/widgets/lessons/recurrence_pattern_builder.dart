import 'package:flutter/material.dart';
import '../../../data/models/lesson.dart';

class RecurrencePatternBuilder extends StatefulWidget {
  final RecurrencePattern initialPattern;
  final Function(RecurrencePattern) onPatternChanged;

  const RecurrencePatternBuilder({
    Key? key,
    required this.initialPattern,
    required this.onPatternChanged,
  }) : super(key: key);

  @override
  State<RecurrencePatternBuilder> createState() =>
      _RecurrencePatternBuilderState();
}

class _RecurrencePatternBuilderState extends State<RecurrencePatternBuilder>
    with TickerProviderStateMixin {
  late RecurrenceType _selectedType;
  late int _interval;
  late int _maxOccurrences;
  late List<WeekDay> _selectedDays;
  late List<DateTime> _excludeDates;
  DateTime? _endDate;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFromPattern();
    _setupAnimations();
  }

  void _initializeFromPattern() {
    _selectedType = widget.initialPattern.type;
    _interval = widget.initialPattern.interval;
    _maxOccurrences = widget.initialPattern.maxOccurrences;
    _selectedDays = List.from(widget.initialPattern.daysOfWeek);
    _excludeDates = List.from(widget.initialPattern.excludeDates);
    _endDate = widget.initialPattern.endDate;
  }

  void _setupAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _expandController.forward();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _expandAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickPatterns(),
          const SizedBox(height: 20),
          _buildCustomPattern(),
          const SizedBox(height: 20),
          _buildSeriesLength(),
          if (_selectedType != RecurrenceType.none) ...[
            const SizedBox(height: 20),
            _buildExcludeDates(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickPatterns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'דפוסים מהירים',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPatternChip(
                RecurrenceType.weekly,
                'שבועי',
                Icons.calendar_view_week,
                const Color(0xFF0c7ff2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPatternChip(
                RecurrenceType.biweekly,
                'דו-שבועי',
                Icons.date_range,
                const Color(0xFF8b5cf6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPatternChip(
                RecurrenceType.monthly,
                'חודשי',
                Icons.calendar_month,
                const Color(0xFF10b981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatternChip(
    RecurrenceType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => _updatePattern(type: type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFe5e7eb),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : const Color(0xFF6b7280),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF6b7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPattern() {
    if (_selectedType == RecurrenceType.none) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'התאמה אישית',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),

          // Interval selector
          Row(
            children: [
              const Text(
                'כל',
                style: TextStyle(fontSize: 16, color: Color(0xFF374151)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFe5e7eb)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _interval,
                      items: List.generate(4, (index) => index + 1)
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _updatePattern(interval: value);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getIntervalLabel(),
                style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
              ),
            ],
          ),

          // Days of week selector (for weekly patterns)
          if (_selectedType == RecurrenceType.weekly ||
              _selectedType == RecurrenceType.biweekly) ...[
            const SizedBox(height: 16),
            _buildDaysOfWeekSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildDaysOfWeekSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ימים בשבוע',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WeekDay.values.map((day) {
            final isSelected = _selectedDays.contains(day);
            return InkWell(
              onTap: () => _toggleWeekDay(day),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0c7ff2)
                      : const Color(0xFFf8fafc),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0c7ff2)
                        : const Color(0xFFe5e7eb),
                  ),
                ),
                child: Text(
                  _getDayLabel(day),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeriesLength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'אורך הסדרה',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),

        // Quick options
        Row(
          children: [
            Expanded(child: _buildLengthOption(8, '8 שיעורים')),
            const SizedBox(width: 8),
            Expanded(child: _buildLengthOption(12, '12 שיעורים')),
            const SizedBox(width: 8),
            Expanded(child: _buildLengthOption(16, '16 שיעורים')),
          ],
        ),

        const SizedBox(height: 12),

        // Custom length
        Row(
          children: [
            const Text(
              'מותאם אישית:',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFe5e7eb)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: TextFormField(
                  initialValue: _maxOccurrences.toString(),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    final occurrences = int.tryParse(value);
                    if (occurrences != null && occurrences > 0) {
                      _updatePattern(maxOccurrences: occurrences);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'שיעורים',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLengthOption(int length, String label) {
    final isSelected = _maxOccurrences == length;

    return InkWell(
      onTap: () => _updatePattern(maxOccurrences: length),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10b981).withOpacity(0.1)
              : const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10b981)
                : const Color(0xFFe5e7eb),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? const Color(0xFF10b981)
                : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildExcludeDates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'תאריכים לדילוג',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addExcludeDate,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('הוסף חופשה'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0c7ff2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),

        if (_excludeDates.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _excludeDates.map((date) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFfef3c7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFf59e0b)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 14,
                      color: const Color(0xFFf59e0b),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFf59e0b),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _removeExcludeDate(date),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Color(0xFFf59e0b),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // Helper methods
  String _getIntervalLabel() {
    switch (_selectedType) {
      case RecurrenceType.weekly:
      case RecurrenceType.biweekly:
        return _interval == 1 ? 'שבוע' : 'שבועות';
      case RecurrenceType.monthly:
        return _interval == 1 ? 'חודש' : 'חודשים';
      default:
        return '';
    }
  }

  String _getDayLabel(WeekDay day) {
    switch (day) {
      case WeekDay.sunday:
        return 'א\'';
      case WeekDay.monday:
        return 'ב\'';
      case WeekDay.tuesday:
        return 'ג\'';
      case WeekDay.wednesday:
        return 'ד\'';
      case WeekDay.thursday:
        return 'ה\'';
      case WeekDay.friday:
        return 'ו\'';
      case WeekDay.saturday:
        return 'ש\'';
    }
  }

  void _toggleWeekDay(WeekDay day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
    _notifyPatternChanged();
  }

  void _updatePattern({
    RecurrenceType? type,
    int? interval,
    int? maxOccurrences,
  }) {
    setState(() {
      if (type != null) {
        _selectedType = type;
        // Reset days when changing type
        if (type != RecurrenceType.weekly && type != RecurrenceType.biweekly) {
          _selectedDays.clear();
        }
      }
      if (interval != null) _interval = interval;
      if (maxOccurrences != null) _maxOccurrences = maxOccurrences;
    });
    _notifyPatternChanged();
  }

  Future<void> _addExcludeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('he', 'IL'),
    );

    if (picked != null && !_excludeDates.contains(picked)) {
      setState(() {
        _excludeDates.add(picked);
        _excludeDates.sort();
      });
      _notifyPatternChanged();
    }
  }

  void _removeExcludeDate(DateTime date) {
    setState(() {
      _excludeDates.remove(date);
    });
    _notifyPatternChanged();
  }

  void _notifyPatternChanged() {
    final pattern = RecurrencePattern(
      type: _selectedType,
      interval: _interval,
      daysOfWeek: List.from(_selectedDays),
      maxOccurrences: _maxOccurrences,
      excludeDates: List.from(_excludeDates),
      endDate: _endDate,
    );

    widget.onPatternChanged(pattern);
  }
}
