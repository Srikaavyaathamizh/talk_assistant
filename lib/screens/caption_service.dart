import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CaptionService {
  static const String _hfToken = "YOUR_HUGGINGFACE_API_KEY";

  static Future<String> generateCaption(File imageFile) async {
    final uri = Uri.parse(
      "https://api-inference.huggingface.co/models/Salesforce/blip-image-captioning-base",
    );

    final bytes = await imageFile.readAsBytes();

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $_hfToken",
        "Content-Type": "application/octet-stream",
      },
      body: bytes,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]["generated_text"];
    } else {
      return "Unable to understand surroundings";
    }
  }
}
