import 'dart:async';
import 'dart:convert';
import 'package:Higa/models/word.dart';
import 'package:Higa/models/sentence_match.dart';
import 'package:Higa/screens/services/history_service.dart';
import 'package:Higa/screens/services/translation_stats_service.dart';
import 'package:Higa/screens/services/tts_service.dart';
import 'package:Higa/screens/services/translation_fallback_service.dart';
import 'package:Higa/screens/services/onnx_translation_service.dart';
import 'package:Higa/screens/services/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class TextTranslateScreen extends StatefulWidget {
  const TextTranslateScreen({super.key});

  @override
  State<TextTranslateScreen> createState() => _TextTranslateScreenState();
}

class _TextTranslateScreenState extends State<TextTranslateScreen> {
  final TextEditingController _textInputController = TextEditingController();
  String _translationResult = '';
  List<Word> _words = [];
  List<SentenceMatch> _sentenceMatches = [];

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  String? _currentlySpeakingText;

  Future<void> _speakWithLoading(String text) async {
    if (_currentlySpeakingText != null) return;
    setState(() {
      _currentlySpeakingText = text;
    });
    try {
      await Provider.of<TtsService>(context, listen: false).speak(text);
    } finally {
      if (mounted) {
        setState(() {
          _currentlySpeakingText = null;
        });
      }
    }
  }

  Future<void> _loadDictionary() async {
    // Load dictionary.json
    try {
      final String response = await rootBundle.loadString(
        'assets/dictionary.json',
      );
      final data = await json.decode(response) as List;
      if (mounted) {
        setState(() {
          _words = data.map((word) => Word.fromJson(word)).toList();
        });
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'TRANSLATION',
        'Could not load dictionary.json (${error.runtimeType}).',
        stackTrace: stackTrace,
      );
    }

    // Load dictionary-second.json
    try {
      final String secondResponse = await rootBundle.loadString(
        'assets/dictionary-second.json',
      );
      final secondData = await json.decode(secondResponse) as List;
      if (mounted) {
        setState(() {
          _sentenceMatches = secondData
              .map((s) => SentenceMatch.fromJson(s))
              .toList();
        });
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'TRANSLATION',
        'Could not load dictionary-second.json (${error.runtimeType}).',
        stackTrace: stackTrace,
      );
    }
  }

  String _normalizeString(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  void _recordTranslation() {
    unawaited(
      Provider.of<TranslationStatsService>(
        context,
        listen: false,
      ).recordTranslation(),
    );
  }

  Future<void> _translateText() async {
    // Hide the keyboard
    FocusScope.of(context).unfocus();

    final inputText = _textInputController.text;
    if (inputText.isEmpty) {
      setState(() {
        _translationResult = 'Please enter text to translate.';
      });
      return;
    }

    setState(() {
      _translationResult = 'Translating...';
    });

    final normalizedInput = _normalizeString(inputText);
    AppLogger.translationStarted(inputText);

    // 1. Check dictionary.json (Words)
    for (var word in _words) {
      if (_normalizeString(word.english) == normalizedInput) {
        AppLogger.dictionaryMatch(
          word.higaonon,
          source: 'local dictionary (word)',
        );
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _translationResult = word.higaonon;
          Provider.of<HistoryService>(
            context,
            listen: false,
          ).addWordToHistory(word);
          Provider.of<TtsService>(context, listen: false).speak(word.higaonon);
        });
        _recordTranslation();
        return;
      }
    }

