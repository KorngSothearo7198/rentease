import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String subscriptionId;
  final String ownerId;

  final String planId;
  final String planName;

  final double amount;
  final String currency;

  final String status;

  final String paymentMethod;
  final String paymentReference;

  final DateTime? startDate;
  final DateTime? endDate;

  final DateTime createdAt;
  final DateTime? updatedAt;

  final String approvedBy;
  final DateTime? approvedAt;

  const SubscriptionModel({
    required this.subscriptionId,
    required this.ownerId,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.paymentReference,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.approvedBy,
    required this.approvedAt,
  });

  factory SubscriptionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SubscriptionModel(
      subscriptionId: data['subscriptionId'] ?? doc.id,

      ownerId: data['ownerId'] ?? '',

      planId: data['planId'] ?? '',

      planName: data['planName'] ?? '',

      amount: (data['amount'] ?? 0).toDouble(),

      currency: data['currency'] ?? 'USD',

      status: data['status'] ?? 'pending',

      paymentMethod: data['paymentMethod'] ?? '',

      paymentReference: data['paymentReference'] ?? '',

      startDate: _timestampToDate(data['startDate']),

      endDate: _timestampToDate(data['endDate']),

      createdAt: _timestampToDate(data['createdAt']) ?? DateTime.now(),

      updatedAt: _timestampToDate(data['updatedAt']),

      approvedBy: data['approvedBy'] ?? '',

      approvedAt: _timestampToDate(data['approvedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subscriptionId': subscriptionId,
      'ownerId': ownerId,

      'planId': planId,
      'planName': planName,

      'amount': amount,
      'currency': currency,

      'status': status,

      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,

      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,

      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,

      'createdAt': Timestamp.fromDate(createdAt),

      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,

      'approvedBy': approvedBy,

      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  SubscriptionModel copyWith({
    String? status,
    String? paymentReference,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedAt,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return SubscriptionModel(
      subscriptionId: subscriptionId,
      ownerId: ownerId,
      planId: planId,
      planName: planName,
      amount: amount,
      currency: currency,

      status: status ?? this.status,

      paymentMethod: paymentMethod,

      paymentReference: paymentReference ?? this.paymentReference,

      startDate: startDate ?? this.startDate,

      endDate: endDate ?? this.endDate,

      createdAt: createdAt,

      updatedAt: updatedAt ?? this.updatedAt,

      approvedBy: approvedBy ?? this.approvedBy,

      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
