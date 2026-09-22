import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;

  final String paymentId;

  final String bookingId;
  final String renterId;
  final String ownerId;
  final String houseId;

  // ============================================================
  // ACTUAL PAYMENT
  // ============================================================

  final double amount;
  final String currency;

  // ============================================================
  // BOOKING AMOUNT
  // ============================================================

  final double bookingAmount;
  final String bookingCurrency;

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
    required this.currency,
    required this.bookingAmount,
    required this.bookingCurrency,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'bookingId': bookingId,
      'renterId': renterId,
      'ownerId': ownerId,
      'houseId': houseId,

      // Actual payment
      'amount': amount,
      'currency': currency,

      // Booking amount
      'bookingAmount': bookingAmount,
      'bookingCurrency': bookingCurrency,

      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory PaymentModel.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    return PaymentModel(
      id: id,

      paymentId: map['paymentId']?.toString() ?? id,

      bookingId: map['bookingId']?.toString() ?? '',

      renterId: map['renterId']?.toString() ?? '',

      ownerId: map['ownerId']?.toString() ?? '',

      houseId: map['houseId']?.toString() ?? '',

      // ========================================================
      // ACTUAL PAYMENT
      // ========================================================

      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,

      currency: map['currency']?.toString() ?? 'KHR',

      // ========================================================
      // BOOKING AMOUNT
      // ========================================================

      bookingAmount:
      (map['bookingAmount'] as num?)?.toDouble() ?? 0.0,

      bookingCurrency:
      map['bookingCurrency']?.toString() ?? 'USD',

      paymentMethod:
      map['paymentMethod']?.toString() ?? '',

      status:
      map['status']?.toString() ?? '',

      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt'] as Timestamp
          : Timestamp.now(),
    );
  }
}