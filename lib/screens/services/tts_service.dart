import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  // Use Meta's MMS TTS via Hugging Face Inference API
  static const String _hfToken = String.fromEnvironment('HF_TOKEN', defaultValue: '');
  
  // Try the direct model URL which sometimes bypasses router issues if correctly prefixed
  static const String _modelUrl = 'https://api-inference.huggingface.co/models/facebook/mms-tts-ceb';
  // Fallback URL if the above is strictly blocked
  static const String _routerUrl = 'https://router.huggingface.co/hf-inference/models/facebook/mms-tts-ceb';

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

    // 1. Try Hugging Face Meta MMS (High Quality Bisaya)
    bool success = await _speakHuggingFace(text, _modelUrl);
    
    // 2. If direct fails, try router URL
    if (!success) {
      print('[TtsService] Direct API failed, trying Router URL...');
      success = await _speakHuggingFace(text, _routerUrl);
    }

    // 3. Fallback to Local TTS (Lower Quality/Tagalog)
    if (!success) {
      print('[TtsService] All API calls failed. Falling back to Local TTS.');
      await _flutterTts.speak(text);
    }
  }

  Future<bool> _speakHuggingFace(String text, String url) async {
    try {
      print('[TtsService] Requesting HF API: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          if (_hfToken.isNotEmpty) 'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/json',
          'x-use-cache': 'false', // Ensure we don't get stale errors
        },
        body: '{"inputs": "${text.replaceAll('"', '\\\\"')}"}',
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ?? false) {
           print('[TtsService] API returned JSON instead of audio: ${response.body}');
           return false;
        }

        final Uint8List audioBytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_audio.flac');
        await file.writeAsBytes(audioBytes);

        print('[TtsService] SUCCESS: Playing API audio (${audioBytes.length} bytes)');
        await _audioPlayer.play(DeviceFileSource(file.path));
        return true;
      } else {
        print('[TtsService] API Error ${response.statusCode}: ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}');
        return false;
      }
    } catch (e) {
      print('[TtsService] API Exception: $e');
      return false;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}

