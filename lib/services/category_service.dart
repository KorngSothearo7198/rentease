import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final CollectionReference _categoryCollection =
  FirebaseFirestore.instance.collection('categories');

  // ===========================================================================
  // 1. CREATE
  // ===========================================================================

  /// Create a new category in Firestore.
  /// Generates a auto-id if [category.id] is empty.
  Future<String> createCategory(CategoryModel category) async {
    try {
      // Prevent duplicate category names (Case-insensitive comparison)
      bool exists = await categoryExistsByName(category.name);
      if (exists) {
        throw Exception('A category with the name "${category.name}" already exists.');
      }

      DocumentReference docRef = await _categoryCollection.add(category.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // ===========================================================================
  // 2. READ (Streams & Futures)
  // ===========================================================================

  /// Get a real-time stream of all categories sorted by name.
  Stream<List<CategoryModel>> getCategories() {
    return _categoryCollection
        .orderBy('name', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Get a single category by ID in real-time.
  Stream<CategoryModel?> streamCategoryById(String id) {
    return _categoryCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CategoryModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  /// Get all categories once (non-realtime fetch).
  Future<List<CategoryModel>> fetchCategoriesOnce() async {
    try {
      QuerySnapshot snapshot =
      await _categoryCollection.orderBy('name').get();

      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Fetch a single category by document ID once.
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      DocumentSnapshot doc = await _categoryCollection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;

      return CategoryModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  // ===========================================================================
  // 3. UPDATE
  // ===========================================================================

  /// Update an existing category by ID.
  Future<void> updateCategory(CategoryModel category) async {
    try {
      if (category.id.isEmpty) {
        throw Exception('Cannot update a category without a valid ID.');
      }

      await _categoryCollection.doc(category.id).update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Update specific fields of a category without overwriting the whole document.
  Future<void> updateCategoryPartial(
      String categoryId,
      Map<String, dynamic> updatedFields,
      ) async {
    try {
      await _categoryCollection.doc(categoryId).update(updatedFields);
    } catch (e) {
      throw Exception('Failed to update field(s): $e');
    }
  }

  // ===========================================================================
  // 4. DELETE
  // ===========================================================================

  /// Delete a category document by ID.
  Future<void> deleteCategory(String id) async {
    try {
      await _categoryCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // ===========================================================================
  // 5. HELPER & ADVANCED METHODS
  // ===========================================================================

  /// Check if a category with the same name already exists.
  Future<bool> categoryExistsByName(String name, {String? excludeId}) async {
    try {
      QuerySnapshot snapshot = await _categoryCollection
          .where('name', isEqualTo: name.trim())
          .get();

      if (snapshot.docs.isEmpty) return false;

      // If updating, ignore the current category document
      if (excludeId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Seed initial categories into database (Batch Operation).
  Future<void> seedInitialCategories(List<CategoryModel> categories) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var cat in categories) {
      DocumentReference docRef = _categoryCollection.doc();
      batch.set(docRef, cat.toMap());
    }

    await batch.commit();
  }
}