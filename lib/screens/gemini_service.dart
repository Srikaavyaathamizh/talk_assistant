import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "YOUR_HUGGINGFACE_API_KEY";

  static Future<String> getReply(String userText) async {
    try {
      final uri = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash?key=$_apiKey",
      );

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {
                  "text":
                  "Reply politely like Google Assistant.\nUser said: $userText"
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["candidates"] != null &&
            data["candidates"].isNotEmpty) {
          return data["candidates"][0]["content"]["parts"][0]["text"];
        } else {
          return "I did not receive a response.";
        }
      } else {
        return "Gemini error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error connecting to Gemini.";
    }
  }
}



