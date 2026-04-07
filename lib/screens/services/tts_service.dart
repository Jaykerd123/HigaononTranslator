import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    print('[TtsService] Initialized.');
    _initLocalTts();
  }

  Future<void> _initLocalTts() async {
    try {
      // Prefer Filipino/Tagalog as the closest available to Bisaya.
      await _flutterTts.setLanguage("fil-PH");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      // Slightly lower pitch to sound more like a male voice.
      await _flutterTts.setPitch(0.95);

      // Try to pick a male Filipino/Philippines voice when available.
      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        Map<String, String>? selectedVoice;

        // Normalize and filter for Filipino / PH-related voices.
        final filipinoVoices = voices.where((v) {
          if (v is Map) {
            final locale = (v['locale'] ?? v['language'] ?? '').toString().toLowerCase();
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

        // Heuristic keywords to detect male voices by name.
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
            if (maleKeywords.any((k) => name.contains(k))) {
              maleVoiceMap = v;
              break;
            }
          }
        }

        // Prefer detected male Filipino voice; otherwise first Filipino / PH voice.
        final chosen = maleVoiceMap ?? (filipinoVoices.isNotEmpty ? filipinoVoices.first as Map? : null);
        if (chosen != null) {
          selectedVoice = {
            'name': chosen['name']?.toString() ?? '',
            'locale': (chosen['locale'] ?? chosen['language'] ?? 'fil-PH').toString(),
          };
        }

        if (selectedVoice != null && selectedVoice['name']!.isNotEmpty) {
          print('[TtsService] Using local TTS voice: ${selectedVoice['name']} (${selectedVoice['locale']})');
          await _flutterTts.setVoice(selectedVoice);
        } else {
          print('[TtsService] No specific Filipino male voice found. Using default local TTS voice.');
        }
      }
    } catch (e) {
      print('[TtsService] Error initializing local TTS: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    // 1. Try Local Python Server which runs the MMS-TTS model
    bool success = await _speakFromLocalServer(text);
    
    // 2. Fallback to Local TTS (Lower Quality/Tagalog)
    if (!success) {
      print('[TtsService] Server API failed. Falling back to Local TTS.');
      await _flutterTts.speak(text);
    }
  }

  Future<bool> _speakFromLocalServer(String text) async {
    // Determine possible URLs depending on whether we are android, web or emulator
    List<String> possibleBaseUrls = ['http://127.0.0.1:8000'];
    if (!kIsWeb && Platform.isAndroid) {
      possibleBaseUrls = ['http://127.0.0.1:8000'];
    }

    for (String baseUrl in possibleBaseUrls) {
      try {
        final url = Uri.parse('$baseUrl/tts');
        print('[TtsService] Trying Local TTS API: $url');
        
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'text': text}),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final Uint8List audioBytes = response.bodyBytes;
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/tts_audio.wav');
          await file.writeAsBytes(audioBytes);

          print('[TtsService] SUCCESS via $baseUrl: Playing Server API audio (${audioBytes.length} bytes)');
          await _audioPlayer.play(DeviceFileSource(file.path));
          return true; // Successfully played!
        } else {
          print('[TtsService] API Error ${response.statusCode} from $baseUrl');
        }
      } catch (e) {
        print('[TtsService] API Exception from $baseUrl: $e');
        // Continue to the next URL
      }
    }
    return false;
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}

