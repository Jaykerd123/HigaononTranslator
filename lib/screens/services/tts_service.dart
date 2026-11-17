import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:Higa/screens/services/app_logger.dart';
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

  static const String hfSpaceBase = 'https://jaykerd-higaonon-tts.hf.space';

  // Hugging Face token supplied when building/running Flutter:
  //
  // flutter run --dart-define=HF_TOKEN=hf_xxxxxxxxx
  //
  static const String hfToken = String.fromEnvironment('HF_TOKEN');

  static const Duration queueTimeout = Duration(seconds: 30);

  static const Duration streamTimeout = Duration(seconds: 120);

  static const Duration downloadTimeout = Duration(seconds: 60);

  // ============================================================
  // INITIALIZATION
  // ============================================================

  TtsService() {
    AppLogger.debug('TTS', 'Service initialized.');

    if (hfToken.isEmpty) {
      AppLogger.debug('TTS', 'Hugging Face authentication is not configured.');
    } else {
      AppLogger.debug('TTS', 'Hugging Face authentication is configured.');
    }

    _initLocalTts();
  }

  Future<void> refreshServerConnection() async {
    AppLogger.debug(
      'TTS',
      'Cloud-hosted TTS does not require local discovery.',
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
            final locale = (v['locale'] ?? v['language'] ?? '')
                .toString()
                .toLowerCase();

            final name = (v['name'] ?? '').toString().toLowerCase();

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
            final name = (v['name'] ?? '').toString().toLowerCase();

            if (maleKeywords.any((keyword) => name.contains(keyword))) {
              maleVoiceMap = v;
              break;
            }
          }
        }

        final chosen =
            maleVoiceMap ??
            (filipinoVoices.isNotEmpty ? filipinoVoices.first as Map? : null);

        if (chosen != null) {
          selectedVoice = {
            'name': chosen['name']?.toString() ?? '',
            'locale': (chosen['locale'] ?? chosen['language'] ?? 'fil-PH')
                .toString(),
          };
        }

        if (selectedVoice != null && selectedVoice['name']!.isNotEmpty) {
          AppLogger.debug('TTS', 'Local fallback voice selected.');

          await _flutterTts.setVoice(selectedVoice);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'TTS',
        'Local TTS initialization failed (${e.runtimeType}).',
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // PUBLIC SPEAK FUNCTION
  // ============================================================

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    AppLogger.debug('TTS', 'Request received.');
    AppLogger.debug('TTS', 'Input text: $text');

    final bool success = await _speakFromHuggingFace(text);

    if (!success) {
      AppLogger.error(
        'TTS',
        'Hugging Face generation failed; using local TTS fallback.',
      );

      try {
        await _flutterTts.speak(text);
        AppLogger.debug('TTS', 'Local audio playback started.');
      } catch (error, stackTrace) {
        AppLogger.error(
          'TTS',
          'Local audio playback failed (${error.runtimeType}).',
          stackTrace: stackTrace,
        );
      }
    }
  }

  // ============================================================
  // HUGGING FACE GRADIO API
  // ============================================================

  Future<bool> _speakFromHuggingFace(String text) async {
    final client = http.Client();

    try {
      // ----------------------------------------------------------
      // CHECK TOKEN
      // ----------------------------------------------------------

      if (hfToken.isEmpty) {
        AppLogger.error(
          'API',
          'Hugging Face authentication token is not configured.',
        );

        return false;
      }

      // ----------------------------------------------------------
      // 1. CLEAN TEXT
      // ----------------------------------------------------------

      String cleanText = text.toLowerCase().trim();

      cleanText = cleanText.replaceAll('aw ', 'au ').replaceAll('aw', 'au');

      cleanText = cleanText.split(RegExp(r'\s+')).join(' ');

      AppLogger.debug('TTS', 'Text prepared for the Hugging Face request.');

      // ----------------------------------------------------------
      // 2. START GRADIO PREDICTION
      // ----------------------------------------------------------

      final queueUrl = Uri.parse('$hfSpaceBase/gradio_api/call/synthesize');

      final queueStopwatch = Stopwatch()..start();
      AppLogger.apiRequest('POST', queueUrl);
      AppLogger.debug('TTS', 'Sending request to Hugging Face.');
      late final http.Response queueResponse;

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
      } catch (error, stackTrace) {
        AppLogger.error(
          'API',
          'TTS POST failed (${error.runtimeType}).',
          stackTrace: stackTrace,
        );
        AppLogger.error(
          'TTS',
          'Hugging Face request failed (${error.runtimeType}).',
        );

        return false;
      } finally {
        AppLogger.debug(
          'API',
          'Request duration: ${queueStopwatch.elapsedMilliseconds} ms',
        );
      }

      AppLogger.apiResponse(queueResponse.statusCode);
      AppLogger.debug('TTS', 'HTTP status: ${queueResponse.statusCode}');

      if (queueResponse.statusCode != 200) {
        AppLogger.error(
          'API',
          'TTS POST returned HTTP ${queueResponse.statusCode}.',
        );
        AppLogger.error('TTS', 'Gradio request returned an HTTP failure.');

        return false;
      }

      // ----------------------------------------------------------
      // 3. GET EVENT ID
      // ----------------------------------------------------------

      final decodedQueue = jsonDecode(queueResponse.body);

      if (decodedQueue is! Map) {
        AppLogger.error('API', 'TTS POST returned an unexpected response.');
        AppLogger.error('TTS', 'Invalid Gradio queue response.');

        return false;
      }

      final eventId = decodedQueue['event_id']?.toString();

      if (eventId == null || eventId.isEmpty) {
        AppLogger.error(
          'API',
          'TTS POST response did not contain an event ID.',
        );
        AppLogger.error('TTS', 'Gradio response did not contain an event ID.');

        return false;
      }

      AppLogger.debug('TTS', 'Gradio event ID: $eventId');
      AppLogger.debug('TTS', 'Audio generation started.');

      // ----------------------------------------------------------
      // 4. CONNECT TO SSE STREAM
      // ----------------------------------------------------------

      final streamUrl = Uri.parse(
        '$hfSpaceBase/gradio_api/call/synthesize/$eventId',
      );

      AppLogger.debug('TTS', 'Connecting to SSE.');

      final request = http.Request('GET', streamUrl);

      request.headers['Accept'] = 'text/event-stream';

      request.headers['Cache-Control'] = 'no-cache';

      // IMPORTANT:
      // Authentication must also be sent to SSE endpoint.
      request.headers['Authorization'] = 'Bearer $hfToken';

      final streamStopwatch = Stopwatch()..start();
      AppLogger.apiRequest('GET', streamUrl);
      late final http.StreamedResponse streamedResponse;

      try {
        streamedResponse = await client.send(request).timeout(streamTimeout);
      } catch (error, stackTrace) {
        AppLogger.error(
          'API',
          'TTS SSE connection failed (${error.runtimeType}).',
          stackTrace: stackTrace,
        );
        AppLogger.error('TTS', 'SSE connection failed (${error.runtimeType}).');

        return false;
      } finally {
        AppLogger.debug(
          'API',
          'Request duration: ${streamStopwatch.elapsedMilliseconds} ms',
        );
      }

      AppLogger.apiResponse(streamedResponse.statusCode);
      AppLogger.debug(
        'TTS',
        'SSE connection status: ${streamedResponse.statusCode}',
      );

      if (streamedResponse.statusCode != 200) {
        AppLogger.error(
          'API',
          'TTS SSE returned HTTP ${streamedResponse.statusCode}.',
        );
        AppLogger.error('TTS', 'SSE stream returned an HTTP failure.');

        return false;
      }

      // ----------------------------------------------------------
      // 5. READ SSE EVENTS
      // ----------------------------------------------------------

      String? downloadUrl;

      String? currentEvent;

      await for (final line
          in streamedResponse.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        final trimmed = line.trim();

        if (trimmed.isEmpty) {
          continue;
        }

        // --------------------------------------------------------
        // EVENT TYPE
        // --------------------------------------------------------

        if (trimmed.startsWith('event:')) {
          currentEvent = trimmed.substring(6).trim();

          // Explicitly detect HF errors.
          if (currentEvent == 'error') {
            AppLogger.error('API', 'TTS SSE returned an error event.');
            AppLogger.error('TTS', 'Gradio SSE returned an error event.');
          }

          continue;
        }

        // --------------------------------------------------------
        // DATA
        // --------------------------------------------------------

        if (!trimmed.startsWith('data:')) {
          continue;
        }

        final dataString = trimmed.substring(5).trim();

        if (dataString.isEmpty || dataString == 'null') {
          continue;
        }

        dynamic data;

        try {
          data = jsonDecode(dataString);
        } catch (error, stackTrace) {
          AppLogger.error(
            'API',
            'TTS SSE data was invalid (${error.runtimeType}).',
            stackTrace: stackTrace,
          );
          AppLogger.error(
            'TTS',
            'SSE event contained invalid JSON (${error.runtimeType}).',
            stackTrace: stackTrace,
          );

          continue;
        }

        // --------------------------------------------------------
        // HANDLE HUGGING FACE ERROR
        // --------------------------------------------------------

        if (data is Map && data.containsKey('error')) {
          AppLogger.error('API', 'TTS Gradio response reported an error.');
          AppLogger.error('TTS', 'Gradio reported an audio generation error.');

          return false;
        }

        // --------------------------------------------------------
        // TRY TO EXTRACT AUDIO FILE
        // --------------------------------------------------------

        final extractedUrl = _extractAudioUrl(data);

        if (extractedUrl != null) {
          downloadUrl = _normalizeDownloadUrl(extractedUrl);

          AppLogger.debug('TTS', 'Audio URL received.');

          break;
        }

        // --------------------------------------------------------
        // COMPLETE EVENT BUT NO AUDIO
        // --------------------------------------------------------

        if (currentEvent == 'complete') {
          AppLogger.error('TTS', 'Complete SSE event contained no audio file.');
        }
      }
      AppLogger.debug(
        'API',
        'SSE request duration: ${streamStopwatch.elapsedMilliseconds} ms',
      );

      // ----------------------------------------------------------
      // 6. CHECK AUDIO URL
      // ----------------------------------------------------------

      if (downloadUrl == null) {
        AppLogger.error('TTS', 'No audio URL was returned by the SSE stream.');

        return false;
      }

      // ----------------------------------------------------------
      // 7. DOWNLOAD AUDIO
      // ----------------------------------------------------------

      AppLogger.debug('TTS', 'Downloading audio.');
      final downloadUri = Uri.parse(downloadUrl);
      final downloadStopwatch = Stopwatch()..start();
      AppLogger.apiRequest('GET', downloadUri);
      late final http.Response audioResponse;

      try {
        audioResponse = await client
            .get(
              downloadUri,
              headers: {
                'Accept': 'audio/wav,audio/*,*/*',

                // Keep authentication here as well.
                'Authorization': 'Bearer $hfToken',
              },
            )
            .timeout(downloadTimeout);
      } catch (error, stackTrace) {
        AppLogger.error(
          'API',
          'TTS audio download failed (${error.runtimeType}).',
          stackTrace: stackTrace,
        );
        AppLogger.error('TTS', 'Audio download failed (${error.runtimeType}).');

        return false;
      } finally {
        AppLogger.debug(
          'API',
          'Request duration: ${downloadStopwatch.elapsedMilliseconds} ms',
        );
      }

      AppLogger.apiResponse(audioResponse.statusCode);
      AppLogger.debug(
        'TTS',
        'Audio download HTTP status: ${audioResponse.statusCode}',
      );

      if (audioResponse.statusCode != 200) {
        AppLogger.error(
          'API',
          'TTS audio download returned HTTP ${audioResponse.statusCode}.',
        );
        AppLogger.error('TTS', 'Audio download returned an HTTP failure.');

        return false;
      }

      // ----------------------------------------------------------
      // 8. CHECK AUDIO DATA
      // ----------------------------------------------------------

      final Uint8List audioBytes = audioResponse.bodyBytes;

      AppLogger.debug(
        'TTS',
        'Audio download completed (${audioBytes.length} bytes).',
      );

      if (audioBytes.isEmpty) {
        AppLogger.error('TTS', 'Downloaded audio file is empty.');

        return false;
      }

      // ----------------------------------------------------------
      // 9. SAVE AUDIO
      // ----------------------------------------------------------

      final tempDir = await getTemporaryDirectory();

      final file = File('${tempDir.path}/higaonon_tts.wav');

      await file.writeAsBytes(audioBytes, flush: true);

      // ----------------------------------------------------------
      // 10. PLAY AUDIO
      // ----------------------------------------------------------

      await _flutterTts.stop();

      await _audioPlayer.stop();

      await _audioPlayer.play(DeviceFileSource(file.path));

      AppLogger.debug('TTS', 'Audio playback started.');
      AppLogger.debug('TTS', 'TTS completed successfully.');

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'API',
        'TTS request failed (${e.runtimeType}).',
        stackTrace: stackTrace,
      );
      AppLogger.error(
        'TTS',
        'Hugging Face TTS generation failed (${e.runtimeType}).',
        stackTrace: stackTrace,
      );

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
        final result = _extractAudioUrl(item);

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

      if (url != null && url.toString().isNotEmpty) {
        return url.toString();
      }

      final path = data['path'];

      if (path != null && path.toString().isNotEmpty) {
        return path.toString();
      }

      final name = data['name'];

      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }

      final file = data['file'];

      if (file != null) {
        final result = _extractAudioUrl(file);

        if (result != null) {
          return result;
        }
      }

      final audio = data['audio'];

      if (audio != null) {
        final result = _extractAudioUrl(audio);

        if (result != null) {
          return result;
        }
      }

      // ----------------------------------------------------------
      // Recursively inspect nested values
      // ----------------------------------------------------------

      for (final value in data.values) {
        final result = _extractAudioUrl(value);

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

  String _normalizeDownloadUrl(String rawUrl) {
    String url = rawUrl.trim();

    // Already absolute
    if (url.startsWith('http://') || url.startsWith('https://')) {
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
