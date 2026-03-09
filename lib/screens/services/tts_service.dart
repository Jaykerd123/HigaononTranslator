import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static const String _hfToken = String.fromEnvironment('HF_TOKEN', defaultValue: ''); 
  // Using the router URL as recommended by HF logs
  static const String _modelUrl = "https://router.huggingface.co/hf-inference/models/facebook/mms-tts-ceb";

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initSystemTts();
    print('[TtsService] Initialized.');
    print('[TtsService] Token status: ${_hfToken.isEmpty ? "MISSING" : "PRESENT (${_hfToken.length} chars)"}');
  }

  Future<void> _initSystemTts() async {
    await _flutterTts.setLanguage("ceb-PH");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    if (_hfToken.isEmpty) {
      print('[TtsService] Falling back to system TTS (No Token).');
      await _flutterTts.speak(text);
      return;
    }

    try {
      print('[TtsService] Calling AI API for: "$text"');
      
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          "Authorization": "Bearer $_hfToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "inputs": text,
          "options": {"wait_for_model": true}
        }),
      );

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
        await file.writeAsBytes(audioBytes);

        print('[TtsService] SUCCESS: Received ${audioBytes.length} bytes. Playing audio...');
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        print('[TtsService] API ERROR ${response.statusCode}: ${response.body}');
        print('[TtsService] Falling back to system TTS.');
        await _flutterTts.speak(text);
      }
    } catch (e) {
      print('[TtsService] EXCEPTION: $e');
      await _flutterTts.speak(text);
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}
