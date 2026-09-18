import 'dart:convert';

import 'package:http/http.dart' as http;

class TelegramService {
  // Firebase Functions emulator
  //
  // iOS Simulator:
  // http://127.0.0.1:5001/PROJECT_ID/us-central1/sendTelegramTest
  //
  // Android Emulator:
  // http://10.0.2.2:5001/PROJECT_ID/us-central1/sendTelegramTest

  static const String functionUrl =
      'http://127.0.0.1:5001/rentease-211f2/us-central1/sendTelegramTest';

  // static const String functionUrl =
  //     'http://127.0.0.1:5001/rentease-211f2/us-central1/sendTelegramTest';

  static Future<bool> sendMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chatId': chatId,
          'message': message,
        }),
      );

      print("Telegram HTTP status: ${response.statusCode}");
      print("Telegram response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print("Telegram error: $e");
      return false;
    }
  }
}