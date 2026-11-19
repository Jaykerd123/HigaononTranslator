import 'dart:async';
import 'dart:convert';

import 'package:Higa/screens/services/app_logger.dart';
import 'package:http/http.dart' as http;

class HuggingFaceCsvTranslation {
  const HuggingFaceCsvTranslation({
    required this.english,
    required this.higaonon,
    required this.source,
    required this.verified,
    required this.status,
    required this.message,
  });

  final String english;
  final String higaonon;
  final String source;
  final bool? verified;
  final String status;
  final String? message;

  String get displaySource => switch (source) {
    'csv_exact' => 'CSV Dataset (Exact Match)',
    'csv_approximate' => 'CSV Dataset (Approximate Match)',
    'gemini_generated' => 'Gemini AI (Generated)',
    _ => 'Other Translation Service',
  };
}

class HuggingFaceCsvTranslationException implements Exception {
  const HuggingFaceCsvTranslationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HuggingFaceCsvTranslationService {
  HuggingFaceCsvTranslationService({
    http.Client? client,
    this.timeout = const Duration(seconds: 120),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static final Uri _endpoint = Uri.parse(
    'https://jaykerd-higaonon-tts.hf.space/'
    'gradio_api/call/v2/translate_from_csv',
  );

  final http.Client _client;
  final Duration timeout;
  final bool _ownsClient;

  Future<HuggingFaceCsvTranslation> translate(String english) async {
    final trimmedEnglish = english.trim();
    if (trimmedEnglish.isEmpty) {
      throw const HuggingFaceCsvTranslationException(
        'English text cannot be empty.',
      );
    }

    final http.Response queueResponse;
    try {
      AppLogger.apiRequest('POST', _endpoint);
      queueResponse = await _client
          .post(
            _endpoint,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'english_text': trimmedEnglish}),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face translation request timed out.',
      );
    } on http.ClientException {
      throw const HuggingFaceCsvTranslationException(
        'Could not connect to the Hugging Face translation service.',
      );
    }
    AppLogger.apiResponse(queueResponse.statusCode);

    if (queueResponse.statusCode != 200) {
      throw HuggingFaceCsvTranslationException(
        'Hugging Face translation request failed '
        '(HTTP ${queueResponse.statusCode}).',
      );
    }

    final dynamic queueData;
    try {
      queueData = jsonDecode(queueResponse.body);
    } on FormatException {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face returned invalid request JSON.',
      );
    }

    if (queueData is! Map) {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face returned an unexpected request response.',
      );
    }
    if (queueData['error'] != null) {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face rejected the translation request.',
      );
    }

    final eventId = queueData['event_id'];
    if (eventId is! String || eventId.isEmpty) {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face did not return a Gradio event ID.',
      );
    }

    final streamUri = _endpoint.replace(
      path:
          '/gradio_api/call/translate_from_csv/'
          '${Uri.encodeComponent(eventId)}',
    );
    final request = http.Request('GET', streamUri)
      ..headers.addAll(const {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      });

    final http.StreamedResponse streamResponse;
    try {
      AppLogger.apiRequest('GET', streamUri);
      streamResponse = await _client.send(request).timeout(timeout);
    } on TimeoutException {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face translation response timed out.',
      );
    } on http.ClientException {
      throw const HuggingFaceCsvTranslationException(
        'Could not read the Hugging Face translation response.',
      );
    }
    AppLogger.apiResponse(streamResponse.statusCode);

    if (streamResponse.statusCode != 200) {
      throw HuggingFaceCsvTranslationException(
        'Hugging Face translation stream failed '
        '(HTTP ${streamResponse.statusCode}).',
      );
    }

    try {
      return await _readEventStream(
        streamResponse,
        trimmedEnglish,
      ).timeout(timeout);
    } on TimeoutException {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face translation response timed out.',
      );
    }
  }

  Future<HuggingFaceCsvTranslation> _readEventStream(
    http.StreamedResponse response,
    String requestedEnglish,
  ) async {
    String? eventName;
    final dataLines = <String>[];

    HuggingFaceCsvTranslation? finishEvent() {
      if (eventName == 'error') {
        final details = dataLines.join('\n').trim();
        throw HuggingFaceCsvTranslationException(
          details.isEmpty
              ? 'Hugging Face reported a translation error.'
              : 'Hugging Face reported a translation error: $details',
        );
      }
      if (eventName != 'complete') return null;

      final payloadText = dataLines.join('\n').trim();
      if (payloadText.isEmpty || payloadText == 'null') {
        throw const HuggingFaceCsvTranslationException(
          'Hugging Face completed without a translation result.',
        );
      }

      final dynamic payload;
      try {
        payload = jsonDecode(payloadText);
      } on FormatException {
        throw const HuggingFaceCsvTranslationException(
          'Hugging Face returned malformed translation JSON.',
        );
      }

      final resultObject = _extractResultObject(payload);
      if (resultObject == null) {
        throw const HuggingFaceCsvTranslationException(
          'Hugging Face returned an unexpected translation result.',
        );
      }
      return _parseResult(resultObject, requestedEnglish);
    }

    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.isEmpty) {
        final result = finishEvent();
        if (result != null) return result;
        eventName = null;
        dataLines.clear();
      } else if (line.startsWith('event:')) {
        eventName = line.substring('event:'.length).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring('data:'.length).trimLeft());
      }
    }

    final result = finishEvent();
    if (result != null) return result;
    throw const HuggingFaceCsvTranslationException(
      'Hugging Face response stream ended before translation completed.',
    );
  }

  Map<String, dynamic>? _extractResultObject(Object? payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is List && payload.length == 1) {
      final result = payload.first;
      if (result is Map<String, dynamic>) return result;
      if (result is String) {
        try {
          final decoded = jsonDecode(result);
          if (decoded is Map<String, dynamic>) return decoded;
        } on FormatException {
          return null;
        }
      }
    }
    if (payload is String) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  HuggingFaceCsvTranslation _parseResult(
    Map<String, dynamic> result,
    String requestedEnglish,
  ) {
    final translation = result['higaonon'];
    final source = result['source'];
    final status = result['status'];
    final verified = result['verified'];
    final message = result['message'];
    final responseEnglish = result['english'];

    if (translation is! String || translation.trim().isEmpty) {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face returned an empty translation.',
      );
    }
    if (source is! String || source.trim().isEmpty) {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face response is missing its source classification.',
      );
    }
    if (status is! String || status.trim().isEmpty) {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face response is missing its status.',
      );
    }
    if (status.trim().toLowerCase() != 'success') {
      throw HuggingFaceCsvTranslationException(
        'Hugging Face translation status was "$status".',
      );
    }
    if (verified != null && verified is! bool) {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face returned an invalid verification status.',
      );
    }
    if (message != null && message is! String) {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face returned an invalid translation message.',
      );
    }
    if (responseEnglish != null && responseEnglish is! String) {
      throw const HuggingFaceCsvTranslationException(
        'Hugging Face returned an invalid English input value.',
      );
    }

    return HuggingFaceCsvTranslation(
      english: responseEnglish is String && responseEnglish.isNotEmpty
          ? responseEnglish
          : requestedEnglish,
      higaonon: translation.trim(),
      source: source.trim(),
      verified: verified is bool ? verified : null,
      status: status.trim(),
      message: message is String ? message : null,
    );
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
