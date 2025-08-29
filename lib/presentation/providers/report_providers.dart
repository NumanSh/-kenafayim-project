import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/config/service_locator.dart';
import 'package:knafayim_app/data/models/report.dart';
import 'package:knafayim_app/data/repositories/report_repository.dart';

// Report Repository Provider
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return serviceLocator<ReportRepository>();
});

// Reports List Provider
final reportsProvider = FutureProvider.family<List<Report>, ReportType>((
  ref,
  type,
) async {
  final repository = ref.read(reportRepositoryProvider);
  return repository.getReports(type: type);
});

// Analytics Data Providers
final workingHoursAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, DateRange>((
      ref,
      dateRange,
    ) async {
      final repository = ref.read(reportRepositoryProvider);
      return repository.generateWorkingHoursAnalytics(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );
    });

final attendanceAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, DateRange>((
      ref,
      dateRange,
    ) async {
      final repository = ref.read(reportRepositoryProvider);
      return repository.generateAttendanceAnalytics(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );
    });

final userActivityAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, DateRange>((
      ref,
      dateRange,
    ) async {
      final repository = ref.read(reportRepositoryProvider);
      return repository.generateUserActivityAnalytics(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );
    });

// Helper class for date range
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
