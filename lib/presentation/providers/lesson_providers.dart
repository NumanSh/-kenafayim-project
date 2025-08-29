// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knafayim_app/data/repositories/user_repository.dart';
import 'package:knafayim_app/services/notification_integration_service.dart'
    show NotificationIntegrationService;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/lesson.dart';
import '../../data/models/user.dart';
import '../../data/repositories/unified_calendar_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../config/service_locator.dart';

part 'lesson_providers.g.dart';

// Repository Providers
@riverpod
UnifiedCalendarRepository unifiedCalendarRepository(
  UnifiedCalendarRepositoryRef ref,
) {
  return serviceLocator<UnifiedCalendarRepository>();
}

@riverpod
LessonRepository lessonRepository(LessonRepositoryRef ref) {
  return serviceLocator<LessonRepository>();
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return serviceLocator<UserRepository>();
}

// ✅ FIXED: Real-time lessons stream provider with proper filtering
@riverpod
Stream<List<Lesson>> lessonsStream(
  LessonsStreamRef ref,
  String userId,
  UserRole userRole,
) {
  final firestore = FirebaseFirestore.instance;

  Query query;

  switch (userRole) {
    case UserRole.staff:
      // ✅ Staff can see ALL lessons (no filtering)
      query = firestore
          .collection('lessons')
          .orderBy('date', descending: false);
      break;
    case UserRole.mentor:
      // ✅ Mentors see all lessons (they can teach any lesson)
      query = firestore
          .collection('lessons')
          .orderBy('date', descending: false);
      break;
    case UserRole.client:
      // ✅ Clients see lessons they're registered for
      query = firestore
          .collection('lessons')
          .where('registeredArtistIds', arrayContains: userId)
          .orderBy('date', descending: false);
      break;
  }

  return query.snapshots().map((snapshot) {
    print(
      '🔍 STREAM DEBUG ($userRole): Found ${snapshot.docs.length} lessons in Firestore',
    );

    final lessons = snapshot.docs
        .where((doc) => !doc.metadata.hasPendingWrites)
        .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            print(
              '🔍 STREAM: Processing "${data['title']}" - Date: ${data['date']} (Type: ${data['date'].runtimeType})',
            );

            return Lesson.fromMap({...data, 'id': doc.id});
          } catch (e) {
            print('❌ STREAM: Error parsing lesson ${doc.id}: $e');
            return null;
          }
        })
        .where((lesson) => lesson != null)
        .cast<Lesson>()
        .toList();

    print(
      '✅ STREAM: Successfully parsed ${lessons.length} lessons for $userRole',
    );
    for (int i = 0; i < lessons.length; i++) {
      print('   ${i + 1}. ${lessons[i].title} - ${lessons[i].date}');
    }

    return lessons;
  });
}

// ✅ ENHANCED: Stream for upcoming lessons only (for dashboard)
@riverpod
Stream<List<Lesson>> upcomingLessonsStream(
  UpcomingLessonsStreamRef ref,
  String userId,
  UserRole userRole,
) {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final weekAgo = now.subtract(
    const Duration(days: 7),
  ); // Show lessons from last week

  Query query;

  switch (userRole) {
    case UserRole.staff:
      query = firestore
          .collection('lessons')
          .where('date', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('date', descending: false)
          .limit(20);
      break;
    case UserRole.mentor:
      query = firestore
          .collection('lessons')
          .where('date', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('date', descending: false);
      break;
    case UserRole.client:
      query = firestore
          .collection('lessons')
          .where('registeredArtistIds', arrayContains: userId)
          .where('date', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('date', descending: false);
      break;
  }

  return query.snapshots().map((snapshot) {
    print(
      '🔍 UPCOMING DEBUG ($userRole): Found ${snapshot.docs.length} upcoming lessons',
    );

    return snapshot.docs
        .where((doc) => !doc.metadata.hasPendingWrites)
        .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            print(
              '🔍 UPCOMING: Processing "${data['title']}" with date: ${data['date']}',
            );

            return Lesson.fromMap({...data, 'id': doc.id});
          } catch (e) {
            print('❌ UPCOMING: Error parsing lesson ${doc.id}: $e');
            return null;
          }
        })
        .where((lesson) => lesson != null)
        .cast<Lesson>()
        .toList();
  });
}

