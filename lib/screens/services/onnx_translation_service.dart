import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';

class OnnxTranslationService {
  static final OnnxTranslationService _instance = OnnxTranslationService._internal();
  factory OnnxTranslationService() => _instance;
  OnnxTranslationService._internal();

  bool _isInitialized = false;
  OrtSession? _encoderSession;
  OrtSession? _decoderSession;
  OrtSession? _decoderWithPastSession;
  SentencePieceTokenizer? _tokenizer;
  Map<String, dynamic>? _vocab;

  final int _decoderStartTokenId = 56823;
  final int _eosTokenId = 0;
  final int _padTokenId = 56823;
  final int _hiddenSize = 512;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      OrtEnv.instance.init();

      final modelDir = await getApplicationDocumentsDirectory();
      
      _encoderSession = await _loadSession(
        'assets/higaonon_mobile/encoder_model.onnx',
        '${modelDir.path}/encoder_model.onnx',
      );
      _decoderSession = await _loadSession(
        'assets/higaonon_mobile/decoder_model.onnx',
        '${modelDir.path}/decoder_model.onnx',
      );
      _decoderWithPastSession = await _loadSession(
        'assets/higaonon_mobile/decoder_with_past_model.onnx',
        '${modelDir.path}/decoder_with_past_model.onnx',
      );

      print('OnnxTranslationService: Encoder Input Names: ${_encoderSession!.inputNames}');
      print('OnnxTranslationService: Decoder Input Names: ${_decoderSession!.inputNames}');
      print('OnnxTranslationService: DecoderWithPast Input Names: ${_decoderWithPastSession!.inputNames}');
      print('OnnxTranslationService: DecoderWithPast Output Names: ${_decoderWithPastSession!.outputNames}');

      // Load tokenizer
      final spmData = await rootBundle.load('assets/higaonon_mobile/source.spm');
      final spmFile = File('${modelDir.path}/source.spm');
      await spmFile.writeAsBytes(spmData.buffer.asUint8List());
      _tokenizer = SentencePieceTokenizer.fromModelFileSync(spmFile.path);

      // Load vocab
      final vocabData = await rootBundle.loadString('assets/higaonon_mobile/vocab.json');
      _vocab = json.decode(vocabData);

