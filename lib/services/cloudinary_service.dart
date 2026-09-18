// import 'dart:convert';
// import 'dart:io';
//
// import 'package:http/http.dart' as http;
//
// class CloudinaryService {
//   final String cloudName = "dxqkcp1hu";
//   final String uploadPreset = "rentease_images";
//
//   Future<String?> uploadImage(File image) async {
//     try {
//       final url = Uri.parse(
//         'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
//       );
//
//       final request = http.MultipartRequest('POST', url);
//
//       request.fields['upload_preset'] = uploadPreset;
//
//       request.files.add(await http.MultipartFile.fromPath('file', image.path));
//
//       final response = await request.send();
//
//       final responseBody = await response.stream.bytesToString();
//
//       print('====================================');
//       print('☁️ CLOUDINARY UPLOAD');
//       print('Status: ${response.statusCode}');
//       print('Response: $responseBody');
//       print('====================================');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(responseBody);
//
//         final String? secureUrl = data['secure_url'];
//
//         print('✅ Cloudinary URL: $secureUrl');
//
//         return secureUrl;
//       }
//
//       print('❌ Cloudinary upload failed');
//
//       return null;
//     } catch (e) {
//       print('❌ Cloudinary Error: $e');
//
//       return null;
//     }
//   }
// }


import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = "dxqkcp1hu";
  final String uploadPreset = "rentease_images";

  /// Upload Image
  Future<String?> uploadImage(File image) async {
    return _uploadFile(
      file: image,
      resourceType: "image",
    );
  }

  /// Upload Voice / Audio
  Future<String?> uploadAudio(File audio) async {
    return _uploadFile(
      file: audio,
      resourceType: "video", // Cloudinary treats audio as "video"
    );
  }

  /// Private upload method
  Future<String?> _uploadFile({
    required File file,
    required String resourceType,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
      );

      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('====================================');
      print('☁️ CLOUDINARY UPLOAD ($resourceType)');
      print('Status: ${response.statusCode}');
      print('Response: $responseBody');
      print('====================================');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final String? secureUrl = data['secure_url'];

        print('✅ Cloudinary URL: $secureUrl');
        return secureUrl;
      }

      print('❌ Cloudinary upload failed');
      return null;
    } catch (e) {
      print('❌ Cloudinary Error: $e');
      return null;
    }
  }
}