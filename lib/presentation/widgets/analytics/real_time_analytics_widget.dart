import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/report.dart';
import '../../../presentation/providers/report_providers.dart';

class RealTimeAnalyticsWidget extends ConsumerStatefulWidget {
  final String title;
  final ReportType analyticsType;
  final Color primaryColor;
  final bool showChart;
  final VoidCallback? onTap;

  const RealTimeAnalyticsWidget({
    super.key,
    required this.title,
    required this.analyticsType,
    required this.primaryColor,
    this.showChart = true,
    this.onTap,
  });

  @override
  ConsumerState<RealTimeAnalyticsWidget> createState() =>
      _RealTimeAnalyticsWidgetState();
}

class _RealTimeAnalyticsWidgetState
    extends ConsumerState<RealTimeAnalyticsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateRange = DateRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: widget.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildContent(dateRange),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForType(widget.analyticsType),
            color: widget.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
              Text(
                'עדכון אחרון: ${DateFormat('HH:mm').format(DateTime.now())}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10b981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10b981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'חי',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10b981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(DateRange dateRange) {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsAsync = _getAnalyticsProvider(ref, dateRange);

        return analyticsAsync.when(
          data: (data) => _buildAnalyticsContent(data),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  AsyncValue<Map<String, dynamic>> _getAnalyticsProvider(
    WidgetRef ref,
    DateRange dateRange,
  ) {
    switch (widget.analyticsType) {
      case ReportType.attendance:
        return ref.watch(attendanceAnalyticsProvider(dateRange));
      case ReportType.workingHours:
        return ref.watch(workingHoursAnalyticsProvider(dateRange));
      case ReportType.userActivity:
        return ref.watch(userActivityAnalyticsProvider(dateRange));
      default:
        return ref.watch(workingHoursAnalyticsProvider(dateRange));
    }
  }

  Widget _buildAnalyticsContent(Map<String, dynamic> data) {
    final mainMetric = _getMainMetric(data);
    final trend = _calculateTrend(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              mainMetric['value'],
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                mainMetric['unit'],
                style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
              ),
            ),
            const Spacer(),
            _buildTrendIndicator(trend),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          mainMetric['subtitle'],
          style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
        ),
        if (widget.showChart) ...[
          const SizedBox(height: 16),
          _buildMiniChart(data),
        ],
      ],
    );
  }

  Widget _buildTrendIndicator(Map<String, dynamic> trend) {
    final isPositive = trend['isPositive'] as bool;
    final value = trend['value'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444))
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: isPositive
                ? const Color(0xFF10b981)
                : const Color(0xFFef4444),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive
                  ? const Color(0xFF10b981)
                  : const Color(0xFFef4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(Map<String, dynamic> data) {
    return SizedBox(
      height: 60,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _generateChartSpots(data),
              isCurved: true,
              color: widget.primaryColor,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: widget.primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Spacer(),
            Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        if (widget.showChart) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Column(
      children: [
        Icon(Icons.error_outline, color: Colors.red[400], size: 32),
        const SizedBox(height: 8),
        Text(
          'שגיאה בטעינת נתונים',
          style: TextStyle(fontSize: 14, color: Colors.red[600]),
        ),
      ],
    );
  }

  // Helper methods
  IconData _getIconForType(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return Icons.people;
      case ReportType.workingHours:
        return Icons.access_time;
      case ReportType.userActivity:
        return Icons.analytics;
      default:
        return Icons.assessment;
    }
  }

  Map<String, dynamic> _getMainMetric(Map<String, dynamic> data) {
    switch (widget.analyticsType) {
      case ReportType.attendance:
        return {
          'value': '${data['attendanceRate']?.toStringAsFixed(1) ?? '0'}%',
          'unit': '',
          'subtitle': 'אחוז נוכחות השבוע',
        };
      case ReportType.workingHours:
        return {
          'value': '${data['totalHours']?.toStringAsFixed(1) ?? '0'}',
          'unit': 'שעות',
          'subtitle': 'שעות עבודה השבוע',
        };
      case ReportType.userActivity:
        return {
          'value': '${data['activeUsers'] ?? 0}',
          'unit': 'משתמשים',
          'subtitle': 'משתמשים פעילים',
        };
      default:
        return {'value': '0', 'unit': '', 'subtitle': 'אין נתונים'};
    }
  }

  Map<String, dynamic> _calculateTrend(Map<String, dynamic> data) {
    // Simple trend calculation - in real implementation, compare with previous period
    final random = DateTime.now().millisecond % 100;
    final isPositive = random > 30;
    final value = '${(random % 20) + 1}%';

    return {'isPositive': isPositive, 'value': value};
  }

  List<FlSpot> _generateChartSpots(Map<String, dynamic> data) {
    // Generate sample chart data - in real implementation, use historical data
    final spots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      final value = (DateTime.now().millisecond + i * 10) % 100;
      spots.add(FlSpot(i.toDouble(), value.toDouble()));
    }
    return spots;
  }
}
