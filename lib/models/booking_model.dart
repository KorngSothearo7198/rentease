// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class BookingModel {
//   final String? bookingId;
//
//   final String renterId;
//
//   final String ownerId;
//
//   final String houseId;
//
//   final String paymentStatus;
//   final String paymentId;
//
//   final Timestamp startDate;
//
//   final Timestamp endDate;
//
//   final int totalDays;
//
//   final double monthlyPrice;
//
//   final double totalAmount;
//
//   final String status;
//
//   final String? note;
//
//   final String? ownerNote;
//
//   final String? cancelReason;
//
//   final Timestamp createdAt;
//
//   final Timestamp updatedAt;
//
//   BookingModel({
//     this.bookingId,
//
//     required this.renterId,
//
//     required this.ownerId,
//
//     required this.houseId,
//
//     required this.paymentStatus,
//     required this.paymentId,
//
//     required this.startDate,
//
//     required this.endDate,
//
//     required this.totalDays,
//
//     required this.monthlyPrice,
//
//     required this.totalAmount,
//
//     required this.status,
//
//     this.note,
//
//     this.ownerNote,
//
//     this.cancelReason,
//
//     required this.createdAt,
//
//     required this.updatedAt,
//   });
//
//   // Convert Object -> Firestore
//
//   Map<String, dynamic> toMap() {
//     return {
//       "renterId": renterId,
//
//       "ownerId": ownerId,
//
//       "houseId": houseId,
//
//       "paymentStatus": paymentStatus,
//
//       "paymentId": paymentId,
//
//       "startDate": startDate,
//
//       "endDate": endDate,
//
//       "totalDays": totalDays,
//
//       "monthlyPrice": monthlyPrice,
//
//       "totalAmount": totalAmount,
//
//       "status": status,
//
//       "note": note ?? "",
//
//       "ownerNote": ownerNote ?? "",
//
//       "cancelReason": cancelReason ?? "",
//
//       "createdAt": createdAt,
//
//       "updatedAt": updatedAt,
//     };
//   }
//
//   // Firestore -> Object
//
//   factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
//     return BookingModel(
//       bookingId: id,
//
//       renterId: map["renterId"] ?? "",
//
//       ownerId: map["ownerId"] ?? "",
//
//       houseId: map["houseId"] ?? "",
//
//       paymentStatus: map["paymentStatus"] ?? "PENDING",
//
//       paymentId: map["paymentId"] ?? "",
//
//       startDate: map["startDate"],
//
//       endDate: map["endDate"],
//
//       totalDays: map["totalDays"] ?? 0,
//
//       monthlyPrice: (map["monthlyPrice"] ?? 0).toDouble(),
//
//       totalAmount: (map["totalAmount"] ?? 0).toDouble(),
//
//       status: map["status"] ?? "Pending",
//
//       note: map["note"],
//
//       ownerNote: map["ownerNote"],
//
//       cancelReason: map["cancelReason"],
//
//       createdAt: map["createdAt"],
//
//       updatedAt: map["updatedAt"],
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String? bookingId;

  final String renterId;
  final String ownerId;
  final String houseId;

  final String paymentStatus;
  final String paymentId;

  // Payment information
  final String? paymentMethod;
  final double? paidAmount;
  final String? paidCurrency;
  final Timestamp? paidAt;

  final Timestamp startDate;
  final Timestamp endDate;

  final int totalDays;

  final double monthlyPrice;
  final double totalAmount;

  final String status;

  final String? note;
  final String? ownerNote;
  final String? cancelReason;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  BookingModel({
    this.bookingId,

    required this.renterId,
    required this.ownerId,
    required this.houseId,

    required this.paymentStatus,
    required this.paymentId,

    this.paymentMethod,
    this.paidAmount,
    this.paidCurrency,
    this.paidAt,

    required this.startDate,
    required this.endDate,

    required this.totalDays,

    required this.monthlyPrice,
    required this.totalAmount,

    required this.status,

    this.note,
    this.ownerNote,
    this.cancelReason,

    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Object -> Firestore
  Map<String, dynamic> toMap() {
    return {
      "renterId": renterId,
      "ownerId": ownerId,
      "houseId": houseId,

      "paymentStatus": paymentStatus,
      "paymentId": paymentId,

      "paymentMethod": paymentMethod ?? "",
      "paidAmount": paidAmount,
      "paidCurrency": paidCurrency ?? "",
      "paidAt": paidAt,

      "startDate": startDate,
      "endDate": endDate,

      "totalDays": totalDays,

      "monthlyPrice": monthlyPrice,
      "totalAmount": totalAmount,

      "status": status,

      "note": note ?? "",
      "ownerNote": ownerNote ?? "",
      "cancelReason": cancelReason ?? "",

      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  // Firestore -> Object
  factory BookingModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return BookingModel(
      bookingId: id,

      renterId: map["renterId"]?.toString() ?? "",
      ownerId: map["ownerId"]?.toString() ?? "",
      houseId: map["houseId"]?.toString() ?? "",

      paymentStatus:
      map["paymentStatus"]?.toString() ?? "PENDING",

      paymentId:
      map["paymentId"]?.toString() ?? "",

      // Payment information
      paymentMethod:
      map["paymentMethod"]?.toString(),

      paidAmount:
      map["paidAmount"] == null
          ? null
          : (map["paidAmount"] as num).toDouble(),

      paidCurrency:
      map["paidCurrency"]?.toString(),

      paidAt:
      map["paidAt"] is Timestamp
          ? map["paidAt"] as Timestamp
          : null,

      startDate:
      map["startDate"] as Timestamp,

      endDate:
      map["endDate"] as Timestamp,

      totalDays:
      (map["totalDays"] ?? 0) as int,

      monthlyPrice:
      (map["monthlyPrice"] ?? 0 as num).toDouble(),

      totalAmount:
      (map["totalAmount"] ?? 0 as num).toDouble(),

      status:
      map["status"]?.toString() ?? "Pending",

      note:
      map["note"]?.toString(),

      ownerNote:
      map["ownerNote"]?.toString(),

      cancelReason:
      map["cancelReason"]?.toString(),

      createdAt:
      map["createdAt"] as Timestamp,

      updatedAt:
      map["updatedAt"] as Timestamp,
    );
  }
}