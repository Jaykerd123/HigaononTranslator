import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class TtsService {
  // Use Meta's MMS TTS via Hugging Face Inference API
  // You can get a free API token at https://huggingface.co/settings/tokens
  static const String _hfToken = String.fromEnvironment('HF_TOKEN', defaultValue: ''); 
  static const String _modelUrl = 'https://router.huggingface.co/models/facebook/mms-tts-ceb';

  final AudioPlayer _audioPlayer = AudioPlayer();

  TtsService() {
    print('[TtsService] Initialized with Meta MMS (Bisaya) approach.');
    if (_hfToken.isEmpty) {
      print('[TtsService] WARNING: No Hugging Face Token (HF_TOKEN) provided. API may be rate limited.');
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    try {
      print('[TtsService] Requesting Meta MMS (Bisaya) for: "$text"');
      
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          if (_hfToken.isNotEmpty) 'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/json',
        },
        body: '{"inputs": "${text.replaceAll('"', '\\"')}"}',
      );

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        
        // Check if the response is actually an image/audio or an error JSON
        if (response.headers['content-type']?.contains('application/json') ?? false) {
           print('[TtsService] Error from API: ${response.body}');
           return;
        }

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_mms_bisaya.flac');
        await file.writeAsBytes(audioBytes);

        print('[TtsService] SUCCESS: Playing Meta MMS audio (${audioBytes.length} bytes)');
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        print('[TtsService] HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('[TtsService] Exception in speak: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
