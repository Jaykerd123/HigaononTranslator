import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String category, String message) {
    if (!kDebugMode) return;
    debugPrint('${DateTime.now().toIso8601String()} [$category] $message');
  }

  static void error(String category, String message, {StackTrace? stackTrace}) {
    debugPrint(
      '${DateTime.now().toIso8601String()} [$category] ERROR: $message',
    );
    if (kDebugMode && stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void apiRequest(String method, Uri uri) {
    final safeUri = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    );
    debug('API', 'Request URL: $safeUri');
    debug('API', 'HTTP method: $method');
    debug('API', 'Request started.');
  }

  static void apiResponse(int statusCode) {
    debug('API', 'Response status: $statusCode');
    debug('API', 'Response received.');
  }

  static void translationStarted(String input) {
    debug('TRANSLATION', '=================================');
    debug('TRANSLATION', 'New translation request received.');
    debug('TRANSLATION', 'Source language: English');
    debug('TRANSLATION', 'Target language: Higaonon');
    debug('TRANSLATION', 'Input text: $input');
    debug('TRANSLATION', 'Checking local dictionary...');
  }

  static void dictionaryMatch(String result, {required String source}) {
    debug('TRANSLATION', 'Dictionary match found.');
    debug('TRANSLATION', 'Dictionary result: $result');
    translationCompleted(result, source);
  }

  static void translationCompleted(String result, String source) {
    debug('TRANSLATION', 'Final translation: $result');
    debug('TRANSLATION', 'Final result source: $source');
    debug('TRANSLATION', 'Translation completed successfully.');
    debug('TRANSLATION', '=================================');
  }
}
