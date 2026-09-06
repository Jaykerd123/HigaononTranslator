import 'package:onnxruntime/onnxruntime.dart';

void main() {
  print('========================================');
  print('DART ONNX RUNTIME TEST');
  print('========================================');

  try {
    OrtEnv.instance.init();

    print('✓ ONNX Runtime initialized');

    final sessionOptions = OrtSessionOptions();

    print('✓ Session options created');

    sessionOptions.release();

    print('✓ ONNX Runtime test successful');
  } catch (e, stackTrace) {
    print('✗ ONNX Runtime test failed');
    print('Error: $e');
    print(stackTrace);
  } finally {
    OrtEnv.instance.release();
  }
}