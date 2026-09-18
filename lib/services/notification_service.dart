import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNotification({
    required String userId,

    required String ownerId,

    required String bookingId,

    required String houseId,

    required String title,

    required String body,

    required String type,
  }) async {
    await FirebaseFirestore.instance.collection("notifications").add({
      "userId": userId,

      "ownerId": ownerId,

      "bookingId": bookingId,

      "houseId": houseId,

      "title": title,

      "body": body,

      "type": type,

      "isRead": false,

      "createdAt": Timestamp.now(),
    });
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(notificationId)
        .update({"isRead": true});
  }

  Stream<int> getUnreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

}
