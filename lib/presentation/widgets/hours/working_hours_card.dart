import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/models/working_hours.dart';
import '../../providers/working_hours_providers.dart';
import 'hours_dashboard_screen.dart';
import 'log_hours_screen.dart';

class WorkingHoursCard extends ConsumerWidget {
  final User user;

  const WorkingHoursCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(workingHoursStatsProvider(user.id));

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8b5cf6), Color(0xFF7c3aed)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8b5cf6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToHoursDashboard(context),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'שעות עבודה',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _navigateToLogHours(context),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats content
                statsAsync.when(
                  data: (stats) => _buildStatsContent(stats),
                  loading: () => _buildLoadingContent(),
                  error: (error, stack) => _buildErrorContent(),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'רשום שעות',
                        Icons.add,
                        () => _navigateToLogHours(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        'צפה בהכל',
                        Icons.visibility,
                        () => _navigateToHoursDashboard(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContent(WorkingHoursStats stats) {
    return Column(
      children: [
        // Weekly progress
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'השבוע: ${stats.totalHoursThisWeek}/${stats.weeklyTarget.toInt()}ש\'',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: stats.weeklyProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stats.weeklyTargetMet
                    ? Colors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                stats.weeklyTargetMet ? 'הושלם' : 'בתהליך',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status summary
        Row(
          children: [
            _buildStatChip(
              'ממתין',
              stats.pendingHours.toString(),
              Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              'אושר',
              stats.approvedHours.toString(),
              Colors.green,
            ),
            if (stats.rejectedHours > 0) ...[
              const SizedBox(width: 8),
              _buildStatChip(
                'נדחה',
                stats.rejectedHours.toString(),
                Colors.red,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return const SizedBox(
      height: 60,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return const SizedBox(
      height: 60,
      child: Center(
        child: Text(
          'שגיאה בטעינת נתונים',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHoursDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HoursDashboardScreen(user: user)),
    );
  }

  void _navigateToLogHours(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LogHoursScreen(user: user)),
    );
  }
}
