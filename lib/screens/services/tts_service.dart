import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static const String _hfToken = String.fromEnvironment('HF_TOKEN', defaultValue: ''); 
  
  // Exhaustive list of potential new HF endpoint formats
  static const List<String> _urlOptions = [
    "https://api-inference.huggingface.co/models/facebook/mms-tts-ceb",
    "https://router.huggingface.co/hf-inference/models/facebook/mms-tts-ceb",
    "https://router.huggingface.co/hf-inference/v1/models/facebook/mms-tts-ceb",
    "https://router.huggingface.co/models/facebook/mms-tts-ceb",
    "https://huggingface.co/api/models/facebook/mms-tts-ceb/inference",
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initSystemTts();
    print('[TtsService] Initialized.');
    print('[TtsService] Token status: ${_hfToken.isEmpty ? "MISSING" : "PRESENT (${_hfToken.length} chars)"}');
    if (_hfToken.isNotEmpty) {
      print('[TtsService] Token starts with: ${_hfToken.substring(0, 5)}...');
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

    if (_hfToken.isEmpty) {
      print('[TtsService] No HF Token found in --dart-define. Using system TTS.');
      await _flutterTts.speak(text);
      return;
    }

    bool success = false;
    for (String url in _urlOptions) {
      print('[TtsService] >>> ATTEMPTING URL: $url');
      success = await _callApi(url, text);
      if (success) break;
    }

    if (!success) {
      print('[TtsService] !!! ALL AI ENDPOINTS FAILED. Performing Model Diagnostic...');
      await _runDiagnostic();
      print('[TtsService] Falling back to system TTS.');
      await _flutterTts.speak(text);
    }
  }

  Future<bool> _callApi(String url, String text) async {
    try {
      final headers = {
        "Authorization": "Bearer $_hfToken",
        "Content-Type": "application/json",
        "x-use-cache": "false",
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          "inputs": text,
          "options": {"wait_for_model": true}
        }),
      );

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        if (audioBytes.length < 500) { // TTS audio should usually be > 500 bytes
           print('[TtsService] Received small response (${audioBytes.length} bytes). Might be JSON: ${response.body}');
           if (response.body.contains("error")) return false;
        }

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav');
        await file.writeAsBytes(audioBytes);

        print('[TtsService] SUCCESS: Received ${audioBytes.length} bytes. Playing...');
        await _audioPlayer.play(DeviceFileSource(file.path));
        return true;
      } else {
        print('[TtsService] RESPONSE ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[TtsService] EXCEPTION at $url: $e');
      return false;
    }
  }

  // Check if a different model works to rule out token/network issues
  Future<void> _runDiagnostic() async {
    const testUrl = "https://api-inference.huggingface.co/models/facebook/mms-tts-eng";
    print('[TtsService] Diagnostic: Checking English model ($testUrl)...');
    try {
      final response = await http.post(
        Uri.parse(testUrl),
        headers: {"Authorization": "Bearer $_hfToken", "Content-Type": "application/json"},
        body: jsonEncode({"inputs": "Test"}),
      );
      print('[TtsService] Diagnostic Result: Status ${response.statusCode}');
      if (response.statusCode == 403) {
        print('[TtsService] CRITICAL: Your token is active but lacks "Inference API" permissions.');
      }
    } catch (e) {
      print('[TtsService] Diagnostic failed: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}
