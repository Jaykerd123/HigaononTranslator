
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';

class OnnxTranslationService {
static final OnnxTranslationService _instance =
OnnxTranslationService._internal();

factory OnnxTranslationService() => _instance;

OnnxTranslationService._internal();

bool _isInitialized = false;

OrtSession? _encoderSession;
OrtSession? _decoderSession;
OrtSession? _decoderWithPastSession;

SentencePieceTokenizer? _tokenizer;
Map<String, dynamic>? _vocab;

// These MUST match the exported MarianMT ONNX model.
final int _decoderStartTokenId = 56823;
final int _eosTokenId = 0;

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

print(
'ONNX Encoder inputs: ${_encoderSession!.inputNames}',
);

print(
'ONNX Decoder inputs: ${_decoderSession!.inputNames}',
);

print(
'ONNX Decoder-with-past inputs: '
'${_decoderWithPastSession!.inputNames}',
);

print(
'ONNX Decoder-with-past outputs: '
'${_decoderWithPastSession!.outputNames}',
);

// Load source SentencePiece tokenizer.
final spmData = await rootBundle.load(
'assets/higaonon_mobile/source.spm',
);

final spmFile = File(
'${modelDir.path}/source.spm',
);

await spmFile.writeAsBytes(
spmData.buffer.asUint8List(),
flush: true,
);

_tokenizer =
SentencePieceTokenizer.fromModelFileSync(
spmFile.path,
);

// Load Marian vocabulary.
final vocabData = await rootBundle.loadString(
'assets/higaonon_mobile/vocab.json',
);

_vocab = json.decode(vocabData);

_isInitialized = true;

print(
'ONNX Translation initialization successful.',
);
} catch (e) {
print(
'ONNX Translation initialization failed: $e',
);

rethrow;
}
}

Future<void> initWithPaths({
required String encoderPath,
required String decoderPath,
required String decoderWithPastPath,
required String spmPath,
required String vocabPath,
}) async {
if (_isInitialized) return;

OrtEnv.instance.init();

_encoderSession = OrtSession.fromFile(
File(encoderPath),
OrtSessionOptions(),
);

_decoderSession = OrtSession.fromFile(
File(decoderPath),
OrtSessionOptions(),
);

_decoderWithPastSession = OrtSession.fromFile(
File(decoderWithPastPath),
OrtSessionOptions(),
);

_tokenizer =
SentencePieceTokenizer.fromModelFileSync(
spmPath,
);

final vocabData =
File(vocabPath).readAsStringSync();

_vocab = json.decode(vocabData);

_isInitialized = true;
}

Future<OrtSession> _loadSession(
String assetPath,
String localPath,
) async {
final file = File(localPath);

if (!await file.exists()) {
final data = await rootBundle.load(assetPath);

await file.writeAsBytes(
data.buffer.asUint8List(),
flush: true,
);
}

return OrtSession.fromFile(
file,
OrtSessionOptions(),
);
}

