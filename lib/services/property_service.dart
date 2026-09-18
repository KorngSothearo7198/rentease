// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../models/property_model.dart';
//
// class PropertyService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   Future<String> createProperty(Property property) async {
//     final doc = await _db.collection("properties").add(property.toMap());
//
//     return doc.id;
//   }
//
//   Stream<List<Property>> getOwnerProperties(String ownerId) {
//     return _db
//         .collection("properties")
//         .where("ownerId", isEqualTo: ownerId)
//         .orderBy("createdAt", descending: true)
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs.map((doc) {
//             return Property.fromMap(doc.data(), doc.id);
//           }).toList();
//         });
//   }
//
//   Future<void> deleteProperty(String id) async {
//     await _db.collection("properties").doc(id).delete();
//   }
//
//   Future<void> updateProperty(String id, Map<String, dynamic> data) async {
//     await _db.collection("properties").doc(id).update({
//       ...data,
//
//       "updatedAt": Timestamp.now(),
//     });
//   }
//
//
//   // home screen
//   Stream<List<Property>> getPublishedProperties() {
//     return FirebaseFirestore.instance
//         .collection("properties")
//         // .where("status", isEqualTo: "Published")
//         .orderBy("createdAt", descending: true)
//
//         .snapshots()
//         .map((snapshot) {
//
//         print("Documents: ${snapshot.docs.length}");
//
//       for (var doc in snapshot.docs) {
//         print(doc.data());
//       }
//
//       return snapshot.docs
//           .map((e) => Property.fromMap(e.data(), e.id))
//           .toList();
//     });
//   }
//
//
//   Future<List<Property>> getProperties() async {
//
//     final snapshot = await FirebaseFirestore
//         .instance
//         .collection("properties")
//         .get();
//
//
//     return snapshot.docs.map((doc){
//
//       return Property.fromMap(
//         doc.data(),
//         doc.id,
//       );
//
//     }).toList();
//
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/property_model.dart';

class PropertyPageResult {
  final List<Property> properties;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const PropertyPageResult({
    required this.properties,
    required this.lastDocument,
    required this.hasMore,
  });
}

class PropertyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> createProperty(Property property) async {
    final doc = await _db
        .collection('properties')
        .add(property.toMap());

    return doc.id;
  }

  // ============================================================
  // OWNER PROPERTIES
  // ============================================================

  Stream<List<Property>> getOwnerProperties(String ownerId) {
    return _db
        .collection('properties')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteProperty(String id) async {
    await _db
        .collection('properties')
        .doc(id)
        .delete();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateProperty(
      String id,
      Map<String, dynamic> data,
      ) async {
    await _db
        .collection('properties')
        .doc(id)
        .update({
      ...data,
      'updatedAt': Timestamp.now(),
    });
  }

  // ============================================================
  // ALL PUBLISHED PROPERTIES - REALTIME
  // ============================================================

  Stream<List<Property>> getPublishedProperties() {
    return _db
        .collection('properties')
        .where(
      'status',
      isEqualTo: 'published',
    )
        .orderBy(
      'createdAt',
      descending: true,
    )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }

  // ============================================================
  // GET ALL PROPERTIES
  // ============================================================

  Future<List<Property>> getProperties() async {
    final snapshot = await _db
        .collection('properties')
        .get();

    return snapshot.docs.map((doc) {
      return Property.fromMap(
        doc.data(),
        doc.id,
      );
    }).toList();
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Future<PropertyPageResult> getPublishedPropertiesPage({
    int limit = 6,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('properties')
        .where(
      'status',
      isEqualTo: 'published',
    )
        .orderBy(
      'createdAt',
      descending: true,
    )
        .limit(limit);

    // Continue from previous page
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    final properties = snapshot.docs.map((doc) {
      return Property.fromMap(
        doc.data(),
        doc.id,
      );
    }).toList();

    return PropertyPageResult(
      properties: properties,

      lastDocument: snapshot.docs.isNotEmpty
          ? snapshot.docs.last
          : null,

      hasMore: snapshot.docs.length == limit,
    );
  }
}