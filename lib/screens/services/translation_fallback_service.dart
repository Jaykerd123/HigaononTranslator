import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationFallbackService {
  /// Translates text from English to Cebuano (Bisaya) using Google Translate API's free endpoint.
  static Future<String?> translateEnglishToBisaya(String text) async {
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ceb&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // The response is a nested JSON array:
        // [[["translation", "source", null, null, 1]], null, "en", null, null, null, 1, null, [["en"], null, [1], ["en"]]]
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isNotEmpty && data[0] is List && data[0].isNotEmpty) {
          final translatedText = StringBuffer();
          for (var item in data[0]) {
            if (item is List && item.isNotEmpty) {
              translatedText.write(item[0]);
            }
          }
          return translatedText.toString();
        }
      }
      return null;
    } catch (e) {
      print('TranslationFallbackService Error: $e');
      return null;
    }
  }
}

