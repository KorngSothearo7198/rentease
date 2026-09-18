import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billing;
  final List<String> features;
  final int propertyLimit;
  final int displayOrder;
  final int level;
  final bool popular;
  final bool recommended;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billing,
    required this.features,
    required this.propertyLimit,
    required this.displayOrder,
    required this.level,
    required this.popular,
    required this.recommended,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanModel.fromFirestore(
      Map<String, dynamic> data,
      String documentId,
      ) {
    return SubscriptionPlanModel(
      id: data['id']?.toString() ?? documentId,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency']?.toString() ?? 'USD',
      billing: data['billing']?.toString() ?? 'month',

      features: (data['features'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],

      propertyLimit: (data['propertyLimit'] as num?)?.toInt() ?? 0,

      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 0,

      level: (data['level'] as num?)?.toInt() ?? 0,

      popular: data['popular'] == true,

      recommended: data['recommended'] == true,

      status: data['status']?.toString() ?? 'inactive',

      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),

      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}