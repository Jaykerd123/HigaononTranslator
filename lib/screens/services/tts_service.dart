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
    await _flutterTts.setLanguage("fil-PH"); // Fallback to Filipino/Tagalog if Cebuano isn't available
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
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
      possibleBaseUrls = ['http://10.0.2.2:8000', 'http://10.0.0.48:8000', 'http://10.0.0.10:8000'];
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
        ).timeout(const Duration(seconds: 4));

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

