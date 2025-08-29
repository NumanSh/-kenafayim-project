import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:knafayim_app/services/notification_integration_service.dart';
import '../models/calendar_event.dart';
import '../models/lesson.dart';
import '../models/user.dart';
import 'calendar_repository.dart';
import 'lesson_repository.dart';
import 'user_repository.dart';
import '../../services/event_cache_service.dart';
import '../../config/service_locator.dart';

/// Unified repository that combines calendar events and lessons
/// Provides a single interface for all calendar-related operations
class UnifiedCalendarRepository {
  final CalendarRepository _calendarRepository;
  final LessonRepository _lessonRepository;
  final UserRepository _userRepository;
  final EventCacheService _cacheService;

  // Stream controllers for real-time updates
  final StreamController<List<UnifiedCalendarItem>> _eventsStreamController =
      StreamController<List<UnifiedCalendarItem>>.broadcast();

  // Cache for unified events
  Map<String, List<UnifiedCalendarItem>> _userEventsCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  UnifiedCalendarRepository({
    CalendarRepository? calendarRepository,
    LessonRepository? lessonRepository,
    UserRepository? userRepository,
    EventCacheService? cacheService,
  }) : _calendarRepository =
           calendarRepository ?? serviceLocator<CalendarRepository>(),
       _lessonRepository =
           lessonRepository ?? serviceLocator<LessonRepository>(),
       _userRepository = userRepository ?? serviceLocator<UserRepository>(),
       _cacheService = cacheService ?? EventCacheService();

  /// Stream of unified calendar events for real-time updates
  Stream<List<UnifiedCalendarItem>> get eventsStream =>
      _eventsStreamController.stream;

  /// Get all calendar items (events + lessons) for a user with role-based filtering
  Future<List<UnifiedCalendarItem>> getUnifiedCalendarItems({
    required String userId,
    required UserRole userRole,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache validity
      if (!forceRefresh && _isCacheValid(userId)) {
        if (kDebugMode) {
          print(
            'UnifiedCalendarRepository: Returning cached events for user $userId',
          );
        }
        return _filterByDateRange(
          _userEventsCache[userId] ?? [],
          startDate,
          endDate,
        );
      }

      if (kDebugMode) {
        print(
          'UnifiedCalendarRepository: Fetching fresh events for user $userId, role: $userRole',
        );
      }

      // Fetch calendar events and lessons concurrently
      final futures = await Future.wait([
        _getCalendarEventsForUser(userId, startDate, endDate),
        _getLessonsForUser(userId, userRole, startDate, endDate),
      ]);

      final calendarEvents = futures[0] as List<CalendarEvent>;
      final lessons = futures[1] as List<Lesson>;

      // Convert to unified format
      final unifiedItems = <UnifiedCalendarItem>[];

      // Add calendar events
      unifiedItems.addAll(
        calendarEvents.map(
          (event) => UnifiedCalendarItem.fromCalendarEvent(event),
        ),
      );

      // Add lessons
      unifiedItems.addAll(
        lessons.map((lesson) => UnifiedCalendarItem.fromLesson(lesson)),
      );

      // Sort by start time
      unifiedItems.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Update cache
      _userEventsCache[userId] = unifiedItems;
      _lastCacheUpdate = DateTime.now();

      // Emit to stream
      _eventsStreamController.add(unifiedItems);

      if (kDebugMode) {
        print(
          'UnifiedCalendarRepository: Fetched ${unifiedItems.length} unified items for user $userId',
        );
      }

      return _filterByDateRange(unifiedItems, startDate, endDate);
    } catch (e) {
      if (kDebugMode) {
        print(
          'UnifiedCalendarRepository: Error fetching unified calendar items: $e',
        );
      }
      throw Exception('Failed to fetch calendar items: $e');
    }
  }

