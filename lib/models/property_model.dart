import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyStatus { published, draft }

class Property {
  final String id;

  final String ownerId;

  final String title;

  final String category;

  final double price;

  final String location;

  // final double latitude;
  // final double longitude;

  final String description;

  final int bedrooms;

  final double bathrooms;

  final String imageUrl;

  final List<String> amenities;

  final PropertyStatus status;

  final Timestamp createdAt;

  final Timestamp updatedAt;

  Property({
    required this.id,

    required this.ownerId,

    required this.title,

    required this.category,

    required this.price,

    required this.location,

    required this.description,

    required this.bedrooms,

    required this.bathrooms,

    required this.imageUrl,

    required this.amenities,

    // required this.latitude,
    // required this.longitude,
    required this.status,

    required this.createdAt,

    required this.updatedAt,
  });

  factory Property.fromMap(Map<String, dynamic> map, String id) {
    return Property(
      id: id,

      ownerId: map["ownerId"],

      title: map["title"],

      category: map["category"],

      price: (map["price"] ?? 0).toDouble(),

      location: map["location"],

      description: map["description"],

      bedrooms: map["bedrooms"] ?? 0,

      bathrooms: (map["bathrooms"] ?? 0).toDouble(),

      imageUrl: map["imageUrl"],

      amenities: List<String>.from(map["amenities"] ?? []),

      // latitude: (map["latitude"] ?? 0).toDouble(),
      //
      // longitude: (map["longitude"] ?? 0).toDouble(),
      status: map["status"] == "published"
          ? PropertyStatus.published
          : PropertyStatus.draft,

      createdAt: map["createdAt"],

      updatedAt: map["updatedAt"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "ownerId": ownerId,

      "title": title,

      "category": category,

      "price": price,

      "location": location,

      "description": description,

      "bedrooms": bedrooms,

      "bathrooms": bathrooms,

      "imageUrl": imageUrl,

      "amenities": amenities,

      // "latitude": latitude,
      // "longitude": longitude,
      "status": status.name,

      "createdAt": createdAt,

      "updatedAt": updatedAt,
    };
  }
}
