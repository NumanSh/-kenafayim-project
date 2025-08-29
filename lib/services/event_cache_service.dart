import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/calendar_event.dart';

class EventCacheService {
  static const String _eventsCacheKey = 'cached_events';
  
  // Save events to local cache
  Future<void> cacheEvents(List<CalendarEvent> events, String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Convert events to JSON
      final List<Map<String, dynamic>> eventsMapList = events.map((e) => e.toMap()).toList();
      final String eventsJson = jsonEncode(eventsMapList);
      
      // Store with user-specific key
      await prefs.setString('${_eventsCacheKey}_$userId', eventsJson);
    } catch (e) {
      print('Error caching events: $e');
    }
  }
  
  // Retrieve events from local cache
  Future<List<CalendarEvent>> getCachedEvents(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? eventsJson = prefs.getString('${_eventsCacheKey}_$userId');
      
      if (eventsJson == null || eventsJson.isEmpty) {
        return [];
      }
      
      // Convert JSON back to events
      final List<dynamic> eventsMapList = jsonDecode(eventsJson);
      return eventsMapList
          .map((eventMap) => CalendarEvent.fromMap(Map<String, dynamic>.from(eventMap)))
          .toList();
    } catch (e) {
      print('Error retrieving cached events: $e');
      return [];
    }
  }
  
  // Clear cache for a specific user
  Future<void> clearCache(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_eventsCacheKey}_$userId');
    } catch (e) {
      print('Error clearing events cache: $e');
    }
  }
}
