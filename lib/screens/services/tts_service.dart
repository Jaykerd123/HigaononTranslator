import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TtsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  // ============================================================
  // HUGGING FACE TTS CONFIGURATION
  // ============================================================

  static const String hfSpaceBase =
      'https://jaykerd-higaonon-tts.hf.space';

  // Hugging Face token supplied when building/running Flutter:
  //
  // flutter run --dart-define=HF_TOKEN=hf_xxxxxxxxx
  //
  static const String hfToken =
  String.fromEnvironment('HF_TOKEN');

  static const Duration queueTimeout =
  Duration(seconds: 30);

  static const Duration streamTimeout =
  Duration(seconds: 120);

  static const Duration downloadTimeout =
  Duration(seconds: 60);

  // ============================================================
  // INITIALIZATION
  // ============================================================

  TtsService() {
    print('[TtsService] Initialized.');

    if (hfToken.isEmpty) {
      print(
        '[TtsService] WARNING: HF_TOKEN is not configured.',
      );
    } else {
      print(
        '[TtsService] Hugging Face authentication configured.',
      );
    }

    _initLocalTts();
  }

  Future<void> refreshServerConnection() async {
    print(
      '[TtsService] Cloud-hosted TTS does not require local discovery.',
    );
  }

  // ============================================================
  // LOCAL FALLBACK TTS
  // ============================================================

  Future<void> _initLocalTts() async {
    try {
      await _flutterTts.setLanguage('fil-PH');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(0.95);

      final voices = await _flutterTts.getVoices;

      if (voices is List) {
        Map<String, String>? selectedVoice;

        final filipinoVoices = voices.where((v) {
          if (v is Map) {
            final locale =
            (v['locale'] ?? v['language'] ?? '')
                .toString()
                .toLowerCase();

            final name =
            (v['name'] ?? '')
                .toString()
                .toLowerCase();

            return locale.contains('ph') ||
                locale.contains('fil') ||
                locale.contains('tl') ||
                name.contains('filipino') ||
                name.contains('tagalog') ||
                name.contains('philippines');
          }

          return false;
        }).toList();

        const maleKeywords = [
          'male',
          'man',
          'andro',
          'andrew',
          'enrique',
          'james',
        ];

        Map? maleVoiceMap;

        for (final v in filipinoVoices) {
          if (v is Map) {
            final name =
            (v['name'] ?? '')
                .toString()
                .toLowerCase();

            if (maleKeywords.any(
                  (keyword) => name.contains(keyword),
            )) {
              maleVoiceMap = v;
              break;
            }
          }
        }

        final chosen = maleVoiceMap ??
            (filipinoVoices.isNotEmpty
                ? filipinoVoices.first as Map?
                : null);

        if (chosen != null) {
          selectedVoice = {
            'name': chosen['name']?.toString() ?? '',
            'locale':
            (chosen['locale'] ??
                chosen['language'] ??
                'fil-PH')
                .toString(),
          };
        }

        if (selectedVoice != null &&
            selectedVoice['name']!.isNotEmpty) {
          print(
            '[TtsService] Local fallback voice: '
                '${selectedVoice['name']}',
          );

          await _flutterTts.setVoice(selectedVoice);
        }
      }
    } catch (e) {
      print(
        '[TtsService] Local TTS init error: $e',
      );
    }
  }

  // ============================================================
  // PUBLIC SPEAK FUNCTION
  // ============================================================

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    print(
      '[TtsService] Requesting Cloud TTS: $text',
    );

    final bool success =
    await _speakFromHuggingFace(text);

    if (!success) {
      print(
        '[TtsService] Cloud TTS failed. '
            'Falling back to local TTS.',
      );

      try {
        await _flutterTts.speak(text);
      } catch (e) {
        print(
          '[TtsService] Critical TTS failure: $e',
        );
      }
    }
  }

  // ============================================================
  // HUGGING FACE GRADIO API
  // ============================================================

  Future<bool> _speakFromHuggingFace(
      String text,
      ) async {
    final client = http.Client();

    try {
      // ----------------------------------------------------------
      // CHECK TOKEN
      // ----------------------------------------------------------

      if (hfToken.isEmpty) {
        print(
          '[TtsService] ERROR: HF_TOKEN is empty.',
        );

        print(
          '[TtsService] Run Flutter with:',
        );

        print(
          'flutter run --dart-define=HF_TOKEN=hf_your_token_here',
        );

        return false;
      }

      // ----------------------------------------------------------
      // 1. CLEAN TEXT
      // ----------------------------------------------------------

      String cleanText =
      text.toLowerCase().trim();

      cleanText = cleanText
          .replaceAll('aw ', 'au ')
          .replaceAll('aw', 'au');

      cleanText =
          cleanText.split(RegExp(r'\s+')).join(' ');

      print(
        '[TtsService] Clean text: $cleanText',
      );

      // ----------------------------------------------------------
      // 2. START GRADIO PREDICTION
      // ----------------------------------------------------------

      final queueUrl = Uri.parse(
        '$hfSpaceBase/gradio_api/call/synthesize',
      );

      print(
        '[TtsService] Sending authenticated request to HF:',
      );

      print(queueUrl);

      http.Response queueResponse;

      try {
        queueResponse = await client
            .post(
          queueUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',

            // IMPORTANT:
            // Hugging Face authentication
            'Authorization': 'Bearer $hfToken',
          },
          body: jsonEncode({
            'data': [cleanText],
          }),
        )
            .timeout(queueTimeout);
      } catch (e) {
        print(
          '[TtsService] Queue request exception: $e',
        );

        return false;
      }

      print(
        '[TtsService] Queue status: '
            '${queueResponse.statusCode}',
      );

      print(
        '[TtsService] Queue response: '
            '${queueResponse.body}',
      );

      if (queueResponse.statusCode != 200) {
        print(
          '[TtsService] Queue failed.',
        );

        return false;
      }

      // ----------------------------------------------------------
      // 3. GET EVENT ID
      // ----------------------------------------------------------

      final decodedQueue =
      jsonDecode(queueResponse.body);

      if (decodedQueue is! Map) {
        print(
          '[TtsService] Unexpected queue response.',
        );

        return false;
      }

      final eventId =
      decodedQueue['event_id']?.toString();

      if (eventId == null ||
          eventId.isEmpty) {
        print(
          '[TtsService] No event_id received.',
        );

        return false;
      }

      print(
        '[TtsService] Gradio Event ID: $eventId',
      );

      // ----------------------------------------------------------
      // 4. CONNECT TO SSE STREAM
      // ----------------------------------------------------------

      final streamUrl = Uri.parse(
        '$hfSpaceBase/gradio_api/call/synthesize/$eventId',
      );

      print(
        '[TtsService] Connecting to authenticated SSE:',
      );

      print(streamUrl);

      final request =
      http.Request('GET', streamUrl);

      request.headers['Accept'] =
      'text/event-stream';

      request.headers['Cache-Control'] =
      'no-cache';

      // IMPORTANT:
      // Authentication must also be sent to SSE endpoint.
      request.headers['Authorization'] =
      'Bearer $hfToken';

      http.StreamedResponse streamedResponse;

      try {
        streamedResponse = await client
            .send(request)
            .timeout(streamTimeout);
      } catch (e) {
        print(
          '[TtsService] SSE connection error: $e',
        );

        return false;
      }

      print(
        '[TtsService] SSE status: '
            '${streamedResponse.statusCode}',
      );

      if (streamedResponse.statusCode != 200) {
        print(
          '[TtsService] SSE stream failed.',
        );

        return false;
      }

      // ----------------------------------------------------------
      // 5. READ SSE EVENTS
      // ----------------------------------------------------------

      String? downloadUrl;

      String? currentEvent;

      await for (
      final line
      in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(
        const LineSplitter(),
      )
      ) {
        final trimmed = line.trim();

        if (trimmed.isEmpty) {
          continue;
        }

        print(
          '[TtsService] SSE: $trimmed',
        );

        // --------------------------------------------------------
        // EVENT TYPE
        // --------------------------------------------------------

        if (trimmed.startsWith('event:')) {
          currentEvent =
              trimmed.substring(6).trim();

          print(
            '[TtsService] SSE event: '
                '$currentEvent',
          );

          // Explicitly detect HF errors.
          if (currentEvent == 'error') {
            print(
              '[TtsService] Hugging Face returned an error event.',
            );
          }

          continue;
        }

        // --------------------------------------------------------
        // DATA
        // --------------------------------------------------------

        if (!trimmed.startsWith('data:')) {
          continue;
        }

        final dataString =
        trimmed.substring(5).trim();

        if (dataString.isEmpty ||
            dataString == 'null') {
          continue;
        }

        print(
          '[TtsService] SSE data: '
              '$dataString',
        );

        dynamic data;

        try {
          data = jsonDecode(dataString);
        } catch (e) {
          print(
            '[TtsService] SSE data is not JSON.',
          );

          continue;
        }

        // --------------------------------------------------------
        // HANDLE HUGGING FACE ERROR
        // --------------------------------------------------------

        if (data is Map &&
            data.containsKey('error')) {
          print(
            '[TtsService] ❌ Hugging Face TTS error:',
          );

          print(
            data['error'],
          );

          return false;
        }

        // --------------------------------------------------------
        // TRY TO EXTRACT AUDIO FILE
        // --------------------------------------------------------

        final extractedUrl =
        _extractAudioUrl(data);

        if (extractedUrl != null) {
          downloadUrl =
              _normalizeDownloadUrl(
                extractedUrl,
              );

          print(
            '[TtsService] ✓ Audio URL found:',
          );

          print(downloadUrl);

          break;
        }

        // --------------------------------------------------------
        // COMPLETE EVENT BUT NO AUDIO
        // --------------------------------------------------------

        if (currentEvent == 'complete') {
          print(
            '[TtsService] Complete event received '
                'but no audio file was detected.',
          );
        }
      }

      // ----------------------------------------------------------
      // 6. CHECK AUDIO URL
      // ----------------------------------------------------------

      if (downloadUrl == null) {
        print(
          '[TtsService] No audio URL found in stream.',
        );

        print(
          '[TtsService] Full cloud TTS attempt failed.',
        );

        return false;
      }

      // ----------------------------------------------------------
      // 7. DOWNLOAD AUDIO
      // ----------------------------------------------------------

      print(
        '[TtsService] Downloading audio:',
      );

      print(downloadUrl);

      http.Response audioResponse;

      try {
        audioResponse = await client
            .get(
          Uri.parse(downloadUrl),
          headers: {
            'Accept': 'audio/wav,audio/*,*/*',

            // Keep authentication here as well.
            'Authorization': 'Bearer $hfToken',
          },
        )
            .timeout(downloadTimeout);
      } catch (e) {
        print(
          '[TtsService] Audio download exception: $e',
        );

        return false;
      }

      print(
        '[TtsService] Audio response status: '
            '${audioResponse.statusCode}',
      );

      if (audioResponse.statusCode != 200) {
        print(
          '[TtsService] Audio download failed.',
        );

        print(
          '[TtsService] Response body: '
              '${audioResponse.body}',
        );

        return false;
      }

      // ----------------------------------------------------------
      // 8. CHECK AUDIO DATA
      // ----------------------------------------------------------

      final Uint8List audioBytes =
          audioResponse.bodyBytes;

      print(
        '[TtsService] Downloaded audio bytes: '
            '${audioBytes.length}',
      );

      if (audioBytes.isEmpty) {
        print(
          '[TtsService] Audio file is empty.',
        );

        return false;
      }

      // ----------------------------------------------------------
      // 9. SAVE AUDIO
      // ----------------------------------------------------------

      final tempDir =
      await getTemporaryDirectory();

      final file = File(
        '${tempDir.path}/higaonon_tts.wav',
      );

      await file.writeAsBytes(
        audioBytes,
        flush: true,
      );

      print(
        '[TtsService] Audio saved to:',
      );

      print(file.path);

      // ----------------------------------------------------------
      // 10. PLAY AUDIO
      // ----------------------------------------------------------

      await _flutterTts.stop();

      await _audioPlayer.stop();

      await _audioPlayer.play(
        DeviceFileSource(file.path),
      );

      print(
        '[TtsService] ✓ Higaonon cloud audio playback started.',
      );

      return true;
    } catch (e, stackTrace) {
      print(
        '[TtsService] HF TTS Exception: $e',
      );

      print(stackTrace);

      return false;
    } finally {
      client.close();
    }
  }

  // ============================================================
  // EXTRACT AUDIO URL FROM GRADIO RESPONSE
  // ============================================================

  String? _extractAudioUrl(dynamic data) {
    // ------------------------------------------------------------
    // CASE 1: Direct string
    // ------------------------------------------------------------

    if (data is String) {
      if (data.startsWith('http://') ||
          data.startsWith('https://') ||
          data.startsWith('/')) {
        return data;
      }

      return null;
    }

    // ------------------------------------------------------------
    // CASE 2: List
    // ------------------------------------------------------------

    if (data is List) {
      for (final item in data) {
        final result =
        _extractAudioUrl(item);

        if (result != null) {
          return result;
        }
      }

      return null;
    }

    // ------------------------------------------------------------
    // CASE 3: Map
    // ------------------------------------------------------------

    if (data is Map) {
      final url = data['url'];

      if (url != null &&
          url.toString().isNotEmpty) {
        return url.toString();
      }

      final path = data['path'];

      if (path != null &&
          path.toString().isNotEmpty) {
        return path.toString();
      }

      final name = data['name'];

      if (name != null &&
          name.toString().isNotEmpty) {
        return name.toString();
      }

      final file = data['file'];

      if (file != null) {
        final result =
        _extractAudioUrl(file);

        if (result != null) {
          return result;
        }
      }

      final audio = data['audio'];

      if (audio != null) {
        final result =
        _extractAudioUrl(audio);

        if (result != null) {
          return result;
        }
      }

      // ----------------------------------------------------------
      // Recursively inspect nested values
      // ----------------------------------------------------------

      for (final value in data.values) {
        final result =
        _extractAudioUrl(value);

        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  // ============================================================
  // NORMALIZE GRADIO FILE URL
  // ============================================================

  String _normalizeDownloadUrl(
      String rawUrl,
      ) {
    String url = rawUrl.trim();

    // Already absolute
    if (url.startsWith('http://') ||
        url.startsWith('https://')) {
      return url;
    }

    // Gradio path:
    //
    // /tmp/gradio/...
    //
    // or
    //
    // /file=...
    //

    if (url.startsWith('/')) {
      // /file=...
      if (url.startsWith('/file=')) {
        return '$hfSpaceBase/gradio_api$url';
      }

      // /gradio_api/file=...
      if (url.startsWith('/gradio_api/')) {
        return '$hfSpaceBase$url';
      }

      // Normal Gradio file path
      return '$hfSpaceBase/gradio_api/file=$url';
    }

    // Plain file path
    return '$hfSpaceBase/gradio_api/file=/$url';
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}