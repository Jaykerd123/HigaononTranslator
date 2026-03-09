import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  // Use String.fromEnvironment to keep the token out of the source code.
  // You can pass it during build/run with: --dart-define=HF_TOKEN=your_token_here
  static const String _hfToken = String.fromEnvironment('HF_TOKEN', defaultValue: ''); 
  static const String _modelUrl = "https://api-inference.huggingface.co/models/facebook/mms-tts-ceb";

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initSystemTts();
    print('[TtsService] Initialized. Token present: ${_hfToken.isNotEmpty}');
    if (_hfToken.isNotEmpty) {
      print('[TtsService] Token starts with: ${_hfToken.substring(0, 4)}...');
    }
  }

  Future<void> _initSystemTts() async {
    await _flutterTts.setLanguage("ceb-PH");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    // If token is missing, fallback to system TTS
    if (_hfToken.isEmpty) {
      print('[TtsService] Hugging Face Token missing, falling back to system TTS.');
      await _flutterTts.speak(text);
      return;
    }

    try {
      print('[TtsService] Requesting AI voice for: $text');
      
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          "Authorization": "Bearer $_hfToken",
          "Content-Type": "application/json",
          "x-use-cache": "false", // Try to bypass cache to see if it helps with 410
        },
        body: jsonEncode({
          "inputs": text,
          "options": {"wait_for_model": true}
        }),
      );

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        
        // Save to a temporary file to play
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_audio.wav');
        await file.writeAsBytes(audioBytes);

        print('[TtsService] Audio received (${audioBytes.length} bytes), playing...');
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        print('[TtsService] API Error: ${response.statusCode}');
        print('[TtsService] Response body: ${response.body}');
        print('[TtsService] Falling back to system TTS.');
        await _flutterTts.speak(text);
      }
    } catch (e) {
      print('[TtsService] Exception: $e, falling back to system TTS.');
      await _flutterTts.speak(text);
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}
