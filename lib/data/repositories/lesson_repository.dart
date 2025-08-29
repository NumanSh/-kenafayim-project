import "dart:async";
import "dart:convert";
import "dart:math";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/foundation.dart";
import "package:knafayim_app/data/models/lesson_series.dart";
import "package:knafayim_app/data/models/user.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../models/lesson.dart";
import "../../config/service_locator.dart";
import "../models/attendance_record.dart";
import "./user_repository.dart";

class LessonRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository = serviceLocator<UserRepository>();
  final Random _random = Random();
  static const String _lessonsStorageKey = 'lessons_data';

  // Keep local cache for offline functionality
  List<Lesson> _cachedLessons = [];
  bool _isInitialized = false;

  LessonRepository() {
    _initializeRepository();
  }

  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        _random.nextInt(99999).toString();
  }

  // Initialize repository by loading from Firestore
  Future<void> _initializeRepository() async {
    if (_isInitialized) return;

    try {
      print('🔍 REPO: Initializing repository from Firestore...');

      // Load from Firestore first
      await _loadLessonsFromFirestore();

      // Then load local cache as backup
      await _loadLessonsFromStorage();

      _isInitialized = true;
      print(
        '🔍 REPO: Repository initialized with ${_cachedLessons.length} lessons',
      );
    } catch (e) {
      print('🔍 REPO: Error initializing repository: $e');
      // Fallback to local storage only
      await _loadLessonsFromStorage();
      _isInitialized = true;
    }
  }

  // Load lessons from Firestore (PRIMARY DATA SOURCE)
  Future<void> _loadLessonsFromFirestore() async {
    try {
      print('🔍 REPO: Loading lessons from Firestore...');

      final querySnapshot = await _firestore.collection('lessons').get();

      final lessons = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Lesson.fromMap(data);
      }).toList();

      _cachedLessons = lessons;

      // Update local cache with Firestore data
      await _saveLessonsToStorage();

      print('🔍 REPO: Loaded ${lessons.length} lessons from Firestore');
    } catch (e) {
      print('🔍 REPO: Error loading from Firestore: $e');
      throw e;
    }
  }

  // Load lessons from SharedPreferences (BACKUP/CACHE)
  Future<void> _loadLessonsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonsJson = prefs.getString(_lessonsStorageKey);

      if (lessonsJson != null) {
        final List<dynamic> decodedList = jsonDecode(lessonsJson);
        final localLessons = decodedList
            .map((lessonMap) => Lesson.fromMap(lessonMap))
            .toList();

        // Only use local cache if Firestore cache is empty
        if (_cachedLessons.isEmpty) {
          _cachedLessons = localLessons;
        }

        print(
          "🔍 REPO: Loaded ${localLessons.length} lessons from local storage",
        );
      }
    } catch (e) {
      print("🔍 REPO: Error loading from local storage: $e");
    }
  }

  // Save lessons to SharedPreferences (CACHE)
  Future<void> _saveLessonsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonsJson = jsonEncode(
        _cachedLessons.map((lesson) => lesson.toMap()).toList(),
      );
      await prefs.setString(_lessonsStorageKey, lessonsJson);
      print("🔍 REPO: Cached ${_cachedLessons.length} lessons locally");
    } catch (e) {
      print("🔍 REPO: Error saving to local storage: $e");
    }
  }

  // Save lesson to Firestore (PRIMARY SAVE)
  Future<void> _saveToFirestore(Lesson lesson) async {
    try {
      await _firestore.collection('lessons').doc(lesson.id).set(lesson.toMap());
      print("🔍 REPO: Saved lesson to Firestore: ${lesson.title}");
    } catch (e) {
      print("🔍 REPO: Error saving to Firestore: $e");
      throw e;
    }
  }

  // Get all lessons from Firestore (REAL-TIME)
  Future<List<Lesson>> getAllLessons({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _initializeRepository();

    try {
      // Always fetch fresh data from Firestore
      await _loadLessonsFromFirestore();

      List<Lesson> lessons = List<Lesson>.from(_cachedLessons);

      // Apply date filtering if provided
      if (startDate != null && endDate != null) {
        lessons = lessons.where((lesson) {
          return lesson.date.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              lesson.date.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();
      }

      // Sort by date
      lessons.sort((a, b) => a.date.compareTo(b.date));

      print('🔍 REPO: Returning ${lessons.length} lessons');
      return lessons;
    } catch (e) {
      print('🔍 REPO: Error getting lessons, using cache: $e');
      // Fallback to cached data
      return List<Lesson>.from(_cachedLessons);
    }
  }

  // For Staff view - includes all lessons
  Future<List<Lesson>> getAllLessonsForStaff() async {
    await _initializeRepository();

    try {
      // Always fetch fresh data from Firestore
      await _loadLessonsFromFirestore();

      List<Lesson> lessons = List<Lesson>.from(_cachedLessons);

      // Sort by date (future first, then past)
      lessons.sort((a, b) {
        bool aIsFuture = a.date.isAfter(DateTime.now());
        bool bIsFuture = b.date.isAfter(DateTime.now());

        if (aIsFuture && bIsFuture) {
          return a.date.compareTo(b.date);
        } else if (!aIsFuture && !bIsFuture) {
          return b.date.compareTo(a.date);
        } else {
          return aIsFuture ? -1 : 1;
        }
      });

      print(
        "🔍 REPO: getAllLessonsForStaff returning ${lessons.length} lessons",
      );
      return lessons;
    } catch (e) {
      print('🔍 REPO: Error getting staff lessons, using cache: $e');
      return List<Lesson>.from(_cachedLessons);
    }
  }

  // Get lessons for a specific artist
  Future<List<Lesson>> getLessonsForArtist(
    String artistId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _initializeRepository();

    try {
      await _loadLessonsFromFirestore();

      return List<Lesson>.from(
        _cachedLessons
            .where((lesson) => lesson.registeredArtistIds.contains(artistId))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
      );
    } catch (e) {
      print('🔍 REPO: Error getting artist lessons: $e');
      return [];
    }
  }

  // Get available lessons for artist registration
  Future<List<Lesson>> getAvailableLessonsForArtist(String artistId) async {
    await _initializeRepository();

    try {
      await _loadLessonsFromFirestore();

      return List<Lesson>.from(
        _cachedLessons.where((lesson) {
          bool isScheduledAndFuture =
              lesson.status == "scheduled" &&
              lesson.date
                  .add(Duration(minutes: lesson.durationMinutes))
                  .isAfter(DateTime.now());
          bool isNotRegistered = !lesson.registeredArtistIds.contains(artistId);
          bool hasCapacity =
              lesson.maxCapacity == null ||
              lesson.registeredArtistIds.length < lesson.maxCapacity!;
          return isScheduledAndFuture && isNotRegistered && hasCapacity;
        }).toList()..sort((a, b) => a.date.compareTo(b.date)),
      );
    } catch (e) {
      print('🔍 REPO: Error getting available lessons: $e');
      return [];
    }
  }

  // Get lessons for a specific mentor
  Future<List<Lesson>> getLessonsForMentor(
    String mentorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _initializeRepository();

    try {
      await _loadLessonsFromFirestore();

      var filteredLessons = _cachedLessons.where(
        (lesson) =>
            lesson.assignedInstructorId == mentorId &&
            (lesson.status == "scheduled" || lesson.status == "completed"),
      );

      if (startDate != null) {
        filteredLessons = filteredLessons.where(
          (lesson) =>
              lesson.date.isAfter(startDate.subtract(const Duration(days: 1))),
        );
      }

      if (endDate != null) {
        filteredLessons = filteredLessons.where(
          (lesson) =>
              lesson.date.isBefore(endDate.add(const Duration(days: 1))),
        );
      }

      return filteredLessons.toList()..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      print('🔍 REPO: Error getting mentor lessons: $e');
      return [];
    }
  }

  // Get lesson by ID
  // Get lesson by ID - PRIORITIZE CACHE for immediate updates
  Future<Lesson?> getLessonById(String lessonId) async {
    await _initializeRepository();

    try {
      // Check cache FIRST for immediate updates
      try {
        final cachedLesson = _cachedLessons.firstWhere(
          (lesson) => lesson.id == lessonId,
        );
        print(
          '🔍 REPO: Found lesson in cache: ${cachedLesson.title} with ${cachedLesson.attendanceRecords.length} attendance records',
        );
        return cachedLesson;
      } catch (e) {
        print('🔍 REPO: Lesson not in cache, fetching from Firestore...');
      }

      // Fallback to Firestore if not in cache
      final doc = await _firestore.collection('lessons').doc(lessonId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        final lesson = Lesson.fromMap(data);

        // Add to cache for future requests
        final index = _cachedLessons.indexWhere((l) => l.id == lessonId);
        if (index != -1) {
          _cachedLessons[index] = lesson;
        } else {
          _cachedLessons.add(lesson);
        }

        return lesson;
      }

      return null;
    } catch (e) {
      print('🔍 REPO: Error getting lesson by ID: $e');
      return null;
    }
  }

  // Add new lesson (FIRESTORE FIRST)
  Future<Lesson> addLesson({
    required String title,
    required DateTime date,
    required int durationMinutes,
    String? instructorName,
    String? instructorEmail,
    int? maxCapacity,
    List<String> registeredArtistIds = const [],
    String? backgroundImagePath,
  }) async {
    await _initializeRepository();

    try {
      final lessonId = _generateUniqueId();

      String? assignedInstructorId;
      if (instructorEmail != null && instructorEmail.isNotEmpty) {
        try {
          final instructor = await _userRepository.getUserByEmail(
            instructorEmail,
          );
          if (instructor != null) {
            assignedInstructorId = instructor.id;
          }
        } catch (e) {
          print("🔍 REPO: Could not resolve instructor email: $e");
        }
      }

      final lesson = Lesson(
        id: lessonId,
        title: title,
        date: date,
        durationMinutes: durationMinutes,
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        assignedInstructorId: assignedInstructorId,
        maxCapacity: maxCapacity,
        registeredArtistIds: registeredArtistIds,
        status: "scheduled",
        backgroundImagePath: backgroundImagePath,
        attendanceRecords: registeredArtistIds
            .map(
              (artistId) => AttendanceRecord(
                id: _generateUniqueId(),
                lessonId: lessonId,
                artistId: artistId,
                status: "pending",
                date: DateTime.now(),
              ),
            )
            .toList(),
      );

      // Save to Firestore FIRST
      await _saveToFirestore(lesson);

      // Update local cache
      _cachedLessons.add(lesson);
      await _saveLessonsToStorage();

      print("🔍 REPO: Lesson '${lesson.title}' created successfully");
      return lesson;
    } catch (e) {
      print("🔍 REPO: Error creating lesson: $e");
      throw Exception('Failed to create lesson: $e');
    }
  }

  // Update lesson details (FIRESTORE FIRST)
  // Update lesson details (FIRESTORE FIRST)
  Future<Lesson?> updateLessonDetails(Lesson updatedLesson) async {
    await _initializeRepository();

    try {
      print(
        '🔍 REPO: Starting updateLessonDetails for lesson: ${updatedLesson.id}',
      );
      print(
        '🔍 REPO: Attendance records count: ${updatedLesson.attendanceRecords.length}',
      );

      // Save to Firestore FIRST
      await _saveToFirestore(updatedLesson);
      print('🔍 REPO: Successfully saved to Firestore');

      // Update local cache IMMEDIATELY
      final index = _cachedLessons.indexWhere((l) => l.id == updatedLesson.id);
      if (index != -1) {
        _cachedLessons[index] = updatedLesson;
        print('🔍 REPO: Updated existing lesson in cache at index $index');
      } else {
        _cachedLessons.add(updatedLesson);
        print('🔍 REPO: Added new lesson to cache');
      }

      // Save to local storage
      await _saveLessonsToStorage();
      print('🔍 REPO: Successfully updated local cache');

      // 🔥 CRITICAL FIX: Force cache refresh for real-time updates
      await Future.delayed(const Duration(milliseconds: 100));

      return updatedLesson;
    } catch (e) {
      print('🔍 REPO: Error updating lesson: $e');
      throw e;
    }
  }

  // Register artist for lesson (FIRESTORE FIRST)
  Future<bool> registerArtistForLesson(String lessonId, String artistId) async {
    await _initializeRepository();

    try {
      final lesson = await getLessonById(lessonId);
      if (lesson == null) return false;

      if (lesson.status != "scheduled") return false;
      if (lesson.registeredArtistIds.contains(artistId)) return true;
      if (lesson.maxCapacity != null &&
          lesson.registeredArtistIds.length >= lesson.maxCapacity!) {
        return false;
      }

      final updatedLesson = lesson.copyWith(
        registeredArtistIds: [...lesson.registeredArtistIds, artistId],
        attendanceRecords: [
          ...lesson.attendanceRecords,
          AttendanceRecord(
            id: _generateUniqueId(),
            lessonId: lessonId,
            artistId: artistId,
            status: "pending",
            date: DateTime.now(),
          ),
        ],
      );

      await updateLessonDetails(updatedLesson);
      print("🔍 REPO: Artist $artistId registered for lesson ${lesson.title}");
      return true;
    } catch (e) {
      print("🔍 REPO: Error registering artist: $e");
      return false;
    }
  }

  // Delete lesson (FIRESTORE FIRST)
  /// Delete lesson with real-time updates
  Future<bool> deleteLesson(String lessonId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('lessons').doc(lessonId).delete();

      print('✅ Repository: Lesson deleted successfully: $lessonId');
      return true;
    } catch (e) {
      print('❌ Repository: Error deleting lesson: $e');
      return false;
    }
  }

  /// Delete multiple lessons (for series deletion)
  Future<bool> deleteLessons(List<String> lessonIds) async {
    try {
      final batch = _firestore.batch();

      for (final lessonId in lessonIds) {
        final docRef = _firestore.collection('lessons').doc(lessonId);
        batch.delete(docRef);
      }

      await batch.commit();

      print('✅ Repository: ${lessonIds.length} lessons deleted successfully');
      return true;
    } catch (e) {
      print('❌ Repository: Error deleting lessons: $e');
      return false;
    }
  }

  // Cancel lesson (FIRESTORE FIRST)
  Future<bool> cancelLesson(String lessonId, String reason) async {
    await _initializeRepository();

    try {
      final lesson = await getLessonById(lessonId);
      if (lesson == null) return false;

      final updatedLesson = lesson.copyWith(status: "cancelled");
      await updateLessonDetails(updatedLesson);

      print("🔍 REPO: Lesson ${lesson.title} cancelled. Reason: $reason");
      return true;
    } catch (e) {
      print("🔍 REPO: Error cancelling lesson: $e");
      return false;
    }
  }

  // Unregister artist from lesson (FIRESTORE FIRST)
  Future<bool> unregisterArtistFromLesson(
    String lessonId,
    String artistId,
  ) async {
    await _initializeRepository();

    try {
      final lesson = await getLessonById(lessonId);
      if (lesson == null) return false;

      if (lesson.status != "scheduled") return false;
      if (!lesson.registeredArtistIds.contains(artistId)) return true;

      final updatedRegisteredIds = List<String>.from(lesson.registeredArtistIds)
        ..remove(artistId);

      final updatedAttendanceRecords = lesson.attendanceRecords
          .where((ar) => ar.artistId != artistId)
          .toList();

      final updatedLesson = lesson.copyWith(
        registeredArtistIds: updatedRegisteredIds,
        attendanceRecords: updatedAttendanceRecords,
      );

      await updateLessonDetails(updatedLesson);
      print(
        "🔍 REPO: Artist $artistId unregistered from lesson ${lesson.title}",
      );
      return true;
    } catch (e) {
      print("🔍 REPO: Error unregistering artist: $e");
      return false;
    }
  }

  // Update lesson attendance (FIRESTORE FIRST)
  Future<bool> updateLessonAttendance(
    String lessonId,
    List<AttendanceRecord> updatedAttendanceRecords,
  ) async {
    await _initializeRepository();

    try {
      final lesson = await getLessonById(lessonId);
      if (lesson == null) return false;

      final updatedLesson = lesson.copyWith(
        attendanceRecords: updatedAttendanceRecords,
      );

      // Check if lesson should be marked as completed
      if (lesson.date.isBefore(DateTime.now()) &&
          lesson.status == "scheduled") {
        bool allMarked = lesson.registeredArtistIds.every(
          (artistId) => updatedAttendanceRecords.any(
            (ar) =>
                ar.artistId == artistId &&
                (ar.status == "present" || ar.status == "absent"),
          ),
        );

        if (allMarked && lesson.registeredArtistIds.isNotEmpty) {
          updatedLesson.status = "completed";
          print("🔍 REPO: Lesson ${lesson.title} marked as completed");
        }
      }

      await updateLessonDetails(updatedLesson);
      print("🔍 REPO: Attendance updated for lesson ${lesson.title}");
      return true;
    } catch (e) {
      print("🔍 REPO: Error updating attendance: $e");
      return false;
    }
  }

  // Update lesson background image (FIRESTORE FIRST)
  Future<Lesson?> updateLessonBackgroundImage(
    String lessonId,
    String? imagePath,
  ) async {
    await _initializeRepository();

    try {
      final lesson = await getLessonById(lessonId);
      if (lesson == null) return null;

      final updatedLesson = lesson.copyWith(backgroundImagePath: imagePath);
      await updateLessonDetails(updatedLesson);

      print("🔍 REPO: Lesson background updated: $imagePath");
      return updatedLesson;
    } catch (e) {
      print("🔍 REPO: Error updating lesson background: $e");
      return null;
    }
  }
  // ✅ NEW: Recurring Lesson Series Management Methods

  /// Creates a complete recurring lesson series
  Future<List<Lesson>> createRecurringLessonSeries({
    required String title,
    required DateTime startDate,
    required int durationMinutes,
    required RecurrencePattern recurrence,
    String? instructorName,
    String? instructorEmail,
    String? assignedInstructorId,
    int? maxCapacity,
    List<String> registeredArtistIds = const [],
    String? backgroundImagePath,
    Map<String, dynamic> seriesMetadata = const {},
  }) async {
    await _initializeRepository();

    try {
      print('🔍 REPO: Creating recurring lesson series: $title');

      // Generate unique recurrence ID for the series
      final recurrenceId =
          'series_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(99999)}';

      // Calculate all lesson dates based on recurrence pattern
      final lessonDates = _calculateRecurringDates(startDate, recurrence);

      print('🔍 REPO: Generated ${lessonDates.length} lesson dates');

      // Create lessons for each date
      final List<Lesson> createdLessons = [];

      for (int i = 0; i < lessonDates.length; i++) {
        final lessonDate = lessonDates[i];
        final lessonId = _generateUniqueId();

        // Create attendance records for registered artists
        final attendanceRecords = registeredArtistIds
            .map(
              (artistId) => AttendanceRecord(
                id: _generateUniqueId(),
                lessonId: lessonId,
                artistId: artistId,
                status: "pending",
                date: lessonDate,
              ),
            )
            .toList();

        final lesson = Lesson(
          id: lessonId,
          title: '$title - שיעור ${i + 1}',
          date: lessonDate,
          durationMinutes: durationMinutes,
          instructorName: instructorName,
          instructorEmail: instructorEmail,
          assignedInstructorId: assignedInstructorId,
          maxCapacity: maxCapacity,
          registeredArtistIds: registeredArtistIds,
          status: "scheduled",
          backgroundImagePath: backgroundImagePath,
          attendanceRecords: attendanceRecords,
          // Recurring fields
          recurrenceId: recurrenceId,
          recurrence: recurrence,
          seriesStartDate: startDate,
          seriesEndDate: recurrence.endDate ?? lessonDates.last,
          isRecurring: true,
          instanceNumber: i + 1,
          seriesTitle: title,
          seriesMetadata: {
            ...seriesMetadata,
            'createdAt': DateTime.now().toIso8601String(),
            'totalLessons': lessonDates.length,
          },
        );

        // Save to Firestore
        await _saveToFirestore(lesson);
        createdLessons.add(lesson);

        print(
          '🔍 REPO: Created lesson ${i + 1}/${lessonDates.length}: ${lesson.title}',
        );
      }

      // Update local cache
      _cachedLessons.addAll(createdLessons);
      await _saveLessonsToStorage();

      print(
        '✅ REPO: Successfully created ${createdLessons.length} lessons in series',
      );
      return createdLessons;
    } catch (e) {
      print('❌ REPO: Error creating recurring lesson series: $e');
      throw Exception('Failed to create recurring lesson series: $e');
    }
  }

  /// Gets all lessons in a specific series
  Future<List<Lesson>> getLessonSeries(String recurrenceId) async {
    await _initializeRepository();

    try {
      print('🔍 REPO: Getting lesson series: $recurrenceId');

      // Try to get from Firestore first
      final querySnapshot = await _firestore
          .collection('lessons')
          .where('recurrenceId', isEqualTo: recurrenceId)
          .orderBy('instanceNumber')
          .get();

      final lessons = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Lesson.fromMap(data);
      }).toList();

      print('🔍 REPO: Found ${lessons.length} lessons in series');
      return lessons;
    } catch (e) {
      print('❌ REPO: Error getting lesson series: $e');
      // Fallback to cached lessons
      return _cachedLessons
          .where((lesson) => lesson.recurrenceId == recurrenceId)
          .toList()
        ..sort(
          (a, b) => (a.instanceNumber ?? 0).compareTo(b.instanceNumber ?? 0),
        );
    }
  }

  /// Updates an entire lesson series or individual instances
  Future<bool> updateLessonSeries({
    required String recurrenceId,
    required SeriesUpdateType updateType,
    String? newTitle,
    String? newInstructorName,
    String? newInstructorEmail,
    String? newAssignedInstructorId,
    int? newMaxCapacity,
    String? newBackgroundImagePath,
    DateTime? specificInstanceDate, // For single instance updates
    Map<String, dynamic>? newSeriesMetadata,
  }) async {
    await _initializeRepository();

    try {
      print(
        '🔍 REPO: Updating lesson series: $recurrenceId (${updateType.name})',
      );

      final seriesLessons = await getLessonSeries(recurrenceId);
      if (seriesLessons.isEmpty) {
        print('❌ REPO: No lessons found for series: $recurrenceId');
        return false;
      }

      List<Lesson> lessonsToUpdate = [];

      switch (updateType) {
        case SeriesUpdateType.allInstances:
          lessonsToUpdate = seriesLessons;
          break;

        case SeriesUpdateType.thisAndFuture:
          if (specificInstanceDate != null) {
            lessonsToUpdate = seriesLessons
                .where(
                  (lesson) =>
                      lesson.date.isAtSameMomentAs(specificInstanceDate) ||
                      lesson.date.isAfter(specificInstanceDate),
                )
                .toList();
          }
          break;

        case SeriesUpdateType.singleInstance:
          if (specificInstanceDate != null) {
            lessonsToUpdate = seriesLessons
                .where(
                  (lesson) =>
                      lesson.date.isAtSameMomentAs(specificInstanceDate),
                )
                .toList();
          }
          break;
      }

      // Update each lesson
      for (final lesson in lessonsToUpdate) {
        final updatedLesson = lesson.copyWith(
          title: newTitle != null
              ? '$newTitle - שיעור ${lesson.instanceNumber}'
              : null,
          instructorName: newInstructorName,
          instructorEmail: newInstructorEmail,
          assignedInstructorId: newAssignedInstructorId,
          maxCapacity: newMaxCapacity,
          backgroundImagePath: newBackgroundImagePath,
          seriesMetadata: newSeriesMetadata != null
              ? {...lesson.seriesMetadata, ...newSeriesMetadata}
              : null,
        );

        await _saveToFirestore(updatedLesson);

        // Update local cache
        final index = _cachedLessons.indexWhere((l) => l.id == lesson.id);
        if (index != -1) {
          _cachedLessons[index] = updatedLesson;
        }
      }

      await _saveLessonsToStorage();

      print('✅ REPO: Updated ${lessonsToUpdate.length} lessons in series');
      return true;
    } catch (e) {
      print('❌ REPO: Error updating lesson series: $e');
      return false;
    }
  }

  /// Cancels an entire lesson series or specific instances
  Future<bool> cancelLessonSeries({
    required String recurrenceId,
    required SeriesCancelType cancelType,
    required String reason,
    DateTime? specificInstanceDate,
  }) async {
    await _initializeRepository();

    try {
      print(
        '🔍 REPO: Cancelling lesson series: $recurrenceId (${cancelType.name})',
      );

      final seriesLessons = await getLessonSeries(recurrenceId);
      if (seriesLessons.isEmpty) {
        print('❌ REPO: No lessons found for series: $recurrenceId');
        return false;
      }

      List<Lesson> lessonsToCancel = [];

      switch (cancelType) {
        case SeriesCancelType.entireSeries:
          lessonsToCancel = seriesLessons
              .where((lesson) => lesson.status == 'scheduled')
              .toList();
          break;

        case SeriesCancelType.remainingInstances:
          final now = DateTime.now();
          lessonsToCancel = seriesLessons
              .where(
                (lesson) =>
                    lesson.status == 'scheduled' && lesson.date.isAfter(now),
              )
              .toList();
          break;

        case SeriesCancelType.singleInstance:
          if (specificInstanceDate != null) {
            lessonsToCancel = seriesLessons
                .where(
                  (lesson) =>
                      lesson.date.isAtSameMomentAs(specificInstanceDate) &&
                      lesson.status == 'scheduled',
                )
                .toList();
          }
          break;
      }

      // Cancel each lesson
      for (final lesson in lessonsToCancel) {
        final cancelledLesson = lesson.copyWith(
          status: 'cancelled',
          seriesMetadata: {
            ...lesson.seriesMetadata,
            'cancelledAt': DateTime.now().toIso8601String(),
            'cancelReason': reason,
            'cancelType': cancelType.name,
          },
        );

        await _saveToFirestore(cancelledLesson);

        // Update local cache
        final index = _cachedLessons.indexWhere((l) => l.id == lesson.id);
        if (index != -1) {
          _cachedLessons[index] = cancelledLesson;
        }
      }

      await _saveLessonsToStorage();

      print('✅ REPO: Cancelled ${lessonsToCancel.length} lessons in series');
      return true;
    } catch (e) {
      print('❌ REPO: Error cancelling lesson series: $e');
      return false;
    }
  }

  /// Gets all recurring lesson series (for staff management)
  Future<List<LessonSeries>> getAllLessonSeries() async {
    await _initializeRepository();

    try {
      print('🔍 REPO: Getting all lesson series');

      // Get all lessons that are part of a series
      final recurringLessons = _cachedLessons
          .where((lesson) => lesson.isRecurring && lesson.recurrenceId != null)
          .toList();

      // Group by recurrenceId
      final Map<String, List<Lesson>> seriesMap = {};
      for (final lesson in recurringLessons) {
        final recurrenceId = lesson.recurrenceId!;
        seriesMap.putIfAbsent(recurrenceId, () => []).add(lesson);
      }

      // Create LessonSeries objects
      final List<LessonSeries> series = [];
      for (final entry in seriesMap.entries) {
        final lessons = entry.value..sort((a, b) => a.date.compareTo(b.date));
        if (lessons.isNotEmpty) {
          series.add(LessonSeries.fromLessons(lessons));
        }
      }

      // Sort by start date
      series.sort((a, b) => a.startDate.compareTo(b.startDate));

      print('🔍 REPO: Found ${series.length} lesson series');
      return series;
    } catch (e) {
      print('❌ REPO: Error getting lesson series: $e');
      return [];
    }
  }

  /// Helper method to calculate recurring dates
  List<DateTime> _calculateRecurringDates(
    DateTime startDate,
    RecurrencePattern recurrence,
  ) {
    final List<DateTime> dates = [];
    DateTime currentDate = startDate;
    int occurrenceCount = 0;

    while (occurrenceCount < recurrence.maxOccurrences) {
      // Check if this date should be excluded
      if (!recurrence.excludeDates.any(
        (excludeDate) => _isSameDay(currentDate, excludeDate),
      )) {
        dates.add(currentDate);
        occurrenceCount++;
      }

      // Calculate next date based on recurrence type
      switch (recurrence.type) {
        case RecurrenceType.weekly:
          currentDate = currentDate.add(
            Duration(days: 7 * recurrence.interval),
          );
          break;

        case RecurrenceType.biweekly:
          currentDate = currentDate.add(
            Duration(days: 14 * recurrence.interval),
          );
          break;

        case RecurrenceType.monthly:
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + recurrence.interval,
            recurrence.dayOfMonth ?? currentDate.day,
            currentDate.hour,
            currentDate.minute,
          );
          break;

        case RecurrenceType.custom:
          // Handle custom recurrence patterns
          currentDate = _calculateNextCustomDate(currentDate, recurrence);
          break;

        case RecurrenceType.none:
        default:
          break; // Single lesson only
      }

      // Safety check to prevent infinite loops
      if (recurrence.endDate != null &&
          currentDate.isAfter(recurrence.endDate!)) {
        break;
      }
    }

    return dates;
  }

  /// Helper method for custom recurrence calculation
  DateTime _calculateNextCustomDate(
    DateTime currentDate,
    RecurrencePattern recurrence,
  ) {
    // For custom patterns, use the daysOfWeek to find the next occurrence
    if (recurrence.daysOfWeek.isNotEmpty) {
      DateTime nextDate = currentDate.add(const Duration(days: 1));

      while (true) {
        final weekday = WeekDay.values[nextDate.weekday % 7];
        if (recurrence.daysOfWeek.contains(weekday)) {
          return nextDate;
        }
        nextDate = nextDate.add(const Duration(days: 1));

        // Safety check
        if (nextDate.difference(currentDate).inDays > 14) {
          break;
        }
      }
    }

    // Fallback to weekly
    return currentDate.add(Duration(days: 7 * recurrence.interval));
  }

  /// Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ✅ NEW: Real attendance analytics
  // ✅ FIXED: Real attendance analytics with proper type casting
  Future<Map<String, dynamic>> getArtistAttendanceAnalytics(
    String artistId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? now;

      // Get all lessons for this artist in the date range
      final lessons = await getLessonsForArtist(
        artistId,
        startDate: start,
        endDate: end,
      );

      if (lessons.isEmpty) {
        return {
          'totalLessons': 0,
          'attendedLessons': 0,
          'attendanceRate': 0.0,
          'presentCount': 0,
          'absentCount': 0,
          'lateCount': 0,
          'excusedCount': 0,
          'pendingCount': 0,
          'favoriteStudio': 'אין נתונים',
          'weeklyAttendance': <Map<String, dynamic>>[],
          'studioBreakdown': <String, int>{},
          'averageLessonsPerWeek': 0.0,
        };
      }

      // Calculate attendance statistics with proper type handling
      int totalLessons = lessons.length;
      int presentCount = 0;
      int absentCount = 0;
      int lateCount = 0;
      int excusedCount = 0;
      int pendingCount = 0;

      Map<String, int> studioBreakdown = {};
      List<Map<String, dynamic>> weeklyData = [];

      for (final lesson in lessons) {
        // Find attendance record for this artist
        final attendanceRecord = lesson.attendanceRecords.firstWhere(
          (record) => record.artistId == artistId,
          orElse: () => AttendanceRecord(
            id: '',
            artistId: artistId,
            lessonId: lesson.id,
            date: lesson.date,
            status: 'pending',
          ),
        );

        // Count attendance status
        switch (attendanceRecord.status) {
          case 'present':
            presentCount++;
            break;
          case 'absent':
            absentCount++;
            break;
          case 'late':
            lateCount++;
            presentCount++; // Late is still considered attended
            break;
          case 'excused':
            excusedCount++;
            break;
          default:
            pendingCount++;
        }

        // Track studio usage
        final studio = _extractStudioFromLesson(lesson);
        studioBreakdown[studio] = (studioBreakdown[studio] ?? 0) + 1;
      }

      // Calculate weekly attendance for the last 4 weeks
      for (int i = 3; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: (i + 1) * 7));
        final weekEnd = now.subtract(Duration(days: i * 7));

        final weekLessons = lessons
            .where(
              (lesson) =>
                  lesson.date.isAfter(weekStart) &&
                  lesson.date.isBefore(weekEnd),
            )
            .toList();

        final weekAttended = weekLessons.where((lesson) {
          final record = lesson.attendanceRecords.firstWhere(
            (r) => r.artistId == artistId,
            orElse: () => AttendanceRecord(
              id: '',
              artistId: artistId,
              lessonId: lesson.id,
              date: lesson.date,
            ),
          );
          return record.status == 'present' || record.status == 'late';
        }).length;

        // ✅ FIXED: Proper double conversion
        final weekTotal = weekLessons.length;
        final attendanceRate = weekTotal > 0
            ? (weekAttended.toDouble() / weekTotal.toDouble()) * 100.0
            : 0.0;

        weeklyData.add({
          'week': 'שבוע ${4 - i}',
          'total': weekTotal,
          'attended': weekAttended,
          'rate': attendanceRate,
        });
      }

      // ✅ FIXED: Ensure all calculations return proper types
      final attendedLessons = presentCount;
      final attendanceRate = totalLessons > 0
          ? (attendedLessons.toDouble() / totalLessons.toDouble()) * 100.0
          : 0.0;

      final favoriteStudio = studioBreakdown.isNotEmpty
          ? studioBreakdown.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
          : 'אין נתונים';

      final averageLessonsPerWeek = totalLessons.toDouble() / 4.0;

      return {
        'totalLessons': totalLessons,
        'attendedLessons': attendedLessons,
        'attendanceRate': attendanceRate,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'excusedCount': excusedCount,
        'pendingCount': pendingCount,
        'favoriteStudio': favoriteStudio,
        'weeklyAttendance': weeklyData,
        'studioBreakdown': studioBreakdown,
        'averageLessonsPerWeek': averageLessonsPerWeek,
      };
    } catch (e) {
      print('Error getting artist attendance analytics: $e');
      return {
        'totalLessons': 0,
        'attendedLessons': 0,
        'attendanceRate': 0.0,
        'presentCount': 0,
        'absentCount': 0,
        'lateCount': 0,
        'excusedCount': 0,
        'pendingCount': 0,
        'favoriteStudio': 'שגיאה',
        'weeklyAttendance': <Map<String, dynamic>>[],
        'studioBreakdown': <String, int>{},
        'averageLessonsPerWeek': 0.0,
      };
    }
  }

  // ✅ NEW: Real studio analytics from lessons
  Future<Map<String, dynamic>> getStudioUtilizationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final lessons = await getAllLessons(
        startDate: startDate,
        endDate: endDate,
      );

      Map<String, int> studioUsage = {};
      Map<String, double> studioHours = {};
      int totalBookings = lessons.length;
      double totalHours = 0;

      for (final lesson in lessons) {
        final studio = _extractStudioFromLesson(lesson);
        final hours = lesson.durationMinutes / 60.0;

        studioUsage[studio] = (studioUsage[studio] ?? 0) + 1;
        studioHours[studio] = (studioHours[studio] ?? 0) + hours;
        totalHours += hours;
      }

      // Calculate utilization rates (assuming 8 hours/day available per studio)
      final daysInPeriod = endDate != null && startDate != null
          ? endDate.difference(startDate).inDays
          : 30;
      final availableHoursPerStudio = daysInPeriod * 8.0;
      final totalAvailableHours = availableHoursPerStudio * 6; // 6 studios

      return {
        'totalBookings': totalBookings,
        'totalHours': totalHours,
        'utilizationRate': totalAvailableHours > 0
            ? (totalHours / totalAvailableHours) * 100
            : 0,
        'studioUsage': studioUsage,
        'studioHours': studioHours,
        'averageBookingDuration': totalBookings > 0
            ? totalHours / totalBookings
            : 0,
        'activeStudios': studioUsage.keys.length,
        'mostPopularStudio': studioUsage.isNotEmpty
            ? studioUsage.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key
            : 'אין נתונים',
      };
    } catch (e) {
      print('Error getting studio utilization analytics: $e');
      return {
        'totalBookings': 0,
        'totalHours': 0.0,
        'utilizationRate': 0.0,
        'studioUsage': <String, int>{},
        'studioHours': <String, double>{},
        'averageBookingDuration': 0.0,
        'activeStudios': 0,
        'mostPopularStudio': 'שגיאה',
      };
    }
  }

  // ✅ NEW: Real user activity analytics
  Future<Map<String, dynamic>> getUserActivityAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allUsers = await _userRepository.getAllUsers();
      final artists = allUsers.where((u) => u.role == UserRole.client).toList();
      final mentors = allUsers.where((u) => u.role == UserRole.mentor).toList();

      final lessons = await getAllLessons(
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate active users (those who attended at least one lesson)
      Set<String> activeArtistIds = {};
      Set<String> activeMentorIds = {};

      for (final lesson in lessons) {
        // Count artists who attended
        for (final record in lesson.attendanceRecords) {
          if (record.status == 'present' || record.status == 'late') {
            activeArtistIds.add(record.artistId);
          }
        }

        // Count active mentors
        if (lesson.assignedInstructorId != null) {
          activeMentorIds.add(lesson.assignedInstructorId!);
        }
      }

      final totalUsers = artists.length + mentors.length;
      final activeUsers = activeArtistIds.length + activeMentorIds.length;
      final activityRate = totalUsers > 0
          ? (activeUsers / totalUsers) * 100
          : 0.0;

      // Calculate average activity per user
      final totalAttendanceRecords = lessons
          .expand((lesson) => lesson.attendanceRecords)
          .where(
            (record) => record.status == 'present' || record.status == 'late',
          )
          .length;

      final averageActivityPerUser = activeUsers > 0
          ? totalAttendanceRecords / activeUsers
          : 0.0;

      return {
        'totalUsers': totalUsers,
        'totalArtists': artists.length,
        'totalMentors': mentors.length,
        'activeUsers': activeUsers,
        'activeArtists': activeArtistIds.length,
        'activeMentors': activeMentorIds.length,
        'activityRate': activityRate,
        'averageActivityPerUser': averageActivityPerUser,
        'totalLessons': lessons.length,
        'totalAttendanceRecords': totalAttendanceRecords,
      };
    } catch (e) {
      print('Error getting user activity analytics: $e');
      return {
        'totalUsers': 0,
        'totalArtists': 0,
        'totalMentors': 0,
        'activeUsers': 0,
        'activeArtists': 0,
        'activeMentors': 0,
        'activityRate': 0.0,
        'averageActivityPerUser': 0.0,
        'totalLessons': 0,
        'totalAttendanceRecords': 0,
      };
    }
  }

  // ✅ Helper method to extract studio from lesson title
  String _extractStudioFromLesson(Lesson lesson) {
    final title = lesson.title.toLowerCase();

    if (title.contains('פלסטיק') ||
        title.contains('ציור') ||
        title.contains('פיסול')) {
      return 'פלסטיקה';
    } else if (title.contains('תיאטרון') ||
        title.contains('משחק') ||
        title.contains('דרמה')) {
      return 'תיאטרון';
    } else if (title.contains('מוזיקה') ||
        title.contains('שירה') ||
        title.contains('נגינה')) {
      return 'מוזיקה';
    } else if (title.contains('כתיבה') ||
        title.contains('ספרות') ||
        title.contains('שירה')) {
      return 'כתיבה';
    } else if (title.contains('אנימציה') || title.contains('הנפשה')) {
      return 'אנימציה';
    } else if (title.contains('וידאו') ||
        title.contains('צילום') ||
        title.contains('עריכה')) {
      return 'וידאו';
    }

    return 'כללי';
  }
}
