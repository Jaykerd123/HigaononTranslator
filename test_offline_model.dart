import 'dart:io';

void main() {
  const modelPath = 'assets/higaonon_mobile';

  final files = [
    'encoder_model.onnx',
    'decoder_model.onnx',
    'decoder_with_past_model.onnx',
    'source.spm',
    'target.spm',
    'vocab.json',
    'tokenizer_config.json',
    'special_tokens_map.json',
  ];

  print('========================================');
  print('HIGAONON MODEL FILE TEST');
  print('========================================');

  for (final file in files) {
    final path = '$modelPath/$file';
    final f = File(path);

    if (f.existsSync()) {
      final size = f.lengthSync();

      print('✓ $file');
      print('  Size: $size bytes');
    } else {
      print('✗ $file');
      print('  NOT FOUND: $path');
    }
  }

  print('========================================');
  print('TEST COMPLETE');
  print('========================================');
}