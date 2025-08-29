import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get bookings for a user
  // Get bookings for a user
  Future<List<Booking>> getBookingsForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Booking.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user bookings: $e');
      }
      return [];
    }
  }

  // Get bookings for a room
  Future<List<Booking>> getBookingsForRoom(
    String roomId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('bookings')
          .where('roomId', isEqualTo: roomId);

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

      final querySnapshot = await query.orderBy('startTime').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Booking.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting room bookings: $e');
      }
      return [];
    }
  }

  // Get all bookings (for staff)
  Future<List<Booking>> getAllBookings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('bookings');

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

      final querySnapshot = await query
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Booking.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all bookings: $e');
      }
      return [];
    }
  }

  // Get pending bookings (for staff approval)
  Future<List<Booking>> getPendingBookings() async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Booking.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending bookings: $e');
      }
      return [];
    }
  }

  // Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final docSnapshot = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          return Booking.fromMap({...data, 'id': docSnapshot.id});
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting booking by ID: $e');
      }
      return null;
    }
  }

  // Get today's bookings
  Future<List<Booking>> getTodaysBookings() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('bookings')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch,
          )
          .where(
            'startTime',
            isLessThanOrEqualTo: endOfDay.millisecondsSinceEpoch,
          )
          .where('status', whereIn: ['approved', 'pending'])
          .orderBy('startTime')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Booking.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting today\'s bookings: $e');
      }
      return [];
    }
  }

  // Create new booking
  Future<String?> createBooking(Booking booking) async {
    try {
      final docRef = await _firestore
          .collection('bookings')
          .add(
            booking
                .copyWith(
                  createdAt: DateTime.now(),
                  lastModified: DateTime.now(),
                )
                .toMap(),
          );

      if (kDebugMode) {
        print('Booking created: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating booking: $e');
      }
      return null;
    }
  }

  // Update booking
  Future<bool> updateBooking(Booking booking) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(booking.id)
          .update(booking.copyWith(lastModified: DateTime.now()).toMap());

      if (kDebugMode) {
        print('Booking updated: ${booking.id}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating booking: $e');
      }
      return false;
    }
  }

  // Approve booking
  Future<bool> approveBooking(String bookingId, String approvedBy) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      });

      if (kDebugMode) {
        print('Booking approved: $bookingId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error approving booking: $e');
      }
      return false;
    }
  }

  // Reject booking
  Future<bool> rejectBooking(
    String bookingId,
    String rejectedBy,
    String reason,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'rejected',
        'approvedBy': rejectedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'lastModified': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Booking rejected: $bookingId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting booking: $e');
      }
      return false;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'lastModified': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Booking cancelled: $bookingId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling booking: $e');
      }
      return false;
    }
  }

  // Delete booking
  Future<bool> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();

      if (kDebugMode) {
        print('Booking deleted: $bookingId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting booking: $e');
      }
      return false;
    }
  }

  // Get booking by ID

  // Bulk approve bookings
  Future<bool> bulkApproveBookings(
    List<String> bookingIds,
    String approvedBy,
  ) async {
    try {
      final batch = _firestore.batch();

      for (String id in bookingIds) {
        final docRef = _firestore.collection('bookings').doc(id);
        batch.update(docRef, {
          'status': 'approved',
          'approvedBy': approvedBy,
          'approvedAt': FieldValue.serverTimestamp(),
          'lastModified': FieldValue.serverTimestamp(),
          'rejectionReason': null,
        });
      }

      await batch.commit();

      if (kDebugMode) {
        print('Bulk approved ${bookingIds.length} bookings');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error bulk approving bookings: $e');
      }
      return false;
    }
  }
}
