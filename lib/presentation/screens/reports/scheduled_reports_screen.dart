import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/report.dart';
import '../../../data/models/user.dart';
import '../../../services/report_scheduler_service.dart';
import '../../../config/service_locator.dart';

class ScheduledReportsScreen extends ConsumerStatefulWidget {
  final User user;

  const ScheduledReportsScreen({super.key, required this.user});

  @override
  ConsumerState<ScheduledReportsScreen> createState() =>
      _ScheduledReportsScreenState();
}

class _ScheduledReportsScreenState
    extends ConsumerState<ScheduledReportsScreen> {
  final ReportSchedulerService _schedulerService =
      serviceLocator<ReportSchedulerService>();
  List<ScheduledReport> _scheduledReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledReports();
  }

  Future<void> _loadScheduledReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _schedulerService.getScheduledReports();
      if (mounted) {
        setState(() {
          _scheduledReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת דוחות מתוזמנים: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          'דוחות מתוזמנים',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadScheduledReports,
            icon: const Icon(Icons.refresh, color: Color(0xFF3b82f6)),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateScheduledReportDialog,
        backgroundColor: const Color(0xFF3b82f6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.schedule),
        label: const Text('תזמן דוח חדש'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3b82f6)),
          ),
          SizedBox(height: 16),
          Text(
            'טוען דוחות מתוזמנים...',
            style: TextStyle(fontSize: 16, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_scheduledReports.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildScheduledReportsList(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final activeReports = _scheduledReports.where((r) => r.isActive).length;
    final nextReport = _scheduledReports
        .where((r) => r.isActive)
        .fold<ScheduledReport?>(null, (prev, curr) {
          if (prev == null) return curr;
          return curr.nextRun.isBefore(prev.nextRun) ? curr : prev;
        });

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'דוחות פעילים',
            '$activeReports',
            Icons.schedule,
            const Color(0xFF10b981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'הדוח הבא',
            nextReport != null
                ? DateFormat('dd/MM HH:mm').format(nextReport.nextRun)
                : 'אין',
            Icons.access_time,
            const Color(0xFF3b82f6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledReportsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'דוחות מתוזמנים',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1f2937),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _scheduledReports.length,
          itemBuilder: (context, index) {
            final report = _scheduledReports[index];
            return _buildScheduledReportCard(report);
          },
        ),
      ],
    );
  }

  Widget _buildScheduledReportCard(ScheduledReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: _getReportTypeColor(
                      report.reportType,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getReportTypeIcon(report.reportType),
                    color: _getReportTypeColor(report.reportType),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Text(
                        _getFrequencyDisplayName(report.frequency),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: report.isActive,
                  onChanged: (value) => _toggleReportActive(report, value),
                  activeColor: const Color(0xFF10b981),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  'הרצה הבאה',
                  DateFormat('dd/MM/yyyy HH:mm').format(report.nextRun),
                  Icons.schedule,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  'נמענים',
                  '${report.recipientIds.length}',
                  Icons.people,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _triggerReportNow(report),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('הרץ עכשיו'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3b82f6),
                      side: const BorderSide(color: Color(0xFF3b82f6)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editScheduledReport(report),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('ערוך'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6b7280),
                      side: const BorderSide(color: Color(0xFFe5e7eb)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _deleteScheduledReport(report),
                  icon: const Icon(Icons.delete_outline),
                  color: const Color(0xFFef4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFf3f4f6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6b7280)),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: const Color(0xFF6b7280).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'אין דוחות מתוזמנים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6b7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'צור דוח מתוזמן חדש כדי לקבל דוחות אוטומטיים',
            style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getReportTypeColor(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return const Color(0xFF10b981);
      case ReportType.workingHours:
        return const Color(0xFF3b82f6);
      case ReportType.userActivity:
        return const Color(0xFFf59e0b);
      case ReportType.financial:
        return const Color(0xFFef4444);
      default:
        return const Color(0xFF6b7280);
    }
  }

  IconData _getReportTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return Icons.people;
      case ReportType.workingHours:
        return Icons.access_time;
      case ReportType.userActivity:
        return Icons.analytics;
      case ReportType.financial:
        return Icons.attach_money;
      default:
        return Icons.description;
    }
  }

  String _getFrequencyDisplayName(ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.daily:
        return 'יומי';
      case ScheduleFrequency.weekly:
        return 'שבועי';
      case ScheduleFrequency.monthly:
        return 'חודשי';
      case ScheduleFrequency.quarterly:
        return 'רבעוני';
    }
  }

  // Action methods
  void _showCreateScheduledReportDialog() {
    // Implementation for creating new scheduled report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('יצירת דוח מתוזמן חדש תהיה זמינה בקרוב'),
        backgroundColor: Color(0xFF3b82f6),
      ),
    );
  }

  void _toggleReportActive(ScheduledReport report, bool isActive) {
    // Implementation for toggling report active state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isActive ? 'הדוח הופעל' : 'הדוח הושבת'),
        backgroundColor: const Color(0xFF10b981),
      ),
    );
  }

  Future<void> _triggerReportNow(ScheduledReport report) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('מפעיל דוח...'),
            ],
          ),
          backgroundColor: Color(0xFF3b82f6),
        ),
      );

      await _schedulerService.triggerReport(report.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הדוח הופעל בהצלחה!'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהפעלת הדוח: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  void _editScheduledReport(ScheduledReport report) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('עריכת דוח מתוזמן תהיה זמינה בקרוב'),
        backgroundColor: Color(0xFF6b7280),
      ),
    );
  }

  void _deleteScheduledReport(ScheduledReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת דוח מתוזמן'),
        content: Text('האם אתה בטוח שברצונך למחוק את "${report.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _schedulerService.deleteScheduledReport(report.id);
              _loadScheduledReports();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('הדוח המתוזמן נמחק בהצלחה'),
                    backgroundColor: Color(0xFF10b981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }
}
