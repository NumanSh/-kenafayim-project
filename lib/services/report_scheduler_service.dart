import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/models/report.dart';
import '../data/models/user.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/user_repository.dart';
import '../config/service_locator.dart';
import 'report_generation_service.dart';

enum ScheduleFrequency { daily, weekly, monthly, quarterly }

class ScheduledReport {
  final String id;
  final String name;
  final ReportType reportType;
  final ScheduleFrequency frequency;
  final DateTime nextRun;
  final List<String> recipientIds;
  final Map<String, dynamic> filters;
  final bool isActive;
  final String createdById;
  final DateTime createdAt;

  ScheduledReport({
    required this.id,
    required this.name,
    required this.reportType,
    required this.frequency,
    required this.nextRun,
    required this.recipientIds,
    this.filters = const {},
    this.isActive = true,
    required this.createdById,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'reportType': reportType.toString().split('.').last,
      'frequency': frequency.toString().split('.').last,
      'nextRun': nextRun.millisecondsSinceEpoch,
      'recipientIds': recipientIds,
      'filters': filters,
      'isActive': isActive,
      'createdById': createdById,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ScheduledReport.fromMap(Map<String, dynamic> map) {
    return ScheduledReport(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      reportType: _parseReportType(map['reportType'] ?? 'workingHours'),
      frequency: _parseFrequency(map['frequency'] ?? 'weekly'),
      nextRun: DateTime.fromMillisecondsSinceEpoch(map['nextRun'] ?? 0),
      recipientIds: List<String>.from(map['recipientIds'] ?? []),
      filters: Map<String, dynamic>.from(map['filters'] ?? {}),
      isActive: map['isActive'] ?? true,
      createdById: map['createdById'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  static ReportType _parseReportType(String type) {
    switch (type) {
      case 'attendance':
        return ReportType.attendance;
      case 'workingHours':
        return ReportType.workingHours;
      case 'userActivity':
        return ReportType.userActivity;
      case 'financial':
        return ReportType.financial;
      default:
        return ReportType.workingHours;
    }
  }

  static ScheduleFrequency _parseFrequency(String frequency) {
    switch (frequency) {
      case 'daily':
        return ScheduleFrequency.daily;
      case 'weekly':
        return ScheduleFrequency.weekly;
      case 'monthly':
        return ScheduleFrequency.monthly;
      case 'quarterly':
        return ScheduleFrequency.quarterly;
      default:
        return ScheduleFrequency.weekly;
    }
  }

  ScheduledReport copyWith({
    String? id,
    String? name,
    ReportType? reportType,
    ScheduleFrequency? frequency,
    DateTime? nextRun,
    List<String>? recipientIds,
    Map<String, dynamic>? filters,
    bool? isActive,
    String? createdById,
    DateTime? createdAt,
  }) {
    return ScheduledReport(
      id: id ?? this.id,
      name: name ?? this.name,
      reportType: reportType ?? this.reportType,
      frequency: frequency ?? this.frequency,
      nextRun: nextRun ?? this.nextRun,
      recipientIds: recipientIds ?? this.recipientIds,
      filters: filters ?? this.filters,
      isActive: isActive ?? this.isActive,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReportSchedulerService {
  final ReportRepository _reportRepository = serviceLocator<ReportRepository>();
  final ReportGenerationService _reportService =
      serviceLocator<ReportGenerationService>();
  final UserRepository _userRepository = serviceLocator<UserRepository>();

  Timer? _schedulerTimer;
  final List<ScheduledReport> _scheduledReports = [];

  // Initialize the scheduler
  void initialize() {
    _loadScheduledReports();
    _startScheduler();
  }

  // Start the scheduler timer
  void _startScheduler() {
    _schedulerTimer?.cancel();

    // Check every hour for reports to run
    _schedulerTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkAndRunScheduledReports();
    });

    debugPrint('📅 Report Scheduler initialized - checking every hour');
  }

  // Load scheduled reports from storage
  Future<void> _loadScheduledReports() async {
    try {
      // In a real implementation, load from Firestore
      // For now, we'll use sample data
      _scheduledReports.clear();

      final sampleReports = [
        ScheduledReport(
          id: 'weekly_attendance',
          name: 'דוח נוכחות שבועי',
          reportType: ReportType.attendance,
          frequency: ScheduleFrequency.weekly,
          nextRun: _getNextWeeklyRun(),
          recipientIds: ['staff_manager_id'],
          createdById: 'system',
          createdAt: DateTime.now(),
        ),
        ScheduledReport(
          id: 'monthly_summary',
          name: 'סיכום חודשי',
          reportType: ReportType.workingHours,
          frequency: ScheduleFrequency.monthly,
          nextRun: _getNextMonthlyRun(),
          recipientIds: ['director_id', 'admin_id'],
          createdById: 'system',
          createdAt: DateTime.now(),
        ),
      ];

      _scheduledReports.addAll(sampleReports);
      debugPrint('📊 Loaded ${_scheduledReports.length} scheduled reports');
    } catch (e) {
      debugPrint('❌ Error loading scheduled reports: $e');
    }
  }

  // Check and run any due reports
  Future<void> _checkAndRunScheduledReports() async {
    final now = DateTime.now();

    for (final scheduledReport in _scheduledReports) {
      if (scheduledReport.isActive && now.isAfter(scheduledReport.nextRun)) {
        await _runScheduledReport(scheduledReport);
      }
    }
  }

  // Execute a scheduled report
  Future<void> _runScheduledReport(ScheduledReport scheduledReport) async {
    try {
      debugPrint('🚀 Running scheduled report: ${scheduledReport.name}');

      // Calculate date range based on frequency
      final dateRange = _getDateRangeForFrequency(scheduledReport.frequency);

      // Generate the report
      final reportFile = await _reportService.generatePDFReport(
        title: scheduledReport.name,
        content: 'דוח אוטומטי - ${scheduledReport.name}',
        reportType: scheduledReport.reportType,
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
        createdByName: 'מערכת אוטומטית',
      );

      // Send to recipients (in real implementation)
      await _sendReportToRecipients(scheduledReport, reportFile);

      // Update next run time
      final updatedReport = scheduledReport.copyWith(
        nextRun: _calculateNextRun(scheduledReport.frequency),
      );

      // Update in storage
      await _updateScheduledReport(updatedReport);

      debugPrint(
        '✅ Successfully completed scheduled report: ${scheduledReport.name}',
      );
    } catch (e) {
      debugPrint(
        '❌ Error running scheduled report ${scheduledReport.name}: $e',
      );
    }
  }

  // Send report to recipients
  Future<void> _sendReportToRecipients(
    ScheduledReport scheduledReport,
    File reportFile,
  ) async {
    try {
      // In a real implementation, this would:
      // 1. Get recipient email addresses
      // 2. Send email with report attachment
      // 3. Create in-app notifications

      debugPrint(
        '📧 Sending report to ${scheduledReport.recipientIds.length} recipients',
      );

      // For now, just log the action
      for (final recipientId in scheduledReport.recipientIds) {
        debugPrint('   📨 Sent to recipient: $recipientId');
      }

      // Simulate email sending delay
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('❌ Error sending report: $e');
    }
  }

  // Calculate date range based on frequency
  Map<String, DateTime> _getDateRangeForFrequency(ScheduleFrequency frequency) {
    final now = DateTime.now();

    switch (frequency) {
      case ScheduleFrequency.daily:
        return {
          'start': DateTime(now.year, now.month, now.day - 1),
          'end': DateTime(now.year, now.month, now.day),
        };

      case ScheduleFrequency.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return {
          'start': DateTime(weekStart.year, weekStart.month, weekStart.day - 7),
          'end': DateTime(weekStart.year, weekStart.month, weekStart.day),
        };

      case ScheduleFrequency.monthly:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final thisMonth = DateTime(now.year, now.month, 1);
        return {'start': lastMonth, 'end': thisMonth};

      case ScheduleFrequency.quarterly:
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final quarterStart = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        final lastQuarterStart = DateTime(now.year, (quarter - 2) * 3 + 1, 1);
        return {'start': lastQuarterStart, 'end': quarterStart};
    }
  }

  // Calculate next run time
  DateTime _calculateNextRun(ScheduleFrequency frequency) {
    final now = DateTime.now();

    switch (frequency) {
      case ScheduleFrequency.daily:
        return DateTime(
          now.year,
          now.month,
          now.day + 1,
          9,
          0,
        ); // 9 AM next day

      case ScheduleFrequency.weekly:
        final nextWeek = now.add(const Duration(days: 7));
        return DateTime(
          nextWeek.year,
          nextWeek.month,
          nextWeek.day,
          9,
          0,
        ); // 9 AM next week

      case ScheduleFrequency.monthly:
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return DateTime(
          nextMonth.year,
          nextMonth.month,
          1,
          9,
          0,
        ); // 9 AM first of next month

      case ScheduleFrequency.quarterly:
        final nextQuarter = DateTime(now.year, now.month + 3, 1);
        return DateTime(
          nextQuarter.year,
          nextQuarter.month,
          1,
          9,
          0,
        ); // 9 AM first of next quarter
    }
  }

  // Helper methods for initial scheduling
  DateTime _getNextWeeklyRun() {
    final now = DateTime.now();
    final nextMonday = now.add(Duration(days: 8 - now.weekday));
    return DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 9, 0);
  }

  DateTime _getNextMonthlyRun() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return DateTime(nextMonth.year, nextMonth.month, 1, 9, 0);
  }

  // CRUD operations for scheduled reports
  Future<String> createScheduledReport(ScheduledReport report) async {
    try {
      _scheduledReports.add(report);
      // In real implementation, save to Firestore
      debugPrint('✅ Created scheduled report: ${report.name}');
      return report.id;
    } catch (e) {
      debugPrint('❌ Error creating scheduled report: $e');
      rethrow;
    }
  }

  Future<void> _updateScheduledReport(ScheduledReport report) async {
    try {
      final index = _scheduledReports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _scheduledReports[index] = report;
        // In real implementation, update in Firestore
      }
    } catch (e) {
      debugPrint('❌ Error updating scheduled report: $e');
    }
  }

  Future<void> deleteScheduledReport(String reportId) async {
    try {
      _scheduledReports.removeWhere((r) => r.id == reportId);
      // In real implementation, delete from Firestore
      debugPrint('🗑️ Deleted scheduled report: $reportId');
    } catch (e) {
      debugPrint('❌ Error deleting scheduled report: $e');
    }
  }

  Future<List<ScheduledReport>> getScheduledReports() async {
    return List.from(_scheduledReports);
  }

  // Manual trigger for testing
  Future<void> triggerReport(String reportId) async {
    final report = _scheduledReports.firstWhere((r) => r.id == reportId);
    await _runScheduledReport(report);
  }

  // Cleanup
  void dispose() {
    _schedulerTimer?.cancel();
    debugPrint('🛑 Report Scheduler disposed');
  }
}