Future<String?> translate(String text) async {
if (!_isInitialized) {
await init();
}

try {
// ============================================================
// 1. TOKENIZATION
// ============================================================

final encoded = _tokenizer!.encode(text);

// Diagnostic output.
print('');
print('========== ONNX TRANSLATION ==========');
print('Input: $text');

print(
'RAW TOKENIZER RESULT: $encoded',
);

final pieces = encoded.tokens;

print(
'Tokenizer pieces: $pieces',
);

final List<int> inputIds = [];

for (final token in pieces) {
final dynamic tokenId = _vocab![token];

if (tokenId == null) {
throw Exception(
'Token not found in vocab: $token',
);
}

inputIds.add(
tokenId as int,
);
}

// Marian encoder input ends with EOS.
inputIds.add(_eosTokenId);

print(
'Input IDs: $inputIds',
);

// ============================================================
// 2. ENCODER
// ============================================================

final int batchSize = 1;
final int sequenceLength = inputIds.length;

final inputIdsTensor =
OrtValueTensor.createTensorWithDataList(
Int64List.fromList(inputIds),
[batchSize, sequenceLength],
);

final attentionMask =
OrtValueTensor.createTensorWithDataList(
Int64List.fromList(
List<int>.filled(
sequenceLength,
1,
),
),
[batchSize, sequenceLength],
);

print(
'Attention mask: '
'${List<int>.filled(sequenceLength, 1)}',
);

final encoderInputs = <String, OrtValue>{
'input_ids': inputIdsTensor,
'attention_mask': attentionMask,
};

final encoderOutputs =
await _encoderSession!.run(
OrtRunOptions(),
encoderInputs,
);

if (encoderOutputs.isEmpty) {
throw Exception(
'Encoder returned no outputs.',
);
}

final encoderHiddenStates =
encoderOutputs[0] as OrtValueTensor;

print(
'Encoder output type: '
'${encoderHiddenStates.runtimeType}',
);

// ============================================================
// 3. INITIAL DECODER
// ============================================================

print(
'Decoder start token: '
'$_decoderStartTokenId',
);

final decoderInputIds =
OrtValueTensor.createTensorWithDataList(
Int64List.fromList([
_decoderStartTokenId,
]),
[batchSize, 1],
);

final decoderInputs = <String, OrtValue>{
'input_ids': decoderInputIds,
'encoder_hidden_states':
encoderHiddenStates,
'encoder_attention_mask':
attentionMask,
};

final decoderOutputs =
await _decoderSession!.run(
OrtRunOptions(),
decoderInputs,
);

if (decoderOutputs.isEmpty) {
throw Exception(
'Decoder returned no outputs.',
);
}

final logits =
decoderOutputs[0] as OrtValueTensor;

print(
'Initial decoder logits type: '
'${logits.runtimeType}',
);

// ============================================================
// 4. INITIAL KV CACHE
// ============================================================

final Map<String, OrtValue> decoderCache = {};
final Map<String, OrtValue> encoderCache = {};

final List<OrtValue> tensorsToRelease = [];

final decoderOutputNames =
_decoderSession!.outputNames;

for (
int i = 1;
i < decoderOutputs.length;
i++
) {
final outputName =
decoderOutputNames[i];

final ortValue =
decoderOutputs[i]!;

tensorsToRelease.add(
ortValue,
);

final pastName =
outputName.replaceFirst(
'present.',
'past_key_values.',
);

if (pastName.contains('.decoder.')) {
decoderCache[pastName] =
ortValue;
} else if (
pastName.contains('.encoder.')) {
encoderCache[pastName] =
ortValue;
}
}

print(
'Initial decoder cache count: '
'${decoderCache.length}',
);

print(
'Initial encoder cache count: '
'${encoderCache.length}',
);

if (decoderCache.length != 12) {
throw Exception(
'Expected 12 decoder cache tensors, '
'got ${decoderCache.length}.',
);
}

if (encoderCache.length != 12) {
throw Exception(
'Expected 12 encoder cache tensors, '
'got ${encoderCache.length}.',
);
}

// ============================================================
// 5. FIRST TOKEN
// ============================================================

int nextToken =
_getArgmax(logits);

print(
'First generated token ID: '
'$nextToken',
);

final List<int> generatedTokens = [];

const int maxTokens = 100;

int step = 0;

// ============================================================
// 6. GREEDY DECODING LOOP
// ============================================================

while (
nextToken != _eosTokenId &&
step < maxTokens) {
generatedTokens.add(
nextToken,
);

print(
'Step $step: input token = '
'$nextToken',
);

final loopInputIds =
OrtValueTensor.createTensorWithDataList(
Int64List.fromList([
nextToken,
]),
[batchSize, 1],
);

final loopInputs =
<String, OrtValue>{
'input_ids': loopInputIds,
'encoder_attention_mask':
attentionMask,
};

// ------------------------------------------------------------
// Decoder cache
// ------------------------------------------------------------

for (
final entry
in decoderCache.entries
) {
loopInputs[entry.key] =
entry.value;
}

// ------------------------------------------------------------
// Encoder cache
//
// IMPORTANT:
// Encoder cache is NOT replaced.
// ------------------------------------------------------------

for (
final entry
in encoderCache.entries
) {
loopInputs[entry.key] =
entry.value;
}

// Verify every required input.
if (step == 0) {
final requiredInputs =
_decoderWithPastSession!
    .inputNames;

print(
'Decoder-with-past input count: '
'${requiredInputs.length}',
);

for (
final required
in requiredInputs
) {
if (!loopInputs
    .containsKey(required)) {
throw Exception(
'Missing decoder-with-past input: '
'$required',
);
}
}

print(
'All decoder-with-past inputs supplied.',
);
}

// ------------------------------------------------------------
// Run decoder-with-past
// ------------------------------------------------------------

final loopOutputs =
await _decoderWithPastSession!.run(
OrtRunOptions(),
loopInputs,
);

if (loopOutputs.isEmpty) {
throw Exception(
'Decoder-with-past returned no outputs.',
);
}

final loopLogits =
loopOutputs[0] as OrtValueTensor;

// ------------------------------------------------------------
// Argmax
// ------------------------------------------------------------

nextToken =
_getArgmax(loopLogits);

print(
'Step $step: generated token = '
'$nextToken',
);

// ------------------------------------------------------------
// Replace ONLY decoder cache.
// ------------------------------------------------------------

final Map<String, OrtValue>
nextDecoderCache = {};

final pastOutputNames =
_decoderWithPastSession!
    .outputNames;

for (
int i = 1;
i < loopOutputs.length;
i++
) {
final outputName =
pastOutputNames[i];

final ortValue =
loopOutputs[i]!;

tensorsToRelease.add(
ortValue,
);

final pastName =
outputName.replaceFirst(
'present.',
'past_key_values.',
);

if (
pastName.contains(
'.decoder.',
)) {
nextDecoderCache[
pastName] = ortValue;
}
}

if (nextDecoderCache.length != 12) {
throw Exception(
'Expected 12 updated decoder cache '
'tensors, got '
'${nextDecoderCache.length}.',
);
}

decoderCache
..clear()
..addAll(
nextDecoderCache,
);

loopInputIds.release();
loopLogits.release();

step++;
}

// ============================================================
// 7. FINAL TOKEN IDs
// ============================================================

print(
'Generated token IDs: '
'$generatedTokens',
);

print(
'Generation stopped because: '
'${nextToken == _eosTokenId ? "EOS" : "max tokens"}',
);

// ============================================================
// 8. DETOKENIZATION
// ============================================================

final Map<int, String> idToToken =
{};

for (
final entry
in _vocab!.entries
) {
idToToken[
entry.value as int] =
entry.key;
}

final List<String> resultTokens =
generatedTokens.map(
(id) =>
idToToken[id] ?? '',
).toList();

final String result =
resultTokens
    .join('')
    .replaceAll(
'\u2581',
' ',
)
    .trim();

print(
'Translation: $result',
);

print(
'======================================',
);

// ============================================================
// 9. CLEANUP
// ============================================================

inputIdsTensor.release();
attentionMask.release();
encoderHiddenStates.release();
decoderInputIds.release();
logits.release();

for (
final tensor
in tensorsToRelease
) {
tensor.release();
}

return result;
} catch (e, stackTrace) {
print(
'ONNX Translation failed: $e',
);

print(stackTrace);

return null;
}
}

int _getArgmax(
OrtValueTensor logits,
) {
final dynamic data =
logits.value;

if (data is! List ||
data.isEmpty) {
throw Exception(
'Invalid logits tensor data.',
);
}

final dynamic batch =
data[0];

if (batch is! List ||
batch.isEmpty) {
throw Exception(
'Invalid logits batch structure.',
);
}

final dynamic lastStep =
batch[batch.length - 1];

if (lastStep is! List ||
lastStep.isEmpty) {
throw Exception(
'Invalid logits sequence structure.',
);
}

double maxValue =
double.negativeInfinity;

int maxIndex = 0;

for (
int i = 0;
i < lastStep.length;
i++
) {
final dynamic value =
lastStep[i];

final double score =
(value as num).toDouble();

if (score > maxValue) {
maxValue = score;
maxIndex = i;
}
}

return maxIndex;
}

void dispose() {
_encoderSession?.release();
_decoderSession?.release();
_decoderWithPastSession?.release();

_encoderSession = null;
_decoderSession = null;
_decoderWithPastSession = null;

_isInitialized = false;

OrtEnv.instance.release();
}
}