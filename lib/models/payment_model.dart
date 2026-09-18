import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;

  final String paymentId;

  final String bookingId;
  final String renterId;
  final String ownerId;
  final String houseId;

  final double amount;

  final String paymentMethod;

  final String status;

  final Timestamp createdAt;

  PaymentModel({
    required this.id,
    required this.paymentId,
    required this.bookingId,
    required this.renterId,
    required this.ownerId,
    required this.houseId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'bookingId': bookingId,
      'renterId': renterId,
      'ownerId': ownerId,
      'houseId': houseId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory PaymentModel.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    return PaymentModel(
      id: id,

      paymentId: map['paymentId'] ?? id,

      bookingId: map['bookingId'] ?? '',

      renterId: map['renterId'] ?? '',

      ownerId: map['ownerId'] ?? '',

      houseId: map['houseId'] ?? '',

      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,

      paymentMethod: map['paymentMethod'] ?? '',

      status: map['status'] ?? '',

      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt'] as Timestamp
          : Timestamp.now(),
    );
  }
}