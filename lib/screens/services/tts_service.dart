import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  // Switch to VoiceRSS for Tagalog/Filipino support
  // Get your key at http://www.voicerss.org/
  static const String _apiKey = String.fromEnvironment('VOICE_RSS_KEY', defaultValue: ''); 
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initSystemTts();
    print('[TtsService] Initialized with VoiceRSS approach.');
    print('[TtsService] API Key present: ${_apiKey.isNotEmpty}');
  }

  Future<void> _initSystemTts() async {
    // System fallback set to Filipino/Tagalog
    await _flutterTts.setLanguage("fil-PH"); 
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    if (_apiKey.isEmpty) {
      print('[TtsService] No VoiceRSS Key. Using system TTS.');
      await _flutterTts.speak(text);
      return;
    }

    try {
      print('[TtsService] Requesting VoiceRSS (Tagalog) for: "$text"');
      
      // VoiceRSS Parameters:
      // hl: tl-ph (Tagalog)
      // r: 0 (speed)
      // c: WAV (codec)
      // f: 16khz_16bit_mono (format)
      final url = Uri.parse('https://api.voicerss.org/?key=$_apiKey&hl=tl-ph&src=${Uri.encodeComponent(text)}&r=0&c=WAV&f=16khz_16bit_mono');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // VoiceRSS returns error messages as text starting with "ERROR:"
        if (response.body.startsWith("ERROR:")) {
          print('[TtsService] VoiceRSS API Error: ${response.body}');
          await _flutterTts.speak(text);
          return;
        }

        final Uint8List audioBytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_voicerss.wav');
        await file.writeAsBytes(audioBytes);

        print('[TtsService] SUCCESS: Playing VoiceRSS audio (${audioBytes.length} bytes)');
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        print('[TtsService] HTTP Error ${response.statusCode}');
        await _flutterTts.speak(text);
      }
    } catch (e) {
      print('[TtsService] Exception: $e');
      await _flutterTts.speak(text);
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}
