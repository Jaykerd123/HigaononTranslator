import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class TtsService {
  // Use Meta's MMS TTS via Hugging Face Inference API
  // You can get a free API token at https://huggingface.co/settings/tokens
  static const String _hfToken = String.fromEnvironment('HF_TOKEN', defaultValue: ''); 
  // Updated to include /hf-inference/ which is required by the new router
  static const String _modelUrl = 'https://router.huggingface.co/hf-inference/models/facebook/mms-tts-ceb';

  final AudioPlayer _audioPlayer = AudioPlayer();

  TtsService() {
    print('[TtsService] Initialized with Meta MMS (Bisaya) approach.');
    print('[TtsService] Model URL: $_modelUrl');
    if (_hfToken.isEmpty) {
      print('[TtsService] WARNING: No Hugging Face Token (HF_TOKEN) provided. API may be rate limited or return 401.');
    } else {
      print('[TtsService] HF_TOKEN is provided (starts with: ${_hfToken.substring(0, 4)}...)');
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) {
      print('[TtsService] speak() called with empty text.');
      return;
    }

    try {
      print('[TtsService] Requesting Meta MMS (Bisaya) for: "$text"');
      
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          if (_hfToken.isNotEmpty) 'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/json',
        },
        body: '{"inputs": "${text.replaceAll('"', '\\\\"')}"}',
      ).timeout(const Duration(seconds: 15));

      print('[TtsService] Response Status: ${response.statusCode}');
      print('[TtsService] Response Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        
        // Check if the response is actually JSON (which usually means an error despite 200)
        if (response.headers['content-type']?.contains('application/json') ?? false) {
           print('[TtsService] Unexpected JSON response: ${response.body}');
           return;
        }

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/tts_mms_bisaya.flac');
        await file.writeAsBytes(audioBytes);

        print('[TtsService] SUCCESS: Playing audio (${audioBytes.length} bytes)');
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        print('[TtsService] HTTP Error ${response.statusCode}');
        print('[TtsService] Error Body: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');
        
        if (response.statusCode == 401) {
          print('[TtsService] HINT: 401 usually means your HF_TOKEN is invalid or the model requires authentication.');
        } else if (response.statusCode == 429) {
          print('[TtsService] HINT: 429 means you are being rate limited. Try adding a HF_TOKEN.');
        } else if (response.statusCode == 503) {
          print('[TtsService] HINT: 503 means the model is currently loading on Hugging Face. Try again in a minute.');
        }
      }
    } catch (e) {
      print('[TtsService] Exception in speak: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
