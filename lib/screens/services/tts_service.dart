import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static const String _hfToken = String.fromEnvironment('HF_TOKEN', defaultValue: ''); 
  
  // New Hugging Face Router URL
  static const String _primaryUrl = "https://router.huggingface.co/models/facebook/mms-tts-ceb";
  // Classic Inference URL (Backup)
  static const String _backupUrl = "https://api-inference.huggingface.co/models/facebook/mms-tts-ceb";

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
      print('[TtsService] No HF Token. Using system TTS.');
      await _flutterTts.speak(text);
      return;
    }

    // Try Primary URL (Router)
    bool success = await _callApi(_primaryUrl, text);
    
    // If Primary fails, try Backup URL (Classic)
    if (!success) {
      print('[TtsService] Retrying with backup URL...');
      success = await _callApi(_backupUrl, text);
    }

    // If both fail, use system TTS
    if (!success) {
      print('[TtsService] Both APIs failed. Falling back to system TTS.');
      await _flutterTts.speak(text);
    }
  }

  Future<bool> _callApi(String url, String text) async {
    try {
      print('[TtsService] POST -> $url');
      final response = await http.post(
        Uri.parse(url),
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
        if (audioBytes.length < 100) {
           print('[TtsService] API returned suspiciously small file (${audioBytes.length} bytes).');
           return false;
        }

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav');
        await file.writeAsBytes(audioBytes);

        print('[TtsService] SUCCESS: Audio received. Playing...');
        await _audioPlayer.play(DeviceFileSource(file.path));
        return true;
      } else {
        print('[TtsService] API ERROR ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[TtsService] REQUEST EXCEPTION: $e');
      return false;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}