    // 2. Check dictionary.json (Sentences)
    for (var word in _words) {
      if (_normalizeString(word.exampleEnglish) == normalizedInput) {
        AppLogger.dictionaryMatch(
          word.exampleHigaonon,
          source: 'local dictionary (example sentence)',
        );
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _translationResult = word.exampleHigaonon;
          Provider.of<HistoryService>(
            context,
            listen: false,
          ).addWordToHistory(word);
          Provider.of<TtsService>(
            context,
            listen: false,
          ).speak(word.exampleHigaonon);
        });
        _recordTranslation();
        return;
      }
    }

    // 3. Check dictionary-second.json
    for (var match in _sentenceMatches) {
      if (_normalizeString(match.english) == normalizedInput) {
        AppLogger.dictionaryMatch(
          match.higaonon,
          source: 'local dictionary (phrase list)',
        );
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _translationResult = match.higaonon;
          final wordObj = Word(
            higaonon: match.higaonon,
            tagalog: '',
            partOfSpeech: '',
            english: match.english,
            exampleHigaonon: '',
            exampleEnglish: '',
          );
          Provider.of<HistoryService>(
            context,
            listen: false,
          ).addWordToHistory(wordObj);
          Provider.of<TtsService>(context, listen: false).speak(match.higaonon);
        });
        _recordTranslation();
        return;
      }
    }

    // 4. Offline ONNX Model
    AppLogger.debug('TRANSLATION', 'No dictionary match.');
    AppLogger.debug('TRANSLATION', 'Running ONNX model...');
    try {
      final onnxTranslation = await OnnxTranslationService().translate(
        inputText,
      );
      if (mounted && onnxTranslation != null && onnxTranslation.isNotEmpty) {
        AppLogger.translationCompleted(onnxTranslation, 'ONNX model');
        setState(() {
          _translationResult = onnxTranslation;
          Provider.of<TtsService>(
            context,
            listen: false,
          ).speak(onnxTranslation);
        });
        // Add to history (create a dummy Word object for compatibility)
        final wordObj = Word(
          higaonon: onnxTranslation,
          tagalog: '',
          partOfSpeech: 'AI',
          english: inputText,
          exampleHigaonon: '',
          exampleEnglish: '',
        );
        Provider.of<HistoryService>(
          context,
          listen: false,
        ).addWordToHistory(wordObj);
        _recordTranslation();
        return;
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'TRANSLATION',
        'ONNX inference failed (${error.runtimeType}); continuing to fallback.',
        stackTrace: stackTrace,
      );
      // Continue to fallback
    }

    // 5. Fallback to AI Model (Network)
    AppLogger.debug('TRANSLATION', 'Using fallback service...');
    final fallbackTranslation =
        await TranslationFallbackService.translateEnglishToBisaya(inputText);
    if (fallbackTranslation != null && fallbackTranslation.isNotEmpty) {
      AppLogger.translationCompleted(fallbackTranslation, 'fallback service');
    } else {
      AppLogger.error('TRANSLATION', 'Fallback service returned no result.');
    }

    if (mounted) {
      if (fallbackTranslation != null && fallbackTranslation.isNotEmpty) {
        _recordTranslation();
      }
      setState(() {
        if (fallbackTranslation != null && fallbackTranslation.isNotEmpty) {
          _translationResult = fallbackTranslation;
          Provider.of<TtsService>(
            context,
            listen: false,
          ).speak(fallbackTranslation);
        } else {
          _translationResult = 'No translation found for: "$inputText"';
        }
      });
    }
  }

  void _copyToClipboard() {
    if (_translationResult.isNotEmpty &&
        !_translationResult.startsWith('No translation found') &&
        _translationResult != 'Please enter text to translate.') {
      Clipboard.setData(ClipboardData(text: _translationResult));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation copied to clipboard!')),
      );
    }
  }

  @override
  void dispose() {
    _textInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Text Translate')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _textInputController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (value) {
                  if (_translationResult.isNotEmpty) {
                    setState(() {
                      _translationResult = '';
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Enter text to translate...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: theme.colorScheme.secondary,
                      width: 2.0,
                    ),
                  ),
                  alignLabelWithHint: true,
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _translateText,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Translate',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Translation (Higaonon):',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _translationResult.isEmpty
                            ? 'Your translation will appear here.'
                            : _translationResult,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (_translationResult.isNotEmpty &&
                        !_translationResult.startsWith(
                          'No translation found',
                        ) &&
                        _translationResult != 'Please enter text to translate.')
                      IconButton(
                        icon: _currentlySpeakingText == _translationResult
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.secondary,
                                ),
                              )
                            : Icon(
                                Icons.volume_up,
                                color: theme.colorScheme.secondary,
                              ),
                        onPressed: _currentlySpeakingText != null
                            ? null
                            : () => _speakWithLoading(_translationResult),
                      ),
                    if (_translationResult.isNotEmpty &&
                        _translationResult !=
                            'No translation found for sentence' &&
                        _translationResult !=
                            'No translation found for: "${_textInputController.text}"' &&
                        _translationResult != 'Please enter text to translate.')
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: _copyToClipboard,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
