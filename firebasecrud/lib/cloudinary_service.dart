import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dc9ec9jw1';
  static const String uploadPreset = 'flutter_nodes_preset';

  static Future<String?> uploadBytes(Uint8List bytes, String fileName) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return data['secure_url'] as String?;
    } else {
      throw Exception('Cloudinary upload failed: $responseBody');
    }
  }
}
