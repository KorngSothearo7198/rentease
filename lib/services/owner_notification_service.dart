import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/owner_notification_model.dart';

class OwnerNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // OWNER NOTIFICATIONS COLLECTION
  // ==========================================================

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('ownerNotifications');

  // ==========================================================
  // CREATE NOTIFICATION
  // ==========================================================

  Future<String> createNotification({
    required String userId,
    required String role,
    required String title,
    required String body,
    required String type,
    String? relatedId,
    String? relatedType,
    String? bookingId,
    String? houseId,
    String? paymentId,
    double? amount,
    String? currency,
  }) async {
    final doc = _collection.doc();

    await doc.set({
      'userId': userId,
      'role': role,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,

      'relatedId': relatedId,
      'relatedType': relatedType,

      'bookingId': bookingId,
      'houseId': houseId,
      'paymentId': paymentId,

      'amount': amount,
      'currency': currency,

      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // ==========================================================
  // GET USER NOTIFICATIONS
  // ==========================================================

  Stream<List<OwnerNotificationModel>> userNotifications(String userId) {
    return _collection.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final notifications = snapshot.docs
          .map((doc) => OwnerNotificationModel.fromFirestore(doc))
          .toList();

      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    });
  }

  // ==========================================================
  // GET UNREAD NOTIFICATIONS
  // ==========================================================

  Stream<List<OwnerNotificationModel>> unreadNotifications(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => OwnerNotificationModel.fromFirestore(doc))
              .toList();

          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return notifications;
        });
  }

  // ==========================================================
  // GET UNREAD COUNT
  // ==========================================================

  Stream<int> unreadCount(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==========================================================
  // MARK AS READ
  // ==========================================================

  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({'isRead': true});
  }

  // ==========================================================
  // MARK ALL AS READ
  // ==========================================================

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // ==========================================================
  // DELETE NOTIFICATION
  // ==========================================================

  Future<void> deleteNotification(String notificationId) async {
    await _collection.doc(notificationId).delete();
  }

  // ==========================================================
  // DELETE ALL USER NOTIFICATIONS
  // ==========================================================

  Future<void> deleteAllNotifications(String userId) async {
    final snapshot = await _collection.where('userId', isEqualTo: userId).get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
