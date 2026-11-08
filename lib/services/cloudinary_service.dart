//
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



//
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
//
// class CloudinaryService {
//   final String cloudName = "dxqkcp1hu";
//
//   // Image preset
//   final String imageUploadPreset = "rentease_images";
//
//   // Recommended: create a separate Cloudinary unsigned preset
//   // for voice/audio files.
//   final String audioUploadPreset = "rentease_audio";
//
//   // ============================================================
//   // UPLOAD IMAGE
//   // ============================================================
//
//   Future<String?> uploadImage(File image) async {
//     return _uploadFile(
//       file: image,
//       resourceType: "image",
//       uploadPreset: imageUploadPreset,
//       contentType: MediaType("image", "jpeg"),
//     );
//   }
//
//   // ============================================================
//   // UPLOAD AUDIO
//   // ============================================================
//
//   Future<String?> uploadAudio(File audio) async {
//     return _uploadFile(
//       file: audio,
//       resourceType: "video",
//       uploadPreset: audioUploadPreset,
//       contentType: MediaType("audio", "mp4"),
//     );
//   }
//
//   // ============================================================
//   // PRIVATE UPLOAD
//   // ============================================================
//
//   Future<String?> _uploadFile({
//     required File file,
//     required String resourceType,
//     required String uploadPreset,
//     required MediaType contentType,
//   }) async {
//     try {
//       if (!await file.exists()) {
//         print("❌ File does not exist: ${file.path}");
//         return null;
//       }
//
//       final fileSize = await file.length();
//
//       print("====================================");
//       print("☁️ CLOUDINARY UPLOAD");
//       print("Resource: $resourceType");
//       print("File: ${file.path}");
//       print("Size: $fileSize bytes");
//       print("Preset: $uploadPreset");
//       print("====================================");
//
//       final url = Uri.parse(
//         "https://api.cloudinary.com/v1_1/"
//             "$cloudName/"
//             "$resourceType/upload",
//       );
//
//       final request = http.MultipartRequest(
//         "POST",
//         url,
//       );
//
//       request.fields["upload_preset"] = uploadPreset;
//
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           "file",
//           file.path,
//           contentType: contentType,
//         ),
//       );
//
//       final response = await request.send();
//
//       final responseBody =
//       await response.stream.bytesToString();
//
//       print("====================================");
//       print("☁️ CLOUDINARY RESPONSE");
//       print("Status: ${response.statusCode}");
//       print("Response: $responseBody");
//       print("====================================");
//
//       if (response.statusCode != 200) {
//         print("❌ Cloudinary upload failed");
//         return null;
//       }
//
//       final data = jsonDecode(responseBody);
//
//       final secureUrl = data["secure_url"];
//
//       if (secureUrl == null || secureUrl.toString().isEmpty) {
//         print("❌ secure_url is missing");
//         return null;
//       }
//
//       print("✅ Cloudinary URL:");
//       print(secureUrl);
//
//       return secureUrl.toString();
//     } catch (e, stackTrace) {
//       print("====================================");
//       print("❌ CLOUDINARY ERROR");
//       print(e);
//       print(stackTrace);
//       print("====================================");
//
//       return null;
//     }
//   }
// }