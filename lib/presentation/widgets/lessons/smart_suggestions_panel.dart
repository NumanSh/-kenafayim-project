import 'package:flutter/material.dart';
import '../../../data/models/lesson.dart';

class SmartSuggestionsPanel extends StatefulWidget {
  final DateTime startDate;
  final TimeOfDay startTime;
  final RecurrencePattern recurrencePattern;
  final Function(Map<String, dynamic>) onSuggestionApplied;

  const SmartSuggestionsPanel({
    Key? key,
    required this.startDate,
    required this.startTime,
    required this.recurrencePattern,
    required this.onSuggestionApplied,
  }) : super(key: key);

  @override
  State<SmartSuggestionsPanel> createState() => _SmartSuggestionsPanelState();
}

class _SmartSuggestionsPanelState extends State<SmartSuggestionsPanel>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<SmartSuggestion> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateSuggestions();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SmartSuggestionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.startTime != widget.startTime ||
        oldWidget.recurrencePattern != widget.recurrencePattern) {
      _generateSuggestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_suggestions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _suggestions
          .map((suggestion) => _buildSuggestionCard(suggestion))
          .toList(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: const Icon(
                    Icons.lightbulb,
                    color: Color(0xFF10b981),
                    size: 20,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'מחשב הצעות חכמות...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6b7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: const Color(0xFF6b7280),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'אין הצעות זמינות כרגע. נסה לשנות את התאריך או השעה.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(SmartSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: suggestion.priority == SuggestionPriority.high
            ? const Color(0xFF10b981).withOpacity(0.05)
            : const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: suggestion.priority == SuggestionPriority.high
              ? const Color(0xFF10b981).withOpacity(0.3)
              : const Color(0xFFe5e7eb),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: suggestion.priority == SuggestionPriority.high
                        ? const Color(0xFF10b981).withOpacity(0.1)
                        : const Color(0xFF0c7ff2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    suggestion.icon,
                    size: 16,
                    color: suggestion.priority == SuggestionPriority.high
                        ? const Color(0xFF10b981)
                        : const Color(0xFF0c7ff2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        suggestion.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (suggestion.priority == SuggestionPriority.high)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'מומלץ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            if (suggestion.details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: suggestion.details
                      .map(
                        (detail) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: const Color(0xFF10b981),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  detail,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _applySuggestion(suggestion),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          suggestion.priority == SuggestionPriority.high
                          ? const Color(0xFF10b981)
                          : const Color(0xFF0c7ff2),
                      side: BorderSide(
                        color: suggestion.priority == SuggestionPriority.high
                            ? const Color(0xFF10b981)
                            : const Color(0xFF0c7ff2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('החל הצעה'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _dismissSuggestion(suggestion),
                  icon: const Icon(Icons.close, size: 16),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateSuggestions() {
    setState(() => _isLoading = true);

    // Simulate AI processing
    Future.delayed(const Duration(milliseconds: 1500), () {
      final suggestions = <SmartSuggestion>[];

      // Time-based suggestions
      final hour = widget.startTime.hour;
      if (hour >= 16 && hour <= 18) {
        suggestions.add(
          SmartSuggestion(
            title: 'שעת פעילות מומלצת',
            description: 'שעות אחר הצהריים מציגות נוכחות גבוהה יותר',
            icon: Icons.schedule,
            priority: SuggestionPriority.high,
            details: [
              'נוכחות ממוצעת: 92%',
              'פחות ביטולים',
              'זמינות מנחים טובה',
            ],
            data: {'optimized': true},
          ),
        );
      }

      // Day-based suggestions
      final weekday = widget.startDate.weekday;
      if (weekday == DateTime.sunday || weekday == DateTime.tuesday) {
        suggestions.add(
          SmartSuggestion(
            title: 'יום מועדף לשיעורים',
            description: 'ימים א\' ו-ג\' מציגים השתתפות גבוהה',
            icon: Icons.calendar_today,
            priority: SuggestionPriority.medium,
            details: [
              'פחות התנגשויות עם בתי ספר',
              'זמינות חניה טובה',
              'מנחים זמינים',
            ],
            data: {'dayOptimized': true},
          ),
        );
      }

      // Series length suggestions
      if (widget.recurrencePattern.maxOccurrences > 16) {
        suggestions.add(
          SmartSuggestion(
            title: 'אורך סדרה מומלץ',
            description: 'סדרות של 12-16 שיעורים מציגות השלמה טובה יותר',
            icon: Icons.timeline,
            priority: SuggestionPriority.medium,
            details: ['שיעור השלמה: 87%', 'פחות נשירה', 'מחויבות טובה יותר'],
            data: {'maxOccurrences': 12},
          ),
        );
      }

      // Conflict warnings
      if (hour >= 15 &&
          hour <= 17 &&
          weekday >= DateTime.sunday &&
          weekday <= DateTime.thursday) {
        suggestions.add(
          SmartSuggestion(
            title: 'התנגשות פוטנציאלית',
            description: 'שעות אלו עלולות להתנגש עם פעילויות בית ספר',
            icon: Icons.warning_amber,
            priority: SuggestionPriority.low,
            details: [
              'בדוק עם הורים',
              'שקול שעות מאוחרות יותר',
              'הכן תוכנית גיבוי',
            ],
            data: {'warning': 'school_conflict'},
          ),
        );
      }

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    });
  }

  void _applySuggestion(SmartSuggestion suggestion) {
    widget.onSuggestionApplied(suggestion.data);

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('הצעה הוחלה: ${suggestion.title}'),
        backgroundColor: const Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // Remove applied suggestion
    setState(() {
      _suggestions.remove(suggestion);
    });
  }

  void _dismissSuggestion(SmartSuggestion suggestion) {
    setState(() {
      _suggestions.remove(suggestion);
    });
  }
}

// Supporting classes
enum SuggestionPriority { high, medium, low }

class SmartSuggestion {
  final String title;
  final String description;
  final IconData icon;
  final SuggestionPriority priority;
  final List<String> details;
  final Map<String, dynamic> data;

  const SmartSuggestion({
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
    this.details = const [],
    this.data = const {},
  });
}
