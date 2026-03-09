import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class TtsService {
  // Use String.fromEnvironment to keep the token out of the source code.
  // You can pass it during build/run with: --dart-define=HF_TOKEN=your_token_here
  static const String _hfToken = String.fromEnvironment('HF_TOKEN', defaultValue: ''); 
  static const String _modelUrl = "https://api-inference.huggingface.co/models/facebook/mms-tts-ceb";

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (_hfToken.isEmpty) {
      print('[TtsService] Error: Hugging Face Token is missing. Build with --dart-define=HF_TOKEN=your_token');
      return;
    }

    try {
      print('[TtsService] Requesting AI voice for: $text');
      
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          "Authorization": "Bearer $_hfToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"inputs": text}),
      );

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        
        // Save to a temporary file to play
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_audio.wav');
        await file.writeAsBytes(audioBytes);

        print('[TtsService] Audio received, playing...');
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        print('[TtsService] API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[TtsService] Exception: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
