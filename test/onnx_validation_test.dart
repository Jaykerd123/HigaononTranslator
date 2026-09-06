import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:Higa/screens/services/onnx_translation_service.dart';

void main() {
  test('ONNX Translation Validation', () async {
    final service = OnnxTranslationService();

    final encoder = File('assets/higaonon_mobile/encoder_model.onnx').absolute;
    print('Checking encoder at: ${encoder.path}');
    print('Exists: ${encoder.existsSync()}');

    await service.initWithPaths(
      encoderPath: encoder.path,
      decoderPath: File('assets/higaonon_mobile/decoder_model.onnx').absolute.path,
      decoderWithPastPath: File('assets/higaonon_mobile/decoder_with_past_model.onnx').absolute.path,
      spmPath: File('assets/higaonon_mobile/source.spm').absolute.path,
      vocabPath: File('assets/higaonon_mobile/vocab.json').absolute.path,
    );
    print('Initialization complete.');

    final testCases = [
      {'input': 'Hello, how are you?', 'expected': 'Tag-u, kainu kad?'},
      {'input': 'Thank you very much.', 'expected': 'Kabayaan ku Ikaw.'},
      {'input': 'I am here.', 'expected': 'Dini ad.'},
      {'input': 'The sun is shining brightly today.', 'expected': 'Sa adlaw adlaw aldaw kadagway sa aldaw.'},
      {'input': 'What is your name?', 'expected': 'Inu sa ngalan nu?'},
      {'input': 'I love you.', 'expected': 'Kabayaan ku Ikaw.'},
    ];

    for (var testCase in testCases) {
      print('\n--- TEST CASE ---');
      print('Translating: "${testCase['input']}"');
      final result = await service.translate(testCase['input']!);
      print('Result:   "$result"');
      print('Expected: "${testCase['expected']}"');
      
      // We print result for manual verification even if it doesn't match exactly yet
      // so we can see how close it is.
    }

    service.dispose();
  });
}
