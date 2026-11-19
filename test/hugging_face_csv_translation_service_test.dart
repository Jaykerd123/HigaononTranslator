import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:Higa/screens/services/hugging_face_csv_translation_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HuggingFaceCsvTranslationService', () {
    test('uses the published Gradio request and parses JSON output', () async {
      final requests = <http.BaseRequest>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'event_id': 'translation-event'}),
            200,
          );
        }
        return http.Response(
          'event: complete\n'
          'data: [{"english":"Please help me.","higaonon":"Mock translation",'
          '"source":"gemini_generated","verified":false,"status":"success",'
          '"message":"Generated for this test."}]\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final service = HuggingFaceCsvTranslationService(client: client);

      final result = await service.translate('  Please help me.  ');

      expect(requests, hasLength(2));
      expect(requests.first.method, 'POST');
      expect(requests.first.url.path, '/gradio_api/call/v2/translate_from_csv');
      expect(jsonDecode((requests.first as http.Request).body), {
        'english_text': 'Please help me.',
      });
      expect(requests.last.method, 'GET');
      expect(
        requests.last.url.path,
        '/gradio_api/call/translate_from_csv/translation-event',
      );
      expect(requests.last.headers['accept'], 'text/event-stream');
      expect(result.english, 'Please help me.');
      expect(result.higaonon, 'Mock translation');
      expect(result.source, 'gemini_generated');
      expect(result.displaySource, 'Gemini AI (Generated)');
      expect(result.verified, isFalse);
      expect(result.status, 'success');
      expect(result.message, 'Generated for this test.');

      service.dispose();
      client.close();
    });

    test('keeps verification unknown when the API omits it', () async {
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'event_id': 'event'}), 200);
        }
        return http.Response(
          'event: complete\n'
          'data: [{"higaonon":"Dataset phrase","source":"csv_exact",'
          '"status":"success"}]\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final service = HuggingFaceCsvTranslationService(client: client);

      final result = await service.translate('Original English');

      expect(result.english, 'Original English');
      expect(result.displaySource, 'CSV Dataset (Exact Match)');
      expect(result.verified, isNull);
      expect(result.message, isNull);

      service.dispose();
      client.close();
    });

    test('rejects malformed, missing, and empty translation results', () async {
      for (final eventData in [
        '{not json}',
        '[{"source":"csv_exact","status":"success"}]',
        '[{"higaonon":"  ","source":"csv_exact","status":"success"}]',
      ]) {
        final client = MockClient((request) async {
          if (request.method == 'POST') {
            return http.Response(jsonEncode({'event_id': 'event'}), 200);
          }
          return http.Response(
            'event: complete\ndata: $eventData\n\n',
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        });
        final service = HuggingFaceCsvTranslationService(client: client);

        await expectLater(
          service.translate('English input'),
          throwsA(isA<HuggingFaceCsvTranslationException>()),
        );

        service.dispose();
        client.close();
      }
    });

    test('surfaces Gradio error events for fallback handling', () async {
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'event_id': 'event'}), 200);
        }
        return http.Response(
          'event: error\ndata: "Generation unavailable"\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final service = HuggingFaceCsvTranslationService(client: client);

      await expectLater(
        service.translate('English input'),
        throwsA(
          isA<HuggingFaceCsvTranslationException>().having(
            (error) => error.message,
            'message',
            contains('Generation unavailable'),
          ),
        ),
      );

      service.dispose();
      client.close();
    });

    test('does not make a request for empty input', () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('', 500);
      });
      final service = HuggingFaceCsvTranslationService(client: client);

      await expectLater(
        service.translate('  '),
        throwsA(isA<HuggingFaceCsvTranslationException>()),
      );

      expect(requestCount, 0);
      service.dispose();
      client.close();
    });
  });
}
