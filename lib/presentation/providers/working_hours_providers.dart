import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/working_hours.dart';
import '../../data/repositories/working_hours_repository.dart';
import '../../config/service_locator.dart';

// Repository provider
final workingHoursRepositoryProvider = Provider<WorkingHoursRepository>((ref) {
  return serviceLocator<WorkingHoursRepository>();
});

// Working hours stream for a specific mentor
final workingHoursProvider = StreamProvider.family<List<WorkingHours>, String>((
  ref,
  mentorId,
) {
  final repository = ref.watch(workingHoursRepositoryProvider);

  // Convert Future to Stream for real-time updates
  return Stream.periodic(
    const Duration(seconds: 30),
    (_) => repository.getWorkingHoursForMentor(mentorId),
  ).asyncMap((future) => future).handleError((error) {
    print('Error in working hours stream: $error');
    return <WorkingHours>[];
  });
});

// Working hours statistics provider
final workingHoursStatsProvider =
    FutureProvider.family<WorkingHoursStats, String>((ref, mentorId) async {
      final repository = ref.watch(workingHoursRepositoryProvider);
      return repository.getWorkingHoursStats(mentorId);
    });

// All working hours for staff (admin view)
final allWorkingHoursProvider = StreamProvider<List<WorkingHours>>((ref) {
  final repository = ref.watch(workingHoursRepositoryProvider);

  // Create a stream that fetches data immediately and then every 15 seconds
  return Stream<dynamic>.multi((controller) async {
    controller.add(null); // Emit immediately
    await for (var _ in Stream.periodic(const Duration(seconds: 15))) {
      controller.add(null);
    }
  }).asyncMap((_) async {
    try {
      print('🔄 PROVIDER: Fetching all working hours...');
      final hours = await repository.getAllWorkingHours();
      print('🔄 PROVIDER: Fetched ${hours.length} working hours');

      for (var hour in hours) {
        print('🔄 PROVIDER: Hour - ${hour.mentorName} (${hour.status})');
      }

      return hours;
    } catch (e) {
      print('❌ PROVIDER ERROR: $e');
      return <WorkingHours>[];
    }
  });
});

// Update pending hours provider to use the stream
final pendingWorkingHoursProvider = Provider<AsyncValue<List<WorkingHours>>>((
  ref,
) {
  final allHoursAsync = ref.watch(allWorkingHoursProvider);

  return allHoursAsync.when(
    data: (allHours) => AsyncValue.data(
      allHours
          .where((hours) => hours.status == WorkingHoursStatus.pending)
          .toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Working hours actions provider
final workingHoursActionsProvider = Provider<WorkingHoursActions>((ref) {
  final repository = ref.watch(workingHoursRepositoryProvider);
  return WorkingHoursActions(repository, ref);
});

// Actions class for working hours operations
class WorkingHoursActions {
  final WorkingHoursRepository _repository;
  final Ref _ref;

  WorkingHoursActions(this._repository, this._ref);

  Future<String> addWorkingHours(WorkingHours workingHours) async {
    final result = await _repository.addWorkingHours(workingHours);
    // Invalidate relevant providers to refresh UI
    _ref.invalidate(workingHoursProvider);
    _ref.invalidate(workingHoursStatsProvider);
    _ref.invalidate(allWorkingHoursProvider);
    _ref.invalidate(pendingWorkingHoursProvider);
    return result;
  }

  Future<bool> approveWorkingHours(
    String workingHoursId,
    String approvedBy,
  ) async {
    final result = await _repository.approveWorkingHours(
      workingHoursId,
      approvedBy,
    );
    if (result) {
      // Invalidate providers to refresh UI
      _ref.invalidate(workingHoursProvider);
      _ref.invalidate(allWorkingHoursProvider);
      _ref.invalidate(pendingWorkingHoursProvider);
    }
    return result;
  }

  Future<bool> rejectWorkingHours(
    String workingHoursId,
    String rejectedBy,
    String reason,
  ) async {
    final result = await _repository.rejectWorkingHours(
      workingHoursId,
      rejectedBy,
      reason,
    );
    if (result) {
      // Invalidate providers to refresh UI
      _ref.invalidate(workingHoursProvider);
      _ref.invalidate(allWorkingHoursProvider);
      _ref.invalidate(pendingWorkingHoursProvider);
    }
    return result;
  }

  Future<bool> bulkApproveWorkingHours(
    List<String> workingHoursIds,
    String approvedBy,
  ) async {
    final result = await _repository.bulkApproveWorkingHours(
      workingHoursIds,
      approvedBy,
    );
    if (result) {
      // Invalidate providers to refresh UI
      _ref.invalidate(workingHoursProvider);
      _ref.invalidate(allWorkingHoursProvider);
      _ref.invalidate(pendingWorkingHoursProvider);
    }
    return result;
  }
}
