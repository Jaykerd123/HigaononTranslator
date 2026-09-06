import 'dart:io';
import 'dart:convert';
import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';

void main() async {
  print('========================================');
  print('TOKENIZER VALIDATION TEST');
  print('========================================');

  final modelPath = 'assets/higaonon_mobile/source.spm';
  final vocabPath = 'assets/higaonon_mobile/vocab.json';

  if (!File(modelPath).existsSync()) {
    print('Error: $modelPath not found');
    return;
  }
  if (!File(vocabPath).existsSync()) {
    print('Error: $vocabPath not found');
    return;
  }

  try {
    // Load vocabulary to check special tokens and mapping
    final vocabContent = File(vocabPath).readAsStringSync();
    final Map<String, dynamic> vocab = json.decode(vocabContent);

    print('✓ Vocab loaded. Size: ${vocab.length}');
    print('  EOS ID: ${vocab["</s>"]} (Expected: 0)');
    print('  PAD ID: ${vocab["<pad>"]} (Expected: 56823)');

    // Initialize tokenizer
    // Note: MarianMT usually uses Unigram. dart_sentencepiece_tokenizer supports it.
    final tokenizer = SentencePieceTokenizer.fromModelFileSync(modelPath);

    final testCases = [
      {
        'text': 'I love you.',
        'expectedIds': [32, 280, 39, 4, 0]
      },
      {
        'text': 'Hello, how are you?',
        'expectedIds': null // We will see what it produces
      },
      {
        'text': 'Thank you very much.',
        'expectedIds': null
      },
      {
        'text': 'The sun is shining brightly today.',
        'expectedIds': null
      },
      {
        'text': 'What is your name?',
        'expectedIds': null
      },
    ];

    bool allMatched = true;

    for (var testCase in testCases) {
      final text = testCase['text'] as String;
      final expected = testCase['expectedIds'] as List<int>?;

      print('\nTesting: "$text"');
      
      // MarianTokenizer behavior:
      // 1. SentencePiece encode
      // 2. Map tokens to vocab IDs
      // 3. Append EOS (0)
      
      final encoding = tokenizer.encode(text);
      
      // Manually map tokens to vocab IDs because the .spm indices might not match the vocab.json indices
      // (MarianMT often has a separate vocab file that doesn't align with the SPM binary indices)
      List<int> mappedIds = [];
      for (var token in encoding.tokens) {
        if (vocab.containsKey(token)) {
          mappedIds.add(vocab[token]);
        } else {
          print('  Warning: Token "$token" not found in vocab.json');
          // Fallback to SPM index or <unk>? 
          // MarianMT usually has all tokens in vocab.json.
          mappedIds.add(vocab['<unk>'] ?? 1);
        }
      }
      
      // Append EOS if not present
      if (mappedIds.isEmpty || mappedIds.last != 0) {
        mappedIds.add(0);
      }

      print('  Tokens: ${encoding.tokens}');
      print('  Result IDs: $mappedIds');
      
      if (expected != null) {
        print('  Expected:   $expected');
        bool match = true;
        if (mappedIds.length != expected.length) {
          match = false;
        } else {
          for (int i = 0; i < mappedIds.length; i++) {
            if (mappedIds[i] != expected[i]) {
              match = false;
              break;
            }
          }
        }
        
        if (match) {
          print('  ✓ MATCH');
        } else {
          print('  ✗ MISMATCH');
          allMatched = false;
        }
      } else {
        print('  (No reference IDs provided for comparison)');
      }
    }

    print('\n========================================');
    if (allMatched) {
      print('VALIDATION COMPLETE: SUCCESS');
    } else {
      print('VALIDATION COMPLETE: FAILED (ID MISMATCH)');
    }
    print('========================================');

  } catch (e, stackTrace) {
    print('Error during validation: $e');
    print(stackTrace);
  }
}