  /// Get events for a specific date
  Future<List<UnifiedCalendarItem>> getEventsForDate({
    required String userId,
    required UserRole userRole,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getUnifiedCalendarItems(
      userId: userId,
      userRole: userRole,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Create a new calendar event
  Future<CalendarEvent> createCalendarEvent(CalendarEvent event) async {
    try {
      final createdEvent = await _calendarRepository.createEvent(event);

      // Invalidate cache for all participants
      for (final participantId in event.participantIds) {
        _invalidateUserCache(participantId);
      }

      // Refresh and emit updated events
      await _refreshAndEmitEvents(event.participantIds);

      return createdEvent;
    } catch (e) {
      throw Exception('Failed to create calendar event: $e');
    }
  }

  /// Create a new lesson
  // Add this import at the top

  Future<Lesson> createLesson({
    required String title,
    required DateTime date,
    required int durationMinutes,
    String? instructorName,
    String? instructorEmail,
    int? maxCapacity,
    List<String> registeredArtistIds = const [], // ✅ ADD THIS PARAMETER
  }) async {
    try {
      final createdLesson = await _lessonRepository.addLesson(
        title: title,
        date: date,
        durationMinutes: durationMinutes,
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        maxCapacity: maxCapacity,
        registeredArtistIds: registeredArtistIds, // ✅ PASS THIS TO REPOSITORY
      );

      // ✅ ADD NOTIFICATION INTEGRATION

      // Rest of your existing code...
      final affectedUserIds = <String>[];
      if (createdLesson.assignedInstructorId != null) {
        affectedUserIds.add(createdLesson.assignedInstructorId!);
      }
      affectedUserIds.addAll(createdLesson.registeredArtistIds);

      for (final userId in affectedUserIds) {
        _invalidateUserCache(userId);
      }

      await _refreshAndEmitEvents(affectedUserIds);

      return createdLesson;
    } catch (e) {
      throw Exception('Failed to create lesson: $e');
    }
  }

  /// Update a calendar event
  Future<void> updateCalendarEvent(CalendarEvent event) async {
    try {
      await _calendarRepository.updateEvent(event);

      // Invalidate cache for all participants
      for (final participantId in event.participantIds) {
        _invalidateUserCache(participantId);
      }

      // Refresh and emit updated events
      await _refreshAndEmitEvents(event.participantIds);
    } catch (e) {
      throw Exception('Failed to update calendar event: $e');
    }
  }

  /// Update a lesson
  Future<Lesson?> updateLesson(Lesson lesson) async {
    try {
      final updatedLesson = await _lessonRepository.updateLessonDetails(lesson);

      if (updatedLesson != null) {
        // Invalidate cache for instructor and registered artists
        final affectedUserIds = <String>[];
        if (lesson.assignedInstructorId != null) {
          affectedUserIds.add(lesson.assignedInstructorId!);
        }
        affectedUserIds.addAll(lesson.registeredArtistIds);

        for (final userId in affectedUserIds) {
          _invalidateUserCache(userId);
        }

        // Refresh and emit updated events
        await _refreshAndEmitEvents(affectedUserIds);
      }

      return updatedLesson;
    } catch (e) {
      throw Exception('Failed to update lesson: $e');
    }
  }

  /// Delete a calendar event
  Future<void> deleteCalendarEvent(
    String eventId,
    List<String> participantIds,
  ) async {
    try {
      await _calendarRepository.deleteEvent(eventId);

      // Invalidate cache for all participants
      for (final participantId in participantIds) {
        _invalidateUserCache(participantId);
      }

      // Refresh and emit updated events
      await _refreshAndEmitEvents(participantIds);
    } catch (e) {
      throw Exception('Failed to delete calendar event: $e');
    }
  }

  /// Delete a lesson
  /// Delete lesson with real-time calendar updates
  Future<bool> deleteLesson(String lessonId) async {
    try {
      // Delete via lesson repository
      final success = await _lessonRepository.deleteLesson(lessonId);

      if (success) {
        // ✅ ENHANCED: Invalidate cache for all users
        _userEventsCache.clear();
        _lastCacheUpdate = null;

        // ✅ NEW: Immediately refresh and emit for all relevant users
        await _refreshAllUsersEventsAfterDeletion(lessonId);

        print('✅ Unified Repository: Lesson deleted and cache refreshed');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Unified Repository: Error deleting lesson: $e');
      return false;
    }
  }

  /// Delete multiple lessons (for series)
  Future<bool> deleteLessonSeries(List<String> lessonIds) async {
    try {
      // Delete via lesson repository
      final success = await _lessonRepository.deleteLessons(lessonIds);

      if (success) {
        // ✅ ENHANCED: Invalidate cache for all users
        _userEventsCache.clear();
        _lastCacheUpdate = null;

        // ✅ NEW: Immediately refresh and emit for all relevant users
        await _refreshAllUsersEventsAfterDeletion(lessonIds.first);

        print(
          '✅ Unified Repository: ${lessonIds.length} lessons deleted and cache refreshed',
        );
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Unified Repository: Error deleting lesson series: $e');
      return false;
    }
  }

  // ✅ NEW: Refresh events for all users after deletion
  Future<void> _refreshAllUsersEventsAfterDeletion(
    String deletedLessonId,
  ) async {
    try {
      // Get all staff users (they can see all lessons)
      final allUsers = await _userRepository.getAllUsers();
      final staffUsers = allUsers
          .where((user) => user.role == UserRole.staff)
          .toList();

      for (final user in staffUsers) {
        try {
          // Force refresh with latest data
          final refreshedEvents = await getUnifiedCalendarItems(
            userId: user.id,
            userRole: user.role,
            forceRefresh: true,
          );

          // Emit to stream for real-time updates
          _eventsStreamController.add(refreshedEvents);

          print(
            '✅ Repository: Refreshed events for staff user ${user.id} after deletion',
          );
        } catch (e) {
          print(
            '❌ Repository: Error refreshing events for user ${user.id}: $e',
          );
        }
      }
    } catch (e) {
      print('❌ Repository: Error in _refreshAllUsersEventsAfterDeletion: $e');
    }
  }

  /// Register an artist for a lesson
  Future<bool> registerArtistForLesson(String lessonId, String artistId) async {
    try {
      final result = await _lessonRepository.registerArtistForLesson(
        lessonId,
        artistId,
      );

      if (result) {
        // Get lesson to find instructor
        final lesson = await _lessonRepository.getLessonById(lessonId);
        final affectedUserIds = [artistId];
        if (lesson?.assignedInstructorId != null) {
          affectedUserIds.add(lesson!.assignedInstructorId!);
        }

        // Invalidate cache and refresh
        for (final userId in affectedUserIds) {
          _invalidateUserCache(userId);
        }
        await _refreshAndEmitEvents(affectedUserIds);
      }

      return result;
    } catch (e) {
      throw Exception('Failed to register artist for lesson: $e');
    }
  }

  /// Get available lessons for an artist
  Future<List<Lesson>> getAvailableLessonsForArtist(String artistId) async {
    try {
      return await _lessonRepository.getAvailableLessonsForArtist(artistId);
    } catch (e) {
      throw Exception('Failed to get available lessons: $e');
    }
  }

  /// Get events by type
  Future<List<UnifiedCalendarItem>> getEventsByType({
    required EventType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final calendarEvents = await _calendarRepository.getEventsByType(
        type,
        startDate: startDate,
        endDate: endDate,
      );

      return calendarEvents
          .map((event) => UnifiedCalendarItem.fromCalendarEvent(event))
          .toList();
    } catch (e) {
      throw Exception('Failed to get events by type: $e');
    }
  }

  /// Clear cache for a specific user
  void clearUserCache(String userId) {
    _invalidateUserCache(userId);
  }

  /// Clear all caches
  void clearAllCaches() {
    _userEventsCache.clear();
    _lastCacheUpdate = null;
  }

  // Private methods

  Future<List<CalendarEvent>> _getCalendarEventsForUser(
    String userId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    return await _calendarRepository.getEventsForUser(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<Lesson>> _getLessonsForUser(
    String userId,
    UserRole userRole,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    switch (userRole) {
      case UserRole.staff:
        return await _lessonRepository.getAllLessonsForStaff();
      case UserRole.mentor:
        return await _lessonRepository.getLessonsForMentor(
          userId,
          startDate: startDate,
          endDate: endDate,
        );
      case UserRole.client:
        return await _lessonRepository.getLessonsForArtist(
          userId,
          startDate:
              startDate ?? DateTime.now().subtract(const Duration(days: 30)),
          endDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
        );
    }
  }

  List<UnifiedCalendarItem> _filterByDateRange(
    List<UnifiedCalendarItem> items,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return items;

    return items.where((item) {
      if (startDate != null && item.startTime.isBefore(startDate)) return false;
      if (endDate != null && item.startTime.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  bool _isCacheValid(String userId) {
    if (!_userEventsCache.containsKey(userId) || _lastCacheUpdate == null) {
      return false;
    }

    final now = DateTime.now();
    return now.difference(_lastCacheUpdate!).compareTo(_cacheValidityDuration) <
        0;
  }

  void _invalidateUserCache(String userId) {
    _userEventsCache.remove(userId);
  }

  Future<void> _refreshAndEmitEvents(List<String> userIds) async {
    for (final userId in userIds) {
      try {
        final user = await _userRepository.getUserById(userId);
        if (user != null) {
          final refreshedEvents = await getUnifiedCalendarItems(
            userId: userId,
            userRole: user.role,
            forceRefresh: true,
          );
          _eventsStreamController.add(refreshedEvents);
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            'UnifiedCalendarRepository: Error refreshing events for user $userId: $e',
          );
        }
      }
    }
  }

  void dispose() {
    _eventsStreamController.close();
  }
}

/// Unified calendar item that can represent either a calendar event or a lesson
class UnifiedCalendarItem {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final CalendarItemType type;
  final Color color;
  final List<String> participantIds;
  final String? location;
  final CalendarEvent? originalEvent;
  final Lesson? originalLesson;

  UnifiedCalendarItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.color,
    required this.participantIds,
    this.location,
    this.originalEvent,
    this.originalLesson,
  });

  factory UnifiedCalendarItem.fromCalendarEvent(CalendarEvent event) {
    return UnifiedCalendarItem(
      id: event.id,
      title: event.title,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      type: CalendarItemType.event,
      color: _getEventTypeColor(event.type),
      participantIds: event.participantIds,
      location: event.locationOrLink,
      originalEvent: event,
    );
  }

  factory UnifiedCalendarItem.fromLesson(Lesson lesson) {
    return UnifiedCalendarItem(
      id: lesson.id,
      title: lesson.title,
      description: 'מנחה: ${lesson.instructorName ?? "טרם שויך"}',
      startTime: lesson.date,
      endTime: lesson.date.add(Duration(minutes: lesson.durationMinutes)),
      type: CalendarItemType.lesson,
      color: _getLessonStatusColor(lesson.status),
      participantIds: [
        if (lesson.assignedInstructorId != null) lesson.assignedInstructorId!,
        ...lesson.registeredArtistIds,
      ],
      originalLesson: lesson,
    );
  }

  int get durationInMinutes => endTime.difference(startTime).inMinutes;

  bool get isLesson => type == CalendarItemType.lesson;
  bool get isEvent => type == CalendarItemType.event;

  static Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.meeting:
        return const Color(0xFF3b82f6);
      case EventType.therapy:
        return const Color(0xFF10b981);
      case EventType.workshop:
        return const Color(0xFF8b5cf6);
      case EventType.other:
        return const Color(0xFF6b7280);
      case EventType.holiday:
        return const Color(0xFFef4444); // Red for holidays
      case EventType.special_event:
        return const Color(0xFFf59e0b); // Orange for special events
      case EventType.announcement:
        return const Color(0xFF06b6d4); // Cyan for announcements
    }
  }

  static Color _getLessonStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return const Color(0xFF3b82f6);
      case 'completed':
        return const Color(0xFF10b981);
      case 'cancelled':
        return const Color(0xFFef4444);
      default:
        return const Color(0xFF6b7280);
    }
  }
}

enum CalendarItemType { event, lesson }
