import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'discovery_service.dart';

class TtsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    print('[TtsService] Initialized.');
    _initLocalTts();
  }

  /// Clears cached server discovery and forces a fresh scan next time
  /// Call this when the user switches networks
  Future<void> refreshServerConnection() async {
    await DiscoveryService.clearCache();
    print('[TtsService] Server connection cache cleared. Will rediscover on next TTS request.');
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
    List<String> possibleBaseUrls = [
      // Network IP (preferred for phone connectivity)
      'http://10.0.60.122:8080',
      // Localhost fallbacks
      'http://127.0.0.1:8000',
      'http://127.0.0.1:8080',
    ];

    // Add discovered URL if available (highest priority)
    if (DiscoveryService.discoveredBaseUrl != null) {
      possibleBaseUrls.insert(0, DiscoveryService.discoveredBaseUrl!);
      print('[TtsService] Using discovered server: ${DiscoveryService.discoveredBaseUrl}');
    }

    bool triedDiscovery = false;

    for (int i = 0; i < possibleBaseUrls.length; i++) {
      String baseUrl = possibleBaseUrls[i];
      try {
        final url = Uri.parse('$baseUrl/tts');
        print('[TtsService] Trying Local TTS API: $url');
        
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'text': text}),
        ).timeout(const Duration(seconds: 3)); // Reduced timeout for faster fallback

        if (response.statusCode == 200) {
          final Uint8List audioBytes = response.bodyBytes;
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/tts_audio.wav');
          await file.writeAsBytes(audioBytes);

          print('[TtsService] SUCCESS via $baseUrl: Playing Server API audio (${audioBytes.length} bytes)');
          await _audioPlayer.play(DeviceFileSource(file.path));
          return true; // Successfully played!
        }
      } catch (e) {
        print('[TtsService] API Exception from $baseUrl: $e');
        // If this was the cached URL that failed, invalidate it
        if (i == 0 && baseUrl == DiscoveryService.discoveredBaseUrl) {
          print('[TtsService] Cached server URL failed. Invalidating cache.');
          await DiscoveryService.clearCache();
        }
      }

      // If we reached the end and haven't tried discovery yet, try it now
      if (i == possibleBaseUrls.length - 1 && !triedDiscovery) {
        print('[TtsService] All known URLs failed. Attempting auto-discovery...');
        final discovered = await DiscoveryService.discoverServer(forceRescan: true);
        if (discovered != null) {
          possibleBaseUrls.add(discovered);
          triedDiscovery = true;
          // Loop will continue to the newly added discovered URL
        }
      }
    }
    return false;
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}

