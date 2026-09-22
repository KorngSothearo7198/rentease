import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../models/booking_model.dart';
import '../models/owner_notification_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================
  // CREATE BOOKING
  // ==========================

  Future<String?> createBooking(BookingModel booking) async {
    try {
      DocumentReference ref = await _firestore
          .collection("bookings")
          .add(booking.toMap());

      return ref.id;
    } catch (e) {
      print("Create Booking Error: $e");

      return null;
    }
  }

  // ==========================
  // GET RENTER BOOKINGS
  // ==========================

  Stream<List<BookingModel>> getRenterBookings(String renterId) {
    return _firestore
        .collection("bookings")
        .where("renterId", isEqualTo: renterId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // ==========================
  // OWNER VIEW REQUEST
  // ==========================

  Stream<List<BookingModel>> getOwnerBookings(String ownerId) {
    return _firestore
        .collection("bookings")
        .where("ownerId", isEqualTo: ownerId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }


  Future<void> approveBooking(BookingModel booking) async {
    try {
      final batch = _firestore.batch();

      final bookingRef = _firestore
          .collection("bookings")
          .doc(booking.bookingId);

      final propertyRef = _firestore
          .collection("properties")
          .doc(booking.houseId);

      batch.update(bookingRef, {
        "status": "Approved",
        "updatedAt": Timestamp.now(),
      });

      batch.update(propertyRef, {
        "status": "rented",
        "updatedAt": Timestamp.now(),
      });

      await batch.commit();

      print("✅ Booking approved");
      print("✅ Property ${booking.houseId} → rented");
    } catch (e) {
      print("❌ Approve booking error: $e");
      rethrow;
    }
  }


// ==========================
// REJECT BOOKING
// ==========================

  Future<void> rejectBooking(String bookingId) async {
    try {
      await _firestore
          .collection("bookings")
          .doc(bookingId)
          .update({
        "status": "Rejected",
        "updatedAt": Timestamp.now(),
      });

      print("✅ Booking rejected");
    } catch (e) {
      print("❌ Reject booking error: $e");
      rethrow;
    }
  }


// ==========================
// CANCEL BOOKING
// ==========================

  Future<void> cancelBooking(
      String bookingId,
      String reason,
      ) async {
    try {
      await _firestore
          .collection("bookings")
          .doc(bookingId)
          .update({
        "status": "Cancelled",
        "cancelReason": reason,
        "updatedAt": Timestamp.now(),
      });

      print("✅ Booking cancelled");
    } catch (e) {
      print("❌ Cancel booking error: $e");
      rethrow;
    }
  }


  Future<void> createOwnerCancellationNotification({
    required String ownerId,
    required String bookingId,
    required String houseId,
    required String propertyName,
    required String cancelReason,
    required double bookingAmount,
  }) async {
    try {
      final notificationRef =
      FirebaseFirestore.instance.collection('ownerNotifications').doc();

      final notification = OwnerNotificationModel(
        notificationId: notificationRef.id,

        // Notification belongs to OWNER
        userId: ownerId,

        role: 'owner',

        title: 'Booking Cancelled',

        body:
        'A renter has cancelled the booking for "$propertyName". '
            'Reason: $cancelReason',

        type: 'booking_cancelled',

        isRead: false,

        relatedId: bookingId,

        relatedType: 'booking',

        bookingId: bookingId,

        houseId: houseId,

        // No payment was completed because this booking
        // was eligible for cancellation.
        paymentId: null,

        // Booking amount, NOT Bakong transaction amount.
        amount: bookingAmount,

        currency: 'USD',

        createdAt: DateTime.now(),
      );

      await notificationRef.set(
        notification.toFirestore(),
      );

      debugPrint('======================================');
      debugPrint('OWNER CANCELLATION NOTIFICATION');
      debugPrint('======================================');
      debugPrint('Notification ID : ${notificationRef.id}');
      debugPrint('Owner ID        : $ownerId');
      debugPrint('Booking ID      : $bookingId');
      debugPrint('House ID        : $houseId');
      debugPrint('Property        : $propertyName');
      debugPrint('Type            : booking_cancelled');
      debugPrint('Amount          : $bookingAmount USD');
      debugPrint('Reason          : $cancelReason');
      debugPrint('======================================');
    } catch (e) {
      debugPrint(
        'Create owner cancellation notification error: $e',
      );

      rethrow;
    }
  }



  Future<BookingModel?> getBookingById(String bookingId) async {
    final snapshot = await _firestore
        .collection("bookings")
        .doc(bookingId)
        .get();

    if (snapshot.exists) {
      return BookingModel.fromMap(snapshot.data()!, snapshot.id);
    }

    return null;
  }

  Future<String?> getHouseName(String houseId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('properties')
          .doc(houseId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return doc.data()?['title'] as String?;
    } catch (e) {
      print('❌ Get house name error: $e');
      return null;
    }
  }

  Future<String?> getUserName(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return doc.data()?['fullName'] as String?;
    } catch (e) {
      print('❌ Get user name error: $e');
      return null;
    }
  }
}
