import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:Higa/screens/services/gemini_assistant_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GeminiAssistantService', () {
    test('sends a Gradio call and extracts the SSE answer', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'event_id': 'test-event'}), 200);
        }
        return http.Response(
          'event: heartbeat\ndata: null\n\n'
          'event: complete\ndata: ["Hello in Higaonon."]\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final service = GeminiAssistantService(client: client);

      final answer = await service.ask('  How do you say hello?  ');

      expect(answer, 'Hello in Higaonon.');
      expect(requests, hasLength(2));
      expect(requests.first.method, 'POST');
      expect(
        requests.first.url.path,
        '/gradio_api/call/ask_higaonon_assistant',
      );
      expect(jsonDecode(requests.first.body), {
        'data': ['How do you say hello?'],
      });
      expect(requests.last.method, 'GET');
      expect(
        requests.last.url.path,
        '/gradio_api/call/ask_higaonon_assistant/test-event',
      );
      expect(requests.last.headers['accept'], 'text/event-stream');

      service.dispose();
      client.close();
    });

    test('reports Gradio error events', () async {
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'event_id': 'test-event'}), 200);
        }
        return http.Response(
          'event: error\ndata: "Generation failed"\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final service = GeminiAssistantService(client: client);

      await expectLater(
        service.ask('Tell me about Higaonon.'),
        throwsA(
          isA<GeminiAssistantException>().having(
            (error) => error.message,
            'message',
            contains('Generation failed'),
          ),
        ),
      );

      service.dispose();
      client.close();
    });

    test('rejects an empty question without making a request', () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('', 500);
      });
      final service = GeminiAssistantService(client: client);

      await expectLater(
        service.ask('  '),
        throwsA(isA<GeminiAssistantException>()),
      );

      expect(requestCount, 0);
      service.dispose();
      client.close();
    });
  });
}
