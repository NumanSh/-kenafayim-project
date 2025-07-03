import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/data/models/report.dart';
import '../widgets/reports/advanced_filter_panel.dart';

// Filter state provider
final filterCriteriaProvider = StateProvider<FilterCriteria>((ref) {
  return const FilterCriteria();
});

// Filtered reports provider
final filteredReportsProvider = Provider.family<List<Report>, List<Report>>((
  ref,
  reports,
) {
  final filters = ref.watch(filterCriteriaProvider);

  if (!filters.hasActiveFilters) {
    return reports;
  }

  var filtered = reports;

  // Apply date range filter
  if (filters.dateRange != null) {
    filtered = filtered.where((report) {
      return report.createdAt.isAfter(filters.dateRange!.start) &&
          report.createdAt.isBefore(filters.dateRange!.end);
    }).toList();
  }

  // Apply search query filter
  if (filters.searchQuery?.isNotEmpty ?? false) {
    final query = filters.searchQuery!.toLowerCase();
    filtered = filtered.where((report) {
      return report.title.toLowerCase().contains(query) ||
          report.content.toLowerCase().contains(query) ||
          report.createdByName.toLowerCase().contains(query);
    }).toList();
  }

  // Apply report type filters
  if (filters.reportTypes.isNotEmpty) {
    filtered = filtered.where((report) {
      return filters.reportTypes.contains(report.type);
    }).toList();
  }

  return filtered;
});
