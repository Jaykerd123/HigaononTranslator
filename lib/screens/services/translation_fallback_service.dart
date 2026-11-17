import 'dart:convert';

import 'package:Higa/screens/services/app_logger.dart';
import 'package:http/http.dart' as http;
import 'discovery_service.dart';

class TranslationFallbackService {
  /// The current primary public API endpoint (Cloudflare Tunnel)
  static const String publicApiBaseUrl =
      'https://pale-astronomy-tongue-ones.trycloudflare.com';

  /// Translates text from English to Cebuano (Bisaya) using the local NLP server.
  static Future<String?> translateEnglishToBisaya(String text) async {
    List<String> possibleBaseUrls = [
      publicApiBaseUrl,
      'http://127.0.0.1:8000',
      'http://127.0.0.1:8080',
    ];

    if (DiscoveryService.discoveredBaseUrl != null) {
      possibleBaseUrls.insert(
        1,
        DiscoveryService.discoveredBaseUrl!,
      ); // Insert after public URL
    }

    for (int i = 0; i < possibleBaseUrls.length; i++) {
      String baseUrl = possibleBaseUrls[i];
      try {
        final url = Uri.parse('$baseUrl/translate');
        final stopwatch = Stopwatch()..start();
        AppLogger.apiRequest('POST', url);
        late final http.Response response;
        try {
          response = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'text': text}),
              )
              .timeout(
                const Duration(seconds: 6),
              ); // Increased timeout for tunnel latency
        } finally {
          AppLogger.debug(
            'API',
            'Request duration: ${stopwatch.elapsedMilliseconds} ms',
          );
        }
        AppLogger.apiResponse(response.statusCode);

        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) {
            AppLogger.error('API', 'Fallback response had an invalid shape.');
          } else if (decoded.containsKey('translation')) {
            AppLogger.debug('TRANSLATION', 'Fallback response received.');
            return decoded['translation'];
          } else {
            AppLogger.error(
              'API',
              'Fallback response did not contain a translation.',
            );
          }
        } else {
          AppLogger.error(
            'API',
            'Fallback request returned HTTP ${response.statusCode}.',
          );
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'API',
          'Fallback request failed (${error.runtimeType}).',
          stackTrace: stackTrace,
        );
      }

      if (i == possibleBaseUrls.length - 1 &&
          DiscoveryService.discoveredBaseUrl == null) {
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

      final stopwatch = Stopwatch()..start();
      AppLogger.apiRequest('GET', url);
      late final http.Response response;
      try {
        response = await http.get(url);
      } finally {
        AppLogger.debug(
          'API',
          'Request duration: ${stopwatch.elapsedMilliseconds} ms',
        );
      }
      AppLogger.apiResponse(response.statusCode);

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
          AppLogger.debug('TRANSLATION', 'Fallback response received.');
          return translatedText.toString();
        }
      }
      AppLogger.error(
        'API',
        'Google Translate fallback returned HTTP ${response.statusCode} '
            'or an invalid response.',
      );
      return null;
    } catch (error, stackTrace) {
      AppLogger.error(
        'API',
        'Google Translate fallback failed (${error.runtimeType}).',
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
