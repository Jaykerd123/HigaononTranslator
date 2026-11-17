import 'dart:async';
import 'dart:convert';

import 'package:Higa/screens/services/app_logger.dart';
import 'package:http/http.dart' as http;

class GeminiAssistantException implements Exception {
  const GeminiAssistantException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeminiAssistantService {
  GeminiAssistantService({
    http.Client? client,
    this.timeout = const Duration(seconds: 180),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static final Uri _endpoint = Uri.parse(
    'https://jaykerd-higaonon-tts.hf.space/gradio_api/call/ask_higaonon_assistant',
  );

  final http.Client _client;
  final Duration timeout;
  final bool _ownsClient;

  Future<String> ask(String question) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      throw const GeminiAssistantException('Enter a question first.');
    }

    AppLogger.debug('Gemini', 'Request received.');
    AppLogger.debug('Gemini', 'Question: $trimmedQuestion');
    try {
      final queueStopwatch = Stopwatch()..start();
      AppLogger.apiRequest('POST', _endpoint);
      late final http.Response queueResponse;
      try {
        queueResponse = await _client
            .post(
              _endpoint,
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'data': [trimmedQuestion],
              }),
            )
            .timeout(timeout);
      } catch (error, stackTrace) {
        AppLogger.error(
          'API',
          'Gemini POST failed (${error.runtimeType}).',
          stackTrace: stackTrace,
        );
        rethrow;
      } finally {
        AppLogger.debug(
          'API',
          'Request duration: ${queueStopwatch.elapsedMilliseconds} ms',
        );
      }
      AppLogger.apiResponse(queueResponse.statusCode);

      if (queueResponse.statusCode != 200) {
        AppLogger.error(
          'API',
          'Gemini POST returned HTTP ${queueResponse.statusCode}.',
        );
        throw GeminiAssistantException(
          'The assistant request failed (HTTP ${queueResponse.statusCode}).',
        );
      }

      final dynamic queueData;
      try {
        queueData = jsonDecode(queueResponse.body);
      } on FormatException {
        AppLogger.error('API', 'Gemini POST returned invalid JSON.');
        throw const GeminiAssistantException(
          'The assistant returned an invalid Gradio response.',
        );
      }

      if (queueData is! Map) {
        AppLogger.error('API', 'Gemini POST returned an unexpected response.');
        throw const GeminiAssistantException(
          'The assistant returned an unexpected Gradio response.',
        );
      }
      if (queueData['error'] != null) {
        AppLogger.error('API', 'Gradio rejected the Gemini request.');
        throw GeminiAssistantException(
          'The assistant rejected the request: ${queueData['error']}',
        );
      }

      final eventId = queueData['event_id']?.toString();
      if (eventId == null || eventId.isEmpty) {
        AppLogger.error('API', 'Gradio response did not contain an event ID.');
        throw const GeminiAssistantException(
          'The assistant did not return a Gradio event ID.',
        );
      }

      final streamRequest =
          http.Request(
              'GET',
              _endpoint.replace(path: '${_endpoint.path}/$eventId'),
            )
            ..headers.addAll(const {
              'Accept': 'text/event-stream',
              'Cache-Control': 'no-cache',
            });

      AppLogger.debug('Gemini', 'Connecting to Hugging Face response stream.');
      final streamStopwatch = Stopwatch()..start();
      AppLogger.apiRequest('GET', streamRequest.url);
      late final http.StreamedResponse streamResponse;
      try {
        streamResponse = await _client.send(streamRequest).timeout(timeout);
      } catch (error, stackTrace) {
        AppLogger.error(
          'API',
          'Gemini SSE connection failed (${error.runtimeType}).',
          stackTrace: stackTrace,
        );
        AppLogger.debug(
          'API',
          'Request duration: ${streamStopwatch.elapsedMilliseconds} ms',
        );
        rethrow;
      }
      AppLogger.apiResponse(streamResponse.statusCode);
      if (streamResponse.statusCode != 200) {
        AppLogger.debug(
          'API',
          'Request duration: ${streamStopwatch.elapsedMilliseconds} ms',
        );
        AppLogger.error(
          'API',
          'Gemini SSE returned HTTP ${streamResponse.statusCode}.',
        );
        throw GeminiAssistantException(
          'The assistant response stream failed '
          '(HTTP ${streamResponse.statusCode}).',
        );
      }

      late final String answer;
      try {
        answer = await _readEventStream(streamResponse).timeout(timeout);
      } finally {
        AppLogger.debug(
          'API',
          'SSE request duration: ${streamStopwatch.elapsedMilliseconds} ms',
        );
      }
      AppLogger.debug('Gemini', 'Response received.');
      AppLogger.debug('Gemini', 'Response length: ${answer.length}');
      AppLogger.debug('Gemini', 'Request completed successfully.');
      return answer;
    } on GeminiAssistantException catch (error, stackTrace) {
      AppLogger.error(
        'Gemini',
        'Request failed (${error.runtimeType}).',
        stackTrace: stackTrace,
      );
      rethrow;
    } on TimeoutException catch (_, stackTrace) {
      AppLogger.error('API', 'Gemini request timed out.');
      AppLogger.error('Gemini', 'Request timed out.', stackTrace: stackTrace);
      throw const GeminiAssistantException(
        'The assistant took too long to respond. Please try again.',
      );
    } on http.ClientException catch (error, stackTrace) {
      AppLogger.error(
        'API',
        'Gemini connection failed (${error.runtimeType}).',
      );
      AppLogger.error(
        'Gemini',
        'Connection failed (${error.runtimeType}).',
        stackTrace: stackTrace,
      );
      throw GeminiAssistantException(
        'Could not connect to the assistant: ${error.message}',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Gemini',
        'Unexpected request failure (${error.runtimeType}).',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<String> _readEventStream(http.StreamedResponse response) async {
    String? eventName;
    final dataLines = <String>[];

    String? finishEvent() {
      if (eventName == 'error') {
        final details = dataLines.join('\n').trim();
        AppLogger.error('Gemini', 'Gradio SSE returned an error event.');
        AppLogger.error('API', 'Gradio SSE returned an error event.');
        throw GeminiAssistantException(
          details.isEmpty
              ? 'The assistant reported an error.'
              : 'The assistant reported an error: $details',
        );
      }
      if (eventName != 'complete') return null;

      final payloadText = dataLines.join('\n').trim();
      if (payloadText.isEmpty || payloadText == 'null') {
        throw const GeminiAssistantException(
          'The assistant completed without returning an answer.',
        );
      }

      Object? payload;
      try {
        payload = jsonDecode(payloadText);
      } on FormatException {
        payload = payloadText;
      }

      final answer = _extractAnswer(payload);
      if (answer == null || answer.trim().isEmpty) {
        throw const GeminiAssistantException(
          'The assistant response did not contain readable text.',
        );
      }
      return answer.trim();
    }

    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.isEmpty) {
        final answer = finishEvent();
        if (answer != null) return answer;
        eventName = null;
        dataLines.clear();
      } else if (line.startsWith('event:')) {
        eventName = line.substring('event:'.length).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring('data:'.length).trimLeft());
      }
    }

    final answer = finishEvent();
    if (answer != null) return answer;
    throw const GeminiAssistantException(
      'The assistant response stream ended before an answer arrived.',
    );
  }

  String? _extractAnswer(Object? value) {
    if (value is String) {
      return value.trim().isEmpty ? null : value;
    }
    if (value is List) {
      for (final item in value) {
        final answer = _extractAnswer(item);
        if (answer != null) return answer;
      }
      return null;
    }
    if (value is Map) {
      if (value['error'] != null) {
        throw GeminiAssistantException(
          'The assistant reported an error: ${value['error']}',
        );
      }
      for (final key in const [
        'answer',
        'response',
        'text',
        'output',
        'message',
        'content',
        'data',
      ]) {
        if (value.containsKey(key)) {
          final answer = _extractAnswer(value[key]);
          if (answer != null) return answer;
        }
      }
      for (final item in value.values) {
        final answer = _extractAnswer(item);
        if (answer != null) return answer;
      }
    }
    return null;
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
