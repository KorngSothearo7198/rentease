import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/property_model.dart';

class FavoriteService {
  // get current user token
  Future<String?> getUserToken() async {
    final user = await SessionService.getUser();

    print("===== FAVORITE USER =====");
    print(user);
    print("=========================");

    if (user == null) {
      return null;
    }

    print("CURRENT UID = ${user["uid"]}");

    return user["uid"];
  }

  // save favorite
  Future<void> addFavorite(Property property) async {
    print("ADD FAVORITE START");

    final prefs = await SharedPreferences.getInstance();

    final token = await getUserToken();

    print("TOKEN = $token");

    if (token == null) {
      print("NO USER TOKEN");

      return;
    }

    String key = "favorites_$token";

    print("SAVE KEY = $key");

    List<String> favorites = prefs.getStringList(key) ?? [];

    print("BEFORE SAVE = $favorites");

    if (!favorites.contains(property.id)) {
      favorites.add(property.id);

      await prefs.setStringList(key, favorites);

      print("AFTER SAVE = $favorites");
    } else {
      print("Already Favorite");
    }
  }

  // remove favorite
  Future<void> removeFavorite(String propertyId) async {
    final prefs = await SharedPreferences.getInstance();

    final token = await getUserToken();

    if (token == null) {
      print("NO TOKEN");

      return;
    }

    String key = "favorites_$token";

    List<String> favorites = prefs.getStringList(key) ?? [];

    print("BEFORE REMOVE = $favorites");

    favorites.remove(propertyId);

    await prefs.setStringList(key, favorites);

    print("AFTER REMOVE = $favorites");
  }

  // check favorite
  Future<bool> isFavorite(String propertyId) async {
    final prefs = await SharedPreferences.getInstance();

    final token = await getUserToken();

    print("CHECK FAVORITE USER = $token");

    if (token == null) {
      return false;
    }

    String key = "favorites_$token";

    List<String> favorites = prefs.getStringList(key) ?? [];

    print("CURRENT FAVORITES = $favorites");

    bool result = favorites.contains(propertyId);

    print("IS FAVORITE = $result");

    return result;
  }

  // get favorite ids
  Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();

    final token = await getUserToken();

    if (token == null) return [];

    return prefs.getStringList("favorites_$token") ?? [];
  }

  Future<List<Property>> getProperties() async {
    print("LOAD PROPERTIES START");

    final snapshot = await FirebaseFirestore.instance
        .collection("properties")
        .get();

    print("TOTAL PROPERTY = ${snapshot.docs.length}");

    for (var doc in snapshot.docs) {
      print("PROPERTY ID = ${doc.id}");
    }

    return snapshot.docs.map((doc) {
      return Property.fromMap(doc.data(), doc.id);
    }).toList();
  }
}
