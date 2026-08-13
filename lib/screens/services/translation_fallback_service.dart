import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'discovery_service.dart';

class TranslationFallbackService {
  /// Translates text from English to Cebuano (Bisaya) using the local NLP server.
  static Future<String?> translateEnglishToBisaya(String text) async {
    List<String> possibleBaseUrls = [
      'http://127.0.0.1:8000',
      'http://127.0.0.1:8080',
    ];
    
    if (DiscoveryService.discoveredBaseUrl != null) {
      possibleBaseUrls.insert(0, DiscoveryService.discoveredBaseUrl!);
    }

    for (int i = 0; i < possibleBaseUrls.length; i++) {
      String baseUrl = possibleBaseUrls[i];
      try {
        final url = Uri.parse('$baseUrl/translate');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          if (data.containsKey('translation')) {
            return data['translation'];
          }
        }
      } catch (e) {
        print('TranslationFallbackService Error calling local Python server at $baseUrl: $e');
      }

      if (i == possibleBaseUrls.length - 1 && DiscoveryService.discoveredBaseUrl == null) {
        final discovered = await DiscoveryService.discoverServer();
        if (discovered != null) {
          possibleBaseUrls.add(discovered);
        }
      }
    }
    
    // Fallback to Google Translate if local server is down or unreachable
    return await _fallbackToGoogleTranslate(text);
  }

  static Future<String?> _fallbackToGoogleTranslate(String text) async {
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

