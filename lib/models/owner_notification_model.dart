import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerNotificationModel {
  // ============================================================
  // BASIC NOTIFICATION
  // ============================================================

  final String notificationId;
  final String userId;
  final String role;
  final String title;
  final String body;
  final String type;
  final bool isRead;

  // ============================================================
  // RELATED INFORMATION
  // ============================================================

  final String? relatedId;
  final String? relatedType;

  // ============================================================
  // PAYMENT / BOOKING INFORMATION
  // ============================================================

  final String? bookingId;
  final String? houseId;
  final String? paymentId;

  final double? amount;
  final String? currency;

  // ============================================================
  // DATE
  // ============================================================

  final DateTime createdAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  OwnerNotificationModel({
    required this.notificationId,
    required this.userId,
    required this.role,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,

    this.relatedId,
    this.relatedType,

    this.bookingId,
    this.houseId,
    this.paymentId,

    this.amount,
    this.currency,

    required this.createdAt,
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory OwnerNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return OwnerNotificationModel(
      // ----------------------------------------------------------
      // BASIC
      // ----------------------------------------------------------
      notificationId: doc.id,

      userId: data['userId']?.toString() ?? '',

      role: data['role']?.toString() ?? '',

      title: data['title']?.toString() ?? '',

      body: data['body']?.toString() ?? '',

      type: data['type']?.toString() ?? '',

      isRead: data['isRead'] == true,

      // ----------------------------------------------------------
      // RELATED
      // ----------------------------------------------------------
      relatedId: data['relatedId']?.toString(),

      relatedType: data['relatedType']?.toString(),

      // ----------------------------------------------------------
      // PAYMENT / BOOKING
      // ----------------------------------------------------------
      bookingId: data['bookingId']?.toString(),

      houseId: data['houseId']?.toString(),

      paymentId: data['paymentId']?.toString(),

      amount: _parseDouble(data['amount']),

      currency: data['currency']?.toString(),

      // ----------------------------------------------------------
      // DATE
      // ----------------------------------------------------------
      createdAt: _parseDate(data['createdAt']),
    );
  }

  // ============================================================
  // PARSE DOUBLE
  // ============================================================

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final parsed = double.tryParse(value.toString());

    return parsed;
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      // ----------------------------------------------------------
      // BASIC
      // ----------------------------------------------------------
      'userId': userId,
      'role': role,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      // ----------------------------------------------------------
      // RELATED
      // ----------------------------------------------------------
      'relatedId': relatedId,
      'relatedType': relatedType,
      // ----------------------------------------------------------
      // PAYMENT / BOOKING
      // ----------------------------------------------------------
      'bookingId': bookingId,
      'houseId': houseId,
      'paymentId': paymentId,
      'amount': amount,
      'currency': currency,
      // ----------------------------------------------------------
      // DATE
      // ----------------------------------------------------------
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
