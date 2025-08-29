import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/room.dart';

class RoomRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all rooms
  Future<List<Room>> getAllRooms() async {
    try {
      final querySnapshot = await _firestore.collection('rooms').get();

      if (querySnapshot.docs.isEmpty) {
        // Initialize default rooms if none exist
        await _initializeDefaultRooms();
        return KnafayimRooms.getDefaultRooms();
      }

      return querySnapshot.docs
          .map((doc) => Room.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting rooms: $e');
      }
      return KnafayimRooms.getDefaultRooms(); // Fallback to default rooms
    }
  }

  // Get room by ID
  Future<Room?> getRoomById(String roomId) async {
    try {
      final docSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .get();

      if (docSnapshot.exists) {
        return Room.fromMap({...docSnapshot.data()!, 'id': docSnapshot.id});
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting room by ID: $e');
      }
      return null;
    }
  }

  // Get rooms by type
  Future<List<Room>> getRoomsByType(RoomType type) async {
    try {
      final querySnapshot = await _firestore
          .collection('rooms')
          .where('type', isEqualTo: type.toString().split('.').last)
          .get();

      return querySnapshot.docs
          .map((doc) => Room.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting rooms by type: $e');
      }
      return [];
    }
  }

  // Get available rooms
  Future<List<Room>> getAvailableRooms() async {
    try {
      final querySnapshot = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: 'available')
          .get();

      return querySnapshot.docs
          .map((doc) => Room.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available rooms: $e');
      }
      return [];
    }
  }

  // Update room status
  Future<bool> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'status': status.toString().split('.').last,
      });

      if (kDebugMode) {
        print('Room status updated: $roomId -> $status');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating room status: $e');
      }
      return false;
    }
  }

  // Add or update room
  Future<bool> saveRoom(Room room) async {
    try {
      await _firestore.collection('rooms').doc(room.id).set(room.toMap());

      if (kDebugMode) {
        print('Room saved: ${room.id}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving room: $e');
      }
      return false;
    }
  }

  // Initialize default rooms in Firestore
  Future<void> _initializeDefaultRooms() async {
    try {
      final defaultRooms = KnafayimRooms.getDefaultRooms();
      final batch = _firestore.batch();

      for (final room in defaultRooms) {
        final docRef = _firestore.collection('rooms').doc(room.id);
        batch.set(docRef, room.toMap());
      }

      await batch.commit();

      if (kDebugMode) {
        print('Default rooms initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing default rooms: $e');
      }
    }
  }

  // Check room availability for a time slot
  Future<bool> isRoomAvailable(
    String roomId,
    DateTime startTime,
    DateTime endTime, {
    String? excludeBookingId,
  }) async {
    try {
      // Check if room exists and is available
      final room = await getRoomById(roomId);
      if (room == null || !room.isAvailable) {
        return false;
      }

      // Check for conflicting bookings
      Query query = _firestore
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('status', whereIn: ['pending', 'approved']);

      final querySnapshot = await query.get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Skip the booking we're excluding (for updates)
        if (excludeBookingId != null && doc.id == excludeBookingId) {
          continue;
        }

        final bookingStart = DateTime.fromMillisecondsSinceEpoch(
          data['startTime'],
        );
        final bookingEnd = DateTime.fromMillisecondsSinceEpoch(data['endTime']);

        // Check for time overlap
        if (startTime.isBefore(bookingEnd) && endTime.isAfter(bookingStart)) {
          return false; // Conflict found
        }
      }

      return true; // No conflicts
    } catch (e) {
      if (kDebugMode) {
        print('Error checking room availability: $e');
      }
      return false;
    }
  }

  // Get room utilization stats
  Future<Map<String, dynamic>> getRoomStats(String roomId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final querySnapshot = await _firestore
          .collection('bookings')
          .where('roomId', isEqualTo: roomId)
          .where('status', isEqualTo: 'approved')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: startOfMonth.millisecondsSinceEpoch,
          )
          .where(
            'startTime',
            isLessThanOrEqualTo: endOfMonth.millisecondsSinceEpoch,
          )
          .get();

      int totalBookings = querySnapshot.docs.length;
      int totalHours = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final startTime = DateTime.fromMillisecondsSinceEpoch(
          data['startTime'],
        );
        final endTime = DateTime.fromMillisecondsSinceEpoch(data['endTime']);
        totalHours += endTime.difference(startTime).inHours;
      }

      return {
        'totalBookings': totalBookings,
        'totalHours': totalHours,
        'averageBookingDuration': totalBookings > 0
            ? totalHours / totalBookings
            : 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting room stats: $e');
      }
      return {'totalBookings': 0, 'totalHours': 0, 'averageBookingDuration': 0};
    }
  }
}
