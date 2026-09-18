import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Result returned from Bakong transaction lookup.
class BakongTransactionStatus {
  final bool paid;
  final String? responseMessage;
  final Map<String, dynamic>? data;

  /// Bakong response code.
  final int responseCode;

  /// HTTP status returned by Bakong.
  final int httpStatus;

  /// True when Bakong says the API request limit was exceeded.
  final bool rateLimited;

  /// True when Bakong rejects the authentication token.
  final bool unauthorized;

  const BakongTransactionStatus({
    required this.paid,
    required this.responseCode,
    required this.httpStatus,
    this.responseMessage,
    this.data,
    this.rateLimited = false,
    this.unauthorized = false,
  });
}

/// Wrapper around Bakong Open API.
///
/// This service handles Bakong API communication only.
/// Firestore/payment business logic belongs in PaymentService.
class BakongService {
  BakongService._();

  static const String _baseUrl =
      'https://api-bakong.nbc.gov.kh/v1';

  static String get _token {
    final token = dotenv.env['BAKONG_TOKEN']?.trim();

    if (token == null || token.isEmpty) {
      throw StateError(
        'BAKONG_TOKEN is not set in .env',
      );
    }

    return token;
  }

  /// Check Bakong transaction using KHQR MD5.
  static Future<BakongTransactionStatus>
  checkTransactionByMd5(
      String md5,
      ) async {
    final md5Value = md5.trim();

    if (md5Value.isEmpty) {
      throw ArgumentError(
        'Bakong MD5 cannot be empty.',
      );
    }

    final response = await http.post(
      Uri.parse(
        '$_baseUrl/check_transaction_by_md5',
      ),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'md5': md5Value,
      }),
    );

    Map<String, dynamic> body;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Bakong response is not a JSON object.',
        );
      }

      body = decoded;
    } catch (e) {
      throw FormatException(
        'Invalid Bakong API response: $e',
      );
    }

    final responseCode =
        int.tryParse(
          body['responseCode']?.toString() ?? '',
        ) ??
            -1;

    final responseMessage =
    body['responseMessage']?.toString();

    final data =
    body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : null;

    final message =
        responseMessage?.toLowerCase() ?? '';

    // ============================================================
    // RATE LIMIT
    // ============================================================

    final rateLimited =
        message.contains('daily request limit') ||
            message.contains('request limit') ||
            message.contains('too many requests');

    // ============================================================
    // UNAUTHORIZED
    // ============================================================

    final unauthorized =
        response.statusCode == 401 ||
            message.contains('unauthorized');

    // ============================================================
    // DEBUG
    // ============================================================

    print('');
    print('==============================================');
    print('BAKONG API RESPONSE');
    print('==============================================');
    print('HTTP Status: ${response.statusCode}');
    print('Response Code: $responseCode');
    print('Message: $responseMessage');
    print('Rate Limited: $rateLimited');
    print('Unauthorized: $unauthorized');
    print('==============================================');

    return BakongTransactionStatus(
      paid:
      response.statusCode == 200 &&
          responseCode == 0 &&
          data != null,

      responseCode: responseCode,

      httpStatus:
      response.statusCode,

      responseMessage:
      responseMessage,

      data:
      data,

      rateLimited:
      rateLimited,

      unauthorized:
      unauthorized,
    );
  }
}