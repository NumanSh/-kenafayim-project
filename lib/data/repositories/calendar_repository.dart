import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';
import '../../services/event_cache_service.dart';

class CalendarRepository {
  final FirebaseFirestore _firestore;
  final EventCacheService _cacheService = EventCacheService();

  CalendarRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<CalendarEvent>> getEventsForUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<CalendarEvent> events = [];

    try {
      // First try to get cached events
      events = await _cacheService.getCachedEvents(userId);

      // Filter cached events if date range is specified
      if (events.isNotEmpty) {
        if (startDate != null) {
          events = events
              .where(
                (e) =>
                    e.startTime.isAfter(startDate) ||
                    e.startTime.isAtSameMomentAs(startDate),
              )
              .toList();
        }
        if (endDate != null) {
          events = events
              .where(
                (e) =>
                    e.startTime.isBefore(endDate) ||
                    e.startTime.isAtSameMomentAs(endDate),
              )
              .toList();
        }
      }

      // Try to fetch from Firestore if online
      try {
        Query query = _firestore
            .collection('events')
            .where('participantIds', arrayContains: userId)
            .orderBy('startTime');

        if (startDate != null) {
          query = query.where(
            'startTime',
            isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
          );
        }

        if (endDate != null) {
          query = query.where(
            'startTime',
            isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
          );
        }

        final querySnapshot = await query.get();

        events = querySnapshot.docs
            .map(
              (doc) => CalendarEvent.fromMap(
                Map<String, dynamic>.from({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }),
              ),
            )
            .toList();

        // Cache the fetched events
        await _cacheService.cacheEvents(events, userId);
      } catch (e) {
        // If fetching from Firestore fails, we'll use the cached events
        print('Using cached events due to Firestore error: $e');
      }

      return events;
    } catch (e) {
      throw Exception('Failed to get events: $e');
    }
  }

  Future<List<CalendarEvent>> getEventsByType(
    EventType type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('events')
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('startTime');

      if (startDate != null) {
        query = query.where(
          'startTime',
          isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
        );
      }

      if (endDate != null) {
        query = query.where(
          'startTime',
          isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
        );
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map(
            (doc) => CalendarEvent.fromMap(
              Map<String, dynamic>.from({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get events by type: $e');
    }
  }

  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      final docRef = await _firestore.collection('events').add(event.toMap());
      final createdEvent = CalendarEvent.fromMap({
        ...event.toMap(),
        'id': docRef.id,
      });

      // Update cache for all participants
      for (String participantId in event.participantIds) {
        List<CalendarEvent> cachedEvents = await _cacheService.getCachedEvents(
          participantId,
        );
        cachedEvents.add(createdEvent);
        await _cacheService.cacheEvents(cachedEvents, participantId);
      }

      return createdEvent;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    try {
      await _firestore.collection('events').doc(event.id).update(event.toMap());

      // Update cache for all participants
      for (String participantId in event.participantIds) {
        List<CalendarEvent> cachedEvents = await _cacheService.getCachedEvents(
          participantId,
        );
        cachedEvents.removeWhere((e) => e.id == event.id);
        cachedEvents.add(event);
        await _cacheService.cacheEvents(cachedEvents, participantId);
      }
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      // Get the event first to know which participants to update
      final docSnapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .get();
      if (docSnapshot.exists) {
        final event = CalendarEvent.fromMap(
          Map<String, dynamic>.from({
            ...docSnapshot.data() as Map<String, dynamic>,
            'id': docSnapshot.id,
          }),
        );

        // Delete from Firestore
        await _firestore.collection('events').doc(eventId).delete();

        // Update cache for all participants
        for (String participantId in event.participantIds) {
          List<CalendarEvent> cachedEvents = await _cacheService
              .getCachedEvents(participantId);
          cachedEvents.removeWhere((e) => e.id == eventId);
          await _cacheService.cacheEvents(cachedEvents, participantId);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }
  // Add these methods to your existing CalendarRepository class

  // Get all public events (holidays, announcements) for everyone
  Future<List<CalendarEvent>> getPublicEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('events')
          .where('type', whereIn: ['holiday', 'announcement', 'special_event']);

      if (startDate != null) {
        query = query.where(
          'startTime',
          isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
        );
      }

      if (endDate != null) {
        query = query.where(
          'startTime',
          isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
        );
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map(
            (doc) => CalendarEvent.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      // Sort by start time
      events.sort((a, b) => a.startTime.compareTo(b.startTime));

      return events;
    } catch (e) {
      print('Error getting public events: $e');
      return [];
    }
  }

  // Get all events for staff management
  Future<List<CalendarEvent>> getAllEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('events');

      if (startDate != null) {
        query = query.where(
          'startTime',
          isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
        );
      }

      if (endDate != null) {
        query = query.where(
          'startTime',
          isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
        );
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map(
            (doc) => CalendarEvent.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      // Sort by start time
      events.sort((a, b) => a.startTime.compareTo(b.startTime));

      return events;
    } catch (e) {
      print('Error getting all events: $e');
      return [];
    }
  }

  // Get holidays only
  Future<List<CalendarEvent>> getHolidays({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('events')
          .where('type', isEqualTo: 'holiday');

      if (startDate != null) {
        query = query.where(
          'startTime',
          isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
        );
      }

      if (endDate != null) {
        query = query.where(
          'startTime',
          isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
        );
      }

      final querySnapshot = await query.get();

      final events = querySnapshot.docs
          .map(
            (doc) => CalendarEvent.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      // Sort by start time
      events.sort((a, b) => a.startTime.compareTo(b.startTime));

      return events;
    } catch (e) {
      print('Error getting holidays: $e');
      return [];
    }
  }

  // Get events by date range for calendar view
  Future<Map<DateTime, List<CalendarEvent>>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? userId,
  }) async {
    try {
      List<CalendarEvent> events = [];

      if (userId != null) {
        // Get user-specific events
        events = await getEventsForUser(
          userId,
          startDate: startDate,
          endDate: endDate,
        );
      }

      // Always include public events
      final publicEvents = await getPublicEvents(
        startDate: startDate,
        endDate: endDate,
      );
      events.addAll(publicEvents);

      // Remove duplicates based on ID
      final uniqueEvents = <String, CalendarEvent>{};
      for (final event in events) {
        uniqueEvents[event.id] = event;
      }

      // Group events by date
      final Map<DateTime, List<CalendarEvent>> eventsByDate = {};

      for (final event in uniqueEvents.values) {
        final eventDate = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );

        eventsByDate.putIfAbsent(eventDate, () => []).add(event);
      }

      // Sort events within each date
      eventsByDate.forEach((date, events) {
        events.sort((a, b) => a.startTime.compareTo(b.startTime));
      });

      return eventsByDate;
    } catch (e) {
      print('Error getting events by date range: $e');
      return {};
    }
  }

  // Get events for a specific day only (optimized query)
}