// ✅ ENHANCED: Keep the existing LessonNotifier for backward compatibility
@riverpod
class LessonNotifier extends _$LessonNotifier {
  @override
  Future<List<Lesson>> build() async => [];

  Future<void> loadLessons(String userId, UserRole userRole) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(unifiedCalendarRepositoryProvider);
      final unifiedItems = await repository.getUnifiedCalendarItems(
        userId: userId,
        userRole: userRole,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 365)),
      );

      final lessons = unifiedItems
          .where((item) => item.isLesson && item.originalLesson != null)
          .map((item) => item.originalLesson!)
          .toList();

      state = AsyncValue.data(lessons);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // ✅ ENHANCED: Direct Firestore creation for real-time updates
  // Update your createLesson method:
  // Update your createLesson method:
  // Add this import at the top

  Future<void> createLesson({
    required String title,
    required DateTime date,
    required int durationMinutes,
    String? instructorName,
    String? instructorEmail,
    int? maxCapacity,
    List<String> registeredArtistIds = const [],
    String? backgroundImagePath, // ✅ ADD THIS PARAMETER
  }) async {
    try {
      // ✅ Use lesson repository directly for image support
      final lessonRepository = ref.read(lessonRepositoryProvider);

      final newLesson = await lessonRepository.addLesson(
        title: title,
        date: date,
        durationMinutes: durationMinutes,
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        maxCapacity: maxCapacity,
        registeredArtistIds: registeredArtistIds,
        backgroundImagePath: backgroundImagePath, // ✅ PASS THE IMAGE PATH
      );

      // ✅ ADD NOTIFICATION INTEGRATION

      // ✅ Update local state
      state = await AsyncValue.guard(() async {
        final currentLessons = state.value ?? [];
        final updatedLessons = [...currentLessons, newLesson];
        updatedLessons.sort((a, b) => a.date.compareTo(b.date));
        return updatedLessons;
      });

      if (kDebugMode) {
        print(
          "✅ Provider: Lesson created with image: ${newLesson.title} - Image: ${newLesson.backgroundImagePath}",
        );
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print("❌ Provider: Error creating lesson: $error");
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateLesson(Lesson updatedLesson) async {
    try {
      final repository = ref.read(lessonRepositoryProvider);
      final result = await repository.updateLessonDetails(updatedLesson);

      if (result != null) {
        state = await AsyncValue.guard(() async {
          final currentLessons = state.value ?? [];
          return currentLessons
              .map((lesson) => lesson.id == updatedLesson.id ? result : lesson)
              .toList();
        });

        if (kDebugMode) {
          print("✅ Provider state updated for lesson: ${result.title}");
        }
      } else {
        if (kDebugMode) {
          print("❌ Repository update failed, not updating provider state");
        }
        throw Exception('Failed to update lesson in repository');
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print("❌ Error in updateLesson: $error");
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete lesson with real-time updates
  Future<bool> deleteLesson(String lessonId) async {
    try {
      // ✅ Use unified repository for better integration
      final unifiedRepository = ref.read(unifiedCalendarRepositoryProvider);

      final success = await unifiedRepository.deleteLesson(lessonId);

      if (success) {
        // ✅ Update local state immediately
        state = await AsyncValue.guard(() async {
          final currentLessons = state.value ?? [];
          final updatedLessons = currentLessons
              .where((lesson) => lesson.id != lessonId)
              .toList();
          updatedLessons.sort((a, b) => a.date.compareTo(b.date));
          return updatedLessons;
        });

        if (kDebugMode) {
          print("✅ Provider: Lesson deleted via unified repository: $lessonId");
        }

        return true;
      }

      return false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print("❌ Provider: Error deleting lesson: $error");
      }
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Delete multiple lessons (for series)
  Future<bool> deleteLessonSeries(List<String> lessonIds) async {
    try {
      // ✅ Use unified repository for better integration
      final unifiedRepository = ref.read(unifiedCalendarRepositoryProvider);

      final success = await unifiedRepository.deleteLessonSeries(lessonIds);

      if (success) {
        // ✅ Update local state immediately
        state = await AsyncValue.guard(() async {
          final currentLessons = state.value ?? [];
          final updatedLessons = currentLessons
              .where((lesson) => !lessonIds.contains(lesson.id))
              .toList();
          updatedLessons.sort((a, b) => a.date.compareTo(b.date));
          return updatedLessons;
        });

        if (kDebugMode) {
          print(
            "✅ Provider: ${lessonIds.length} lessons deleted via unified repository",
          );
        }

        return true;
      }

      return false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print("❌ Provider: Error deleting lesson series: $error");
      }
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

// Selected Lesson Provider
@riverpod
class SelectedLesson extends _$SelectedLesson {
  @override
  Lesson? build() => null;

  void select(Lesson lesson) => state = lesson;
  void clear() => state = null;
}

// Lesson Participants Provider - FIXED VERSION
@riverpod
Future<List<User>> lessonParticipants(
  LessonParticipantsRef ref,
  String lessonId,
) async {
  final lessonRepository = ref.read(lessonRepositoryProvider);
  final lesson = await lessonRepository.getLessonById(lessonId);

  if (lesson == null) return [];

  final userRepository = ref.read(userRepositoryProvider);
  final participants = <User>[];

  for (final artistId in lesson.registeredArtistIds) {
    final user = await userRepository.getUserById(artistId);
    if (user != null) participants.add(user);
  }

  return participants;
}

// Participant Management Provider
@Riverpod(keepAlive: true)
class ParticipantManagement extends _$ParticipantManagement {
  @override
  ParticipantManagementState build() =>
      const ParticipantManagementState(allArtists: [], selectedArtistIds: []);

  Future<void> initialize(String lessonId) async {
    state = state.copyWith(isLoading: true);
    try {
      final lesson = await ref
          .read(lessonRepositoryProvider)
          .getLessonById(lessonId);
      final artists = await ref
          .read(userRepositoryProvider)
          .getUsersByRole(UserRole.client);

      state = state.copyWith(
        isLoading: false,
        allArtists: artists,
        selectedArtistIds: lesson?.registeredArtistIds ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void updateSearch(String query) => state = state.copyWith(searchQuery: query);

  void toggleArtist(String artistId) {
    final newIds = List<String>.from(state.selectedArtistIds);
    newIds.contains(artistId) ? newIds.remove(artistId) : newIds.add(artistId);
    state = state.copyWith(selectedArtistIds: newIds);
  }

  Future<void> save(String lessonId) async {
    state = state.copyWith(isLoading: true);
    try {
      final lesson = await ref
          .read(lessonRepositoryProvider)
          .getLessonById(lessonId);
      if (lesson != null) {
        final updated = lesson.copyWith(
          registeredArtistIds: state.selectedArtistIds,
        );
        await ref.read(lessonRepositoryProvider).updateLessonDetails(updated);

        ref.invalidate(lessonParticipantsProvider(lessonId));
        ref.read(selectedLessonProvider.notifier).select(updated);
        ref.read(lessonNotifierProvider.notifier).updateLesson(updated);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

class ParticipantManagementState {
  final List<User> allArtists;
  final List<String> selectedArtistIds;
  final String searchQuery;
  final bool isLoading;

  const ParticipantManagementState({
    required this.allArtists,
    required this.selectedArtistIds,
    this.searchQuery = '',
    this.isLoading = false,
  });

  List<User> get filteredArtists => allArtists
      .where(
        (artist) =>
            artist.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            artist.email.toLowerCase().contains(searchQuery.toLowerCase()),
      )
      .toList();

  ParticipantManagementState copyWith({
    List<User>? allArtists,
    List<String>? selectedArtistIds,
    String? searchQuery,
    bool? isLoading,
  }) => ParticipantManagementState(
    allArtists: allArtists ?? this.allArtists,
    selectedArtistIds: selectedArtistIds ?? this.selectedArtistIds,
    searchQuery: searchQuery ?? this.searchQuery,
    isLoading: isLoading ?? this.isLoading,
  );
}
