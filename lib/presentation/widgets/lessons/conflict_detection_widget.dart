import 'package:flutter/material.dart';
import '../../../data/models/lesson.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../config/service_locator.dart';

class ConflictDetectionWidget extends StatefulWidget {
  final DateTime startDate;
  final TimeOfDay startTime;
  final int durationMinutes;
  final RecurrencePattern recurrencePattern;
  final String? instructorId;

  const ConflictDetectionWidget({
    super.key,
    required this.startDate,
    required this.startTime,
    required this.durationMinutes,
    required this.recurrencePattern,
    this.instructorId,
  });

  @override
  State<ConflictDetectionWidget> createState() =>
      _ConflictDetectionWidgetState();
}

class _ConflictDetectionWidgetState extends State<ConflictDetectionWidget>
    with TickerProviderStateMixin {
  final _lessonRepository = serviceLocator<LessonRepository>();

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  List<ConflictInfo> _conflicts = [];
  bool _isScanning = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startConflictDetection();
  }

  void _setupAnimations() {
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ConflictDetectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.startTime != widget.startTime ||
        oldWidget.durationMinutes != widget.durationMinutes ||
        oldWidget.recurrencePattern != widget.recurrencePattern ||
        oldWidget.instructorId != widget.instructorId) {
      _startConflictDetection();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return _buildScanningState();
    }

    if (!_hasScanned) {
      return _buildInitialState();
    }

    if (_conflicts.isEmpty) {
      return _buildNoConflictsState();
    }

    return _buildConflictsFound();
  }

  Widget _buildScanningState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFf59e0b).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: _scanAnimation.value * 2 * 3.14159,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            const Color(0xFFf59e0b).withOpacity(0.1),
                            const Color(0xFFf59e0b),
                            const Color(0xFFf59e0b).withOpacity(0.1),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  const Icon(Icons.radar, color: Color(0xFFf59e0b), size: 24),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'סורק התנגשויות...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'בודק זמינות מנחים וחדרים',
            style: TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: const Color(0xFF6b7280), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'זיהוי התנגשויות יתחיל לאחר הגדרת פרטי השיעור',
              style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoConflictsState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10b981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF10b981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'אין התנגשויות!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10b981),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'כל התאריכים זמינים ליצירת הסדרה',
                  style: TextStyle(fontSize: 12, color: Color(0xFF059669)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictsFound() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFfef3c7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber,
                color: Color(0xFFf59e0b),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'נמצאו ${_conflicts.length} התנגשויות',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFf59e0b),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'בדוק את ההתנגשויות ופתור לפני יצירת הסדרה',
                      style: TextStyle(fontSize: 12, color: Color(0xFFd97706)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Conflicts list
        ..._conflicts.map((conflict) => _buildConflictCard(conflict)).toList(),
      ],
    );
  }

  Widget _buildConflictCard(ConflictInfo conflict) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFfecaca)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getConflictIcon(conflict.type),
                color: const Color(0xFFef4444),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFfecaca),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getConflictSeverityLabel(conflict.severity),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFef4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conflict.description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
          ),
          if (conflict.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'הצעות לפתרון:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...conflict.suggestions
                      .map(
                        (suggestion) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lightbulb,
                                size: 12,
                                color: Color(0xFF0c7ff2),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  suggestion,
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startConflictDetection() {
    setState(() {
      _isScanning = true;
      _hasScanned = false;
      _conflicts.clear();
    });

    _scanController.repeat();

    // Simulate conflict detection
    Future.delayed(const Duration(milliseconds: 2000), () {
      _performConflictDetection();
    });
  }

  void _performConflictDetection() {
    final conflicts = <ConflictInfo>[];

    // Simulate various conflict scenarios
    final hour = widget.startTime.hour;
    final weekday = widget.startDate.weekday;

    // Peak hours conflict
    if (hour >= 16 && hour <= 18) {
      conflicts.add(
        ConflictInfo(
          type: ConflictType.timeSlot,
          severity: ConflictSeverity.medium,
          title: 'שעות עומס',
          description: 'שעות 16:00-18:00 הן שעות עומס עם ביקוש גבוה',
          suggestions: [
            'שקול שעות 14:00-16:00 או 18:30-20:30',
            'הכן רשימת המתנה',
            'בדוק זמינות חדרים נוספים',
          ],
        ),
      );
    }

    // Weekend conflicts
    if (weekday == DateTime.friday || weekday == DateTime.saturday) {
      conflicts.add(
        ConflictInfo(
          type: ConflictType.availability,
          severity: ConflictSeverity.low,
          title: 'סוף שבוע',
          description: 'שיעורים בסוף השבוע עלולים להיות פחות פופולריים',
          suggestions: [
            'שקול ימי ראשון-חמישי',
            'הצע הנחה לשיעורי סוף שבוע',
            'בדוק עניין מראש',
          ],
        ),
      );
    }

    // Instructor conflict (if specified)
    if (widget.instructorId != null) {
      conflicts.add(
        ConflictInfo(
          type: ConflictType.instructor,
          severity: ConflictSeverity.high,
          title: 'התנגשות מנחה',
          description: 'המנחה הנבחר עלול להיות תפוס בחלק מהתאריכים',
          suggestions: [
            'בחר מנחה חלופי',
            'שנה את שעות השיעור',
            'פצל את הסדרה לשני מנחים',
          ],
        ),
      );
    }

    _scanController.stop();
    _scanController.reset();

    if (mounted) {
      setState(() {
        _conflicts = conflicts;
        _isScanning = false;
        _hasScanned = true;
      });
    }
  }

  IconData _getConflictIcon(ConflictType type) {
    switch (type) {
      case ConflictType.timeSlot:
        return Icons.schedule;
      case ConflictType.instructor:
        return Icons.person;
      case ConflictType.room:
        return Icons.room;
      case ConflictType.availability:
        return Icons.event_busy;
    }
  }

  String _getConflictSeverityLabel(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.high:
        return 'גבוה';
      case ConflictSeverity.medium:
        return 'בינוני';
      case ConflictSeverity.low:
        return 'נמוך';
    }
  }
}

// Supporting classes
enum ConflictType { timeSlot, instructor, room, availability }

enum ConflictSeverity { high, medium, low }

class ConflictInfo {
  final ConflictType type;
  final ConflictSeverity severity;
  final String title;
  final String description;
  final List<String> suggestions;

  const ConflictInfo({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.suggestions = const [],
  });
}
