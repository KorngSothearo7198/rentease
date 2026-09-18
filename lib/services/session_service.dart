import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String userKey = "logged_user";

  // static Future<void> saveUser(Map<String, dynamic> user) async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   await prefs.setString(
  //     userKey,
  //     jsonEncode(user),
  //   );
  //
  // }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    final success = await prefs.setString(
      userKey,
      jsonEncode(user),
    );

    print("Save Success: $success");
    print("Saved Value:");
    print(prefs.getString(userKey));
  }

  // static Future<Map<String, dynamic>?> getUser() async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   final json = prefs.getString(userKey);
  //
  //   if (json == null) return null;
  //
  //   return Map<String, dynamic>.from(jsonDecode(json));
  // }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final json = prefs.getString(userKey);

    if (json == null || json.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(json);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (e) {
      print("Session decode error: $e");

      await prefs.remove(userKey);
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }
}
// await FirebaseAuth.instance.signOut();
// await SessionService.clear();