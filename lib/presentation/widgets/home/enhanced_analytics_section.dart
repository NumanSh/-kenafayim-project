import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/report.dart';
import '../../../data/models/user.dart';
import '../analytics/real_time_analytics_widget.dart';
import '../../screens/reports/analytics_dashboard_screen.dart';

class EnhancedAnalyticsSection extends ConsumerWidget {
  final User user;

  const EnhancedAnalyticsSection({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        const SizedBox(height: 16),
        _buildAnalyticsGrid(context),
        const SizedBox(height: 16),
        _buildQuickInsights(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          'ניתוחים בזמן אמת',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _navigateToFullAnalytics(context),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('צפה בהכל'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF3b82f6)),
        ),
      ],
    );
  }

  Widget _buildAnalyticsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (screenWidth > 800) {
          // Desktop/Tablet - 3 columns
          return Row(
            children: [
              Expanded(
                child: RealTimeAnalyticsWidget(
                  title: 'נוכחות אמנים',
                  analyticsType: ReportType.attendance,
                  primaryColor: const Color(0xFF10b981),
                  onTap: () =>
                      _navigateToAnalytics(context, ReportType.attendance),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RealTimeAnalyticsWidget(
                  title: 'שעות מנחים',
                  analyticsType: ReportType.workingHours,
                  primaryColor: const Color(0xFF3b82f6),
                  onTap: () =>
                      _navigateToAnalytics(context, ReportType.workingHours),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RealTimeAnalyticsWidget(
                  title: 'פעילות כללית',
                  analyticsType: ReportType.userActivity,
                  primaryColor: const Color(0xFFf59e0b),
                  showChart: false,
                  onTap: () =>
                      _navigateToAnalytics(context, ReportType.userActivity),
                ),
              ),
            ],
          );
        } else if (screenWidth > 600) {
          // Tablet - 2 columns
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: RealTimeAnalyticsWidget(
                      title: 'נוכחות אמנים',
                      analyticsType: ReportType.attendance,
                      primaryColor: const Color(0xFF10b981),
                      onTap: () =>
                          _navigateToAnalytics(context, ReportType.attendance),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RealTimeAnalyticsWidget(
                      title: 'שעות מנחים',
                      analyticsType: ReportType.workingHours,
                      primaryColor: const Color(0xFF3b82f6),
                      onTap: () => _navigateToAnalytics(
                        context,
                        ReportType.workingHours,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RealTimeAnalyticsWidget(
                title: 'פעילות כללית',
                analyticsType: ReportType.userActivity,
                primaryColor: const Color(0xFFf59e0b),
                showChart: false,
                onTap: () =>
                    _navigateToAnalytics(context, ReportType.userActivity),
              ),
            ],
          );
        } else {
          // Mobile - 1 column
          return Column(
            children: [
              RealTimeAnalyticsWidget(
                title: 'נוכחות אמנים',
                analyticsType: ReportType.attendance,
                primaryColor: const Color(0xFF10b981),
                onTap: () =>
                    _navigateToAnalytics(context, ReportType.attendance),
              ),
              const SizedBox(height: 16),
              RealTimeAnalyticsWidget(
                title: 'שעות מנחים',
                analyticsType: ReportType.workingHours,
                primaryColor: const Color(0xFF3b82f6),
                showChart: false,
                onTap: () =>
                    _navigateToAnalytics(context, ReportType.workingHours),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildQuickInsights(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3b82f6).withOpacity(0.1),
            const Color(0xFF10b981).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFF3b82f6),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'תובנות חכמות',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '📈 נוכחות השבוע עלתה ב-12% לעומת השבוע הקודם',
            const Color(0xFF10b981),
          ),
          const SizedBox(height: 8),
          _buildInsightItem(
            '⏰ שעות המנחים יציבות - ממוצע 8.5 שעות ליום',
            const Color(0xFF3b82f6),
          ),
          const SizedBox(height: 8),
          _buildInsightItem(
            '🎯 85% מהאמנים השתתפו בלפחות 3 שיעורים השבוע',
            const Color(0xFFf59e0b),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4b5563),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToAnalytics(BuildContext context, ReportType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AnalyticsDashboardScreen(user: user, reportType: type),
      ),
    );
  }

  void _navigateToFullAnalytics(BuildContext context) {
    // Navigate to main reports screen
    Navigator.pushNamed(context, '/reports');
  }
}
