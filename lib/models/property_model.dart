import 'package:flutter/material.dart';


enum PropertyStatus {
  published,
  draft,
}


class Property {

  final String id;
  final String title;
  final String category;
  final double price;
  final String location;
  final String description;

  final int bedrooms;
  final double bathrooms;

  final String imageUrl;

  final PropertyStatus status;

  final String listedDate;
  final String lastUpdated;

  final List<IconData> amenities;


  Property({

    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.location,
    required this.description,

    required this.bedrooms,
    required this.bathrooms,

    required this.imageUrl,

    required this.status,

    required this.listedDate,
    required this.lastUpdated,

    required this.amenities,

  });

}