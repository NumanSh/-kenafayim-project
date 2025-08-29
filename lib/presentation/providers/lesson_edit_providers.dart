import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knafayim_app/presentation/providers/lesson_providers.dart';
import '../../data/models/lesson.dart';
import '../../data/models/user.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../config/service_locator.dart';

// Edit Lesson State
class LessonEditState {
  final bool isLoading;
  final String? error;
  final Lesson? originalLesson;
  final List<User> availableArtists;
  final List<String> selectedArtistIds;

  const LessonEditState({
    this.isLoading = false,
    this.error,
    this.originalLesson,
    this.availableArtists = const [],
    this.selectedArtistIds = const [],
  });

  LessonEditState copyWith({
    bool? isLoading,
    String? error,
    Lesson? originalLesson,
    List<User>? availableArtists,
    List<String>? selectedArtistIds,
  }) {
    return LessonEditState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      originalLesson: originalLesson ?? this.originalLesson,
      availableArtists: availableArtists ?? this.availableArtists,
      selectedArtistIds: selectedArtistIds ?? this.selectedArtistIds,
    );
  }
}

// Edit Lesson Notifier
final lessonEditNotifierProvider =
    StateNotifierProvider<LessonEditNotifier, LessonEditState>((ref) {
  return LessonEditNotifier(ref);
});

class LessonEditNotifier extends StateNotifier<LessonEditState> {
  final Ref ref;

  LessonEditNotifier(this.ref) : super(const LessonEditState());

  // Initialize edit form with lesson data
  Future<void> initializeEdit(Lesson lesson) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load available artists
      final userRepository = serviceLocator<UserRepository>();
      final allUsers = await userRepository.getAllUsers();
      final artists =
          allUsers.where((user) => user.role == UserRole.client).toList();

      state = state.copyWith(
        isLoading: false,
        originalLesson: lesson,
        availableArtists: artists,
        selectedArtistIds: List.from(lesson.registeredArtistIds),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'שגיאה בטעינת נתונים: $e',
      );
    }
  }

  // Update selected artists
  void updateSelectedArtists(List<String> artistIds) {
    state = state.copyWith(selectedArtistIds: artistIds);
  }

  // Save lesson changes
  Future<bool> saveLesson({
    required String title,
    required DateTime date,
    required int durationMinutes,
    String? instructorName,
    String? instructorEmail,
    int? maxCapacity,
  }) async {
    if (state.originalLesson == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final lessonRepository = serviceLocator<LessonRepository>();

      // Create updated lesson
      final updatedLesson = Lesson(
        id: state.originalLesson!.id,
        title: title,
        date: date,
        durationMinutes: durationMinutes,
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        assignedInstructorId: state.originalLesson!.assignedInstructorId,
        maxCapacity: maxCapacity,
        registeredArtistIds: state.selectedArtistIds,
        status: state.originalLesson!.status,
        attendanceRecords: state.originalLesson!.attendanceRecords,
      );

      // Update lesson
      final result = await lessonRepository.updateLessonDetails(updatedLesson);

      if (result != null) {
        // Update the main lesson provider
        await ref.read(lessonNotifierProvider.notifier).updateLesson(result);

        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'שגיאה בעדכון השיעור',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'שגיאה בשמירת השיעור: $e',
      );
      return false;
    }
  }

  // Clear state
  void clear() {
    state = const LessonEditState();
  }
}
