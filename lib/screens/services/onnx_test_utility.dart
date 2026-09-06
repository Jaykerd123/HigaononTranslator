import 'onnx_translation_service.dart';

void main() async {
  print('========================================');
  print('ONNX MODEL INSPECTION & TEST');
  print('========================================');

  final service = OnnxTranslationService();

  try {
    print('Initializing service with local paths...');
    await service.initWithPaths(
      encoderPath: 'assets/higaonon_mobile/encoder_model.onnx',
      decoderPath: 'assets/higaonon_mobile/decoder_model.onnx',
      decoderWithPastPath: 'assets/higaonon_mobile/decoder_with_past_model.onnx',
      spmPath: 'assets/higaonon_mobile/source.spm',
      vocabPath: 'assets/higaonon_mobile/vocab.json',
    );
    print('Initialization complete.');

    print('\nStarting test translation...');
    final result = await service.translate('I love you.');
    print('\nResult: "$result"');
    print('Expected: "Kabayaan ku Ikaw."');

  } catch (e, stackTrace) {
    print('Error during test: $e');
    print(stackTrace);
  } finally {
    service.dispose();
  }
}