      _isInitialized = true;
      print('OnnxTranslationService: Initialization successful');
    } catch (e) {
      print('OnnxTranslationService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Specialized initialization for testing without Flutter context
  Future<void> initWithPaths({
    required String encoderPath,
    required String decoderPath,
    required String decoderWithPastPath,
    required String spmPath,
    required String vocabPath,
  }) async {
    if (_isInitialized) return;

    OrtEnv.instance.init();

    _encoderSession = OrtSession.fromFile(File(encoderPath), OrtSessionOptions());
    _decoderSession = OrtSession.fromFile(File(decoderPath), OrtSessionOptions());
    _decoderWithPastSession = OrtSession.fromFile(File(decoderWithPastPath), OrtSessionOptions());

    _tokenizer = SentencePieceTokenizer.fromModelFileSync(spmPath);
    final vocabData = File(vocabPath).readAsStringSync();
    _vocab = json.decode(vocabData);

    _isInitialized = true;
  }

  Future<OrtSession> _loadSession(String assetPath, String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return OrtSession.fromFile(file, OrtSessionOptions());
  }

  Future<String?> translate(String text) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      // 1. Tokenize English input
      final pieces = _tokenizer!.encode(text).tokens;
      print('Input: $text');
      print('Tokenizer pieces: $pieces');

      List<int> inputIds = [];
      for (var token in pieces) {
        final tokenId = _vocab![token];
        if (tokenId == null) {
          throw Exception('Token not found in vocab: $token');
        }
        inputIds.add(tokenId as int);
      }
      inputIds.add(_eosTokenId);
      print('Input IDs: $inputIds');

      final batchSize = 1;
      final seqLen = inputIds.length;

      // 2. Run Encoder
      final inputIdsTensor = OrtValueTensor.createTensorWithDataList(
        Int64List.fromList(inputIds),
        [batchSize, seqLen],
      );
      final attentionMask = OrtValueTensor.createTensorWithDataList(
        Int64List.fromList(List.filled(seqLen, 1)),
        [batchSize, seqLen],
      );

      final Map<String, OrtValue> encoderInputs = {
        'input_ids': inputIdsTensor,
        'attention_mask': attentionMask,
      };

      final encoderOutputs = await _encoderSession!.run(OrtRunOptions(), encoderInputs);
      final encoderHiddenStates = encoderOutputs[0] as OrtValueTensor;

      // 3. Initial Decoder
      final decoderInputIds = OrtValueTensor.createTensorWithDataList(
        Int64List.fromList([_decoderStartTokenId]),
        [batchSize, 1],
      );

      final Map<String, OrtValue> decoderInputs = {
        'input_ids': decoderInputIds,
        'encoder_hidden_states': encoderHiddenStates,
        'encoder_attention_mask': attentionMask,
      };

      final decoderOutputs = await _decoderSession!.run(OrtRunOptions(), decoderInputs);
      final logits = decoderOutputs[0] as OrtValueTensor;
      
      // Cache management: Name-based mapping
      Map<String, OrtValue> decoderCache = {};
      Map<String, OrtValue> encoderCache = {};
      List<OrtValue> allCacheTensors = [];

      final decoderOutputNames = _decoderSession!.outputNames;
      for (int i = 1; i < decoderOutputs.length; i++) {
        final outputName = decoderOutputNames[i];
        final ortValue = decoderOutputs[i]!;
        allCacheTensors.add(ortValue);

        final pastName = outputName.replaceFirst('present.', 'past_key_values.');
        
        if (pastName.contains('.decoder.')) {
          decoderCache[pastName] = ortValue;
        } else if (pastName.contains('.encoder.')) {
          encoderCache[pastName] = ortValue;
        }
      }

      print('Initial decoder cache: ${decoderCache.length}');
      print('Initial encoder cache: ${encoderCache.length}');

      // 4. Decoding Loop (Greedy)
      List<int> generatedTokens = [];
      int nextToken = _getArgmax(logits);
      
      final maxTokens = 200;
      int step = 0;

      while (nextToken != _eosTokenId && step < maxTokens) {
        generatedTokens.add(nextToken);

        final loopInputIds = OrtValueTensor.createTensorWithDataList(
          Int64List.fromList([nextToken]),
          [batchSize, 1],
        );

        final Map<String, OrtValue> loopInputs = {
          'input_ids': loopInputIds,
          'encoder_attention_mask': attentionMask,
        };

        // Add both caches to inputs
        decoderCache.forEach((key, value) {
          loopInputs[key] = value;
          // Only print once for verification
          if (step == 0) print('Mapping decoder cache: $key');
        });
        encoderCache.forEach((key, value) {
          loopInputs[key] = value;
          // Only print once for verification
          if (step == 0) print('Mapping encoder cache: $key');
        });

        final loopOutputs = await _decoderWithPastSession!.run(OrtRunOptions(), loopInputs);
        final loopLogits = loopOutputs[0] as OrtValueTensor;
        
        nextToken = _getArgmax(loopLogits);

        // Update ONLY decoder cache
        Map<String, OrtValue> nextDecoderCache = {};
        final pastOutputNames = _decoderWithPastSession!.outputNames;
        
        for (int i = 1; i < loopOutputs.length; i++) {
          final outputName = pastOutputNames[i];
          final ortValue = loopOutputs[i]!;
          
          final pastName = outputName.replaceFirst('present.', 'past_key_values.');
          
          if (pastName.contains('.decoder.')) {
            nextDecoderCache[pastName] = ortValue;
            allCacheTensors.add(ortValue);
          }
        }
        
        decoderCache = nextDecoderCache;
        if (step == 0) {
           print('Updated decoder cache count: ${decoderCache.length}');
           print('Encoder cache preserved count: ${encoderCache.length}');
        }

        loopInputIds.release();
        loopLogits.release();
        step++;
      }

      // 5. Detokenization
      final Map<int, String> idToToken = _vocab!.map((k, v) => MapEntry(v as int, k));
      List<String> resultTokens = generatedTokens.map((id) => idToToken[id] ?? '').toList();
      String result = resultTokens.join('').replaceAll('\u2581', ' ').trim();

      // Cleanup
      inputIdsTensor.release();
      attentionMask.release();
      encoderHiddenStates.release();
      decoderInputIds.release();
      logits.release();
      
      // Release all collected cache tensors at the end
      for (var tensor in allCacheTensors) {
        tensor.release();
      }

      return result;
    } catch (e) {
      print('OnnxTranslationService: Translation failed: $e');
      return null;
    }
  }

  int _getArgmax(OrtValueTensor logits) {
    // Shape: [batch, sequence, vocab]
    final data = logits.value;
    if (data is! List) return 0;
    
    // Get the last sequence step
    final batch = data[0] as List;
    final lastStepLogits = batch.last as List<double>;
    
    double maxVal = -1e38; // Use a very small number
    int maxIdx = 0;
    for (int i = 0; i < lastStepLogits.length; i++) {
      if (lastStepLogits[i] > maxVal) {
        maxVal = lastStepLogits[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  void dispose() {
    _encoderSession?.release();
    _decoderSession?.release();
    _decoderWithPastSession?.release();
    OrtEnv.instance.release();
  }
}
