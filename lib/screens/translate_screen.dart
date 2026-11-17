import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:Higa/models/word.dart';
import 'package:Higa/models/sentence_match.dart';
import 'package:Higa/models/user.dart';
import 'package:Higa/screens/services/history_service.dart';
import 'package:Higa/screens/services/tts_service.dart';
import 'package:Higa/screens/services/translation_stats_service.dart';
import 'package:Higa/screens/services/translation_fallback_service.dart';
import 'package:Higa/screens/services/onnx_translation_service.dart';
import 'package:Higa/screens/services/app_logger.dart';
import 'package:Higa/screens/gemini_assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:Higa/screens/word_detail_screen.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with AutomaticKeepAliveClientMixin {
  List<Word> _words = [];
  List<SentenceMatch> _sentenceMatches = [];
  List<Word> _filteredWords = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String _voiceTranslationResult = '';
  bool _voiceTranslationFound = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // State for Text Translation Mode
  bool _isVoiceMode = true; // True for Voice, False for Text
  final TextEditingController _textInputController = TextEditingController();
  String _textTranslationResult = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDictionary();
    _searchController.addListener(_onSearchChanged);
    _initSpeech();
    _loadTranslationHistory();
  }

  void _initSpeech() async {
    final status = await Permission.microphone.request();
    if (mounted) {
      if (status.isGranted) {
        _speechEnabled = await _speechToText.initialize(
          onStatus: (status) =>
              AppLogger.debug('SpeechToText', 'Status: $status'),
          onError: (_) =>
              AppLogger.error('SpeechToText', 'Recognition error occurred.'),
        );
      } else {
        _speechEnabled = false;
      }
      setState(() {});
    }
  }

  void _startListening() async {
    if (!_speechEnabled || _speechToText.isListening) return;

    // Check if sound effects are enabled
    final userData = Provider.of<UserData?>(context, listen: false);
    if (userData?.soundEffectsEnabled ?? false) {
      await _audioPlayer.play(AssetSource('sounds/mic_on.mp3'));
    }

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    setState(() {
      _lastWords = '';
      _voiceTranslationResult = 'Listening...';
      _voiceTranslationFound = false;
    });
  }

  void _stopListening() async {
    if (!_speechEnabled) return;
    await _audioPlayer.play(AssetSource('sounds/mic_off.mp3'));
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    setState(() {
      if (_lastWords.isEmpty && _voiceTranslationResult == 'Listening...') {
        _voiceTranslationResult = '';
        _voiceTranslationFound = false;
      }
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult) {
      _translateVoiceInput();
    }
  }

  String _normalizeString(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  Future<void> _loadTranslationHistory() async {
    if (!mounted) return;
    Provider.of<HistoryService>(
      context,
      listen: false,
    ).loadHistoryFromFirestore();
  }

  void _addTranslationToHistory(String sourceText, String translatedText) {
    final historyService = Provider.of<HistoryService>(context, listen: false);
    final word = Word(
      higaonon: translatedText,
      tagalog: '',
      partOfSpeech: '',
      english: sourceText,
      exampleHigaonon: '',
      exampleEnglish: '',
    );
    historyService.addWordToHistory(word);
  }

  Future<void> _translateVoiceInput() async {
    if (_lastWords.isNotEmpty) {
      final normalizedInput = _normalizeString(_lastWords);
      AppLogger.translationStarted(_lastWords);

      setState(() {
        _voiceTranslationResult = 'Translating...';
        _voiceTranslationFound = false;
      });

      // 1. Check dictionary.json (Words)
      for (var word in _words) {
        if (_normalizeString(word.english) == normalizedInput) {
          AppLogger.dictionaryMatch(
            word.higaonon,
            source: 'local dictionary (word)',
          );
          await Future.delayed(const Duration(seconds: 2));
          setState(() {
            _voiceTranslationResult = word.higaonon;
            _voiceTranslationFound = true;
          });
          _handleTranslationSuccess(word, _lastWords, word.higaonon);
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
            _voiceTranslationResult = word.exampleHigaonon;
            _voiceTranslationFound = true;
          });
          _handleTranslationSuccess(word, _lastWords, word.exampleHigaonon);
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
            _voiceTranslationResult = match.higaonon;
            _voiceTranslationFound = true;
          });
          final wordObj = Word(
            higaonon: match.higaonon,
            tagalog: '',
            partOfSpeech: '',
            english: match.english,
            exampleHigaonon: '',
            exampleEnglish: '',
          );
          _handleTranslationSuccess(wordObj, _lastWords, match.higaonon);
          return;
        }
      }

      // 4. Offline ONNX Model
      AppLogger.debug('TRANSLATION', 'No dictionary match.');
      AppLogger.debug('TRANSLATION', 'Running ONNX model...');
      try {
        final onnxTranslation = await OnnxTranslationService().translate(
          _lastWords,
        );
        if (mounted && onnxTranslation != null && onnxTranslation.isNotEmpty) {
          AppLogger.translationCompleted(onnxTranslation, 'ONNX model');
          setState(() {
            _voiceTranslationResult = onnxTranslation;
            _voiceTranslationFound = true;
          });
          final wordObj = Word(
            higaonon: onnxTranslation,
            tagalog: '',
            partOfSpeech: 'AI',
            english: _lastWords,
            exampleHigaonon: '',
            exampleEnglish: '',
          );
          _handleTranslationSuccess(wordObj, _lastWords, onnxTranslation);
          return;
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'TRANSLATION',
          'ONNX inference failed (${error.runtimeType}); continuing to fallback.',
          stackTrace: stackTrace,
        );
      }

      // 5. Fallback to AI Model
      AppLogger.debug('TRANSLATION', 'Using fallback service...');
      final fallbackTranslation =
          await TranslationFallbackService.translateEnglishToBisaya(_lastWords);
      if (fallbackTranslation != null && fallbackTranslation.isNotEmpty) {
        AppLogger.translationCompleted(fallbackTranslation, 'fallback service');
      } else {
        AppLogger.error('TRANSLATION', 'Fallback service returned no result.');
      }

      if (mounted) {
        setState(() {
          if (fallbackTranslation != null && fallbackTranslation.isNotEmpty) {
            _voiceTranslationResult = fallbackTranslation;
            _voiceTranslationFound = true;
            Provider.of<TtsService>(
              context,
              listen: false,
            ).speak(fallbackTranslation);
            unawaited(
              Provider.of<TranslationStatsService>(
                context,
                listen: false,
              ).recordTranslation(),
            );
            _addTranslationToHistory(_lastWords, fallbackTranslation);
          } else {
            _voiceTranslationResult = 'No translation found';
            _voiceTranslationFound = false;
          }
        });
      }
    }
  }

  void _handleTranslationSuccess(Word word, String source, String result) {
    if (mounted) {
      _addTranslationToHistory(source, result);
      Provider.of<HistoryService>(
        context,
        listen: false,
      ).addWordToHistory(word);
      Provider.of<TtsService>(context, listen: false).speak(result);
      unawaited(
        Provider.of<TranslationStatsService>(
          context,
          listen: false,
        ).recordTranslation(),
      );
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
          _words.sort((a, b) => a.higaonon.compareTo(b.higaonon));
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

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isSearching = true;
        _filteredWords = _words.where((word) {
          final query = _searchController.text.toLowerCase();
          return word.higaonon.toLowerCase().contains(query) ||
              word.tagalog.toLowerCase().contains(query) ||
              word.english.toLowerCase().contains(query);
        }).toList();
      });
    } else {
      setState(() {
        _isSearching = false;
      });
    }
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

  void _speak(Word word) {
    Provider.of<HistoryService>(context, listen: false).addWordToHistory(word);
    _speakWithLoading(word.higaonon);
  }

  Future<void> _translateText() async {
    // Hide the keyboard
    FocusScope.of(context).unfocus();

    final inputText = _textInputController.text;
    if (inputText.isEmpty) {
      setState(() {
        _textTranslationResult = 'Please enter text to translate.';
      });
      return;
    }

    setState(() {
      _textTranslationResult = 'Translating...';
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
          _textTranslationResult = word.higaonon;
        });
        _handleTranslationSuccess(word, inputText, word.higaonon);
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
          _textTranslationResult = word.exampleHigaonon;
        });
        _handleTranslationSuccess(word, inputText, word.exampleHigaonon);
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
          _textTranslationResult = match.higaonon;
        });
        final wordObj = Word(
          higaonon: match.higaonon,
          tagalog: '',
          partOfSpeech: '',
          english: match.english,
          exampleHigaonon: '',
          exampleEnglish: '',
        );
        _handleTranslationSuccess(wordObj, inputText, match.higaonon);
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
          _textTranslationResult = onnxTranslation;
        });
        final wordObj = Word(
          higaonon: onnxTranslation,
          tagalog: '',
          partOfSpeech: 'AI',
          english: inputText,
          exampleHigaonon: '',
          exampleEnglish: '',
        );
        _handleTranslationSuccess(wordObj, inputText, onnxTranslation);
        return;
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'TRANSLATION',
        'ONNX inference failed (${error.runtimeType}); continuing to fallback.',
        stackTrace: stackTrace,
      );
    }

    // 5. Fallback to AI Model
    AppLogger.debug('TRANSLATION', 'Using fallback service...');
    final fallbackTranslation =
        await TranslationFallbackService.translateEnglishToBisaya(inputText);
    if (fallbackTranslation != null && fallbackTranslation.isNotEmpty) {
      AppLogger.translationCompleted(fallbackTranslation, 'fallback service');
    } else {
      AppLogger.error('TRANSLATION', 'Fallback service returned no result.');
    }

    if (mounted) {
      setState(() {
        if (fallbackTranslation != null && fallbackTranslation.isNotEmpty) {
          _textTranslationResult = fallbackTranslation;
          Provider.of<TtsService>(
            context,
            listen: false,
          ).speak(fallbackTranslation);
          unawaited(
            Provider.of<TranslationStatsService>(
              context,
              listen: false,
            ).recordTranslation(),
          );
          _addTranslationToHistory(inputText, fallbackTranslation);
        } else {
          _textTranslationResult = 'No translation found for: "$inputText"';
        }
      });
    }
  }

  void _copyToClipboard() {
    if (_textTranslationResult.isNotEmpty &&
        !_textTranslationResult.startsWith('No translation found')) {
      Clipboard.setData(ClipboardData(text: _textTranslationResult));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation copied to clipboard!')),
      );
    }
  }

  @override
  void dispose() {
    // Dismiss keyboard and unfocus any focused text fields
    FocusScope.of(context).unfocus();
    _searchController.dispose();
    _textInputController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildAppBar(theme),
          _buildModeSelector(theme),
          Expanded(
            child: _isSearching
                ? _buildSearchResults(theme)
                : (_isVoiceMode
                      ? _buildVoiceTranslationBody(theme)
                      : _buildTextTranslationBody(theme)),
          ),
        ],
      ),
    );
  }

  void _showHistorySheet() {
    _loadTranslationHistory();
    final selectedHistoryIds = <String>{};
    var isSelectionMode = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 450),
        reverseDuration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<HistoryService>(
          builder: (context, historyService, child) {
            final historyItems = historyService.history;
            final allSelected =
                historyItems.isNotEmpty &&
                historyItems.every(
                  (item) => selectedHistoryIds.contains(item.higaonon),
                );

            return StatefulBuilder(
              builder: (context, setSheetState) {
                Future<void> deleteSelectedHistory() async {
                  if (selectedHistoryIds.isEmpty) return;
                  final count = selectedHistoryIds.length;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(
                        count == 1
                            ? 'Delete history item?'
                            : 'Delete $count history items?',
                      ),
                      content: const Text(
                        'This will permanently delete the selected history from your account.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;

                  try {
                    await historyService.deleteHistoryItems(selectedHistoryIds);
                    selectedHistoryIds.clear();
                  } catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Could not delete history: $error'),
                      ),
                    );
                  }
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Translation History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (isSelectionMode)
                            TextButton(
                              onPressed: () => setSheetState(() {
                                isSelectionMode = false;
                                selectedHistoryIds.clear();
                              }),
                              child: const Text('Cancel'),
                            )
                          else
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                        ],
                      ),
                      if (isSelectionMode && historyItems.isNotEmpty)
                        Row(
                          children: [
                            Checkbox(
                              value: allSelected,
                              onChanged: (selected) => setSheetState(() {
                                if (selected ?? false) {
                                  selectedHistoryIds.addAll(
                                    historyItems.map((item) => item.higaonon),
                                  );
                                } else {
                                  selectedHistoryIds.clear();
                                }
                              }),
                            ),
                            const Text('Select all'),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Delete selected history',
                              onPressed: selectedHistoryIds.isEmpty
                                  ? null
                                  : deleteSelectedHistory,
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      if (historyItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No translated voice or text history yet.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: historyItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = historyItems[index];
                              return GestureDetector(
                                onLongPress: () => setSheetState(() {
                                  isSelectionMode = true;
                                  selectedHistoryIds.add(item.higaonon);
                                }),
                                onTap: isSelectionMode
                                    ? () => setSheetState(() {
                                        if (!selectedHistoryIds.remove(
                                          item.higaonon,
                                        )) {
                                          selectedHistoryIds.add(item.higaonon);
                                        }
                                      })
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (isSelectionMode)
                                        Checkbox(
                                          value: selectedHistoryIds.contains(
                                            item.higaonon,
                                          ),
                                          onChanged: (selected) =>
                                              setSheetState(() {
                                                if (selected ?? false) {
                                                  selectedHistoryIds.add(
                                                    item.higaonon,
                                                  );
                                                } else {
                                                  selectedHistoryIds.remove(
                                                    item.higaonon,
                                                  );
                                                }
                                              }),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.higaonon.isNotEmpty
                                                  ? item.higaonon
                                                  : item.english,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.english.isNotEmpty
                                                  ? item.english
                                                  : item.higaonon,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () =>
                                            Provider.of<TtsService>(
                                              context,
                                              listen: false,
                                            ).speak(
                                              item.higaonon.isNotEmpty
                                                  ? item.higaonon
                                                  : item.english,
                                            ),
                                        icon: const Icon(
                                          Icons.volume_up_rounded,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Play translation',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Translator',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GeminiAssistantScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.auto_awesome,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                tooltip: 'Higaonon AI assistant',
              ),
              IconButton(
                onPressed: _showHistorySheet,
                icon: const Icon(
                  Icons.history_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
                tooltip: 'Translation history',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Quick dictionary search...',
              hintStyle: const TextStyle(fontSize: 16),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.redAccent,
              ),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildModeTab(
            'Voice',
            Icons.mic_rounded,
            _isVoiceMode,
            () => setState(() => _isVoiceMode = true),
            theme,
          ),
          const SizedBox(width: 12),
          _buildModeTab(
            'Text',
            Icons.text_fields_rounded,
            !_isVoiceMode,
            () => setState(() => _isVoiceMode = false),
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.redAccent : theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceTranslationBody(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        GestureDetector(
          onTap: _speechToText.isNotListening
              ? _startListening
              : _stopListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _speechToText.isListening
                  ? Colors.redAccent
                  : theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color:
                      (_speechToText.isListening
                              ? Colors.redAccent
                              : Colors.grey)
                          .withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              _speechToText.isNotListening
                  ? Icons.mic_rounded
                  : Icons.stop_rounded,
              color: _speechToText.isListening
                  ? Colors.white
                  : Colors.redAccent,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _speechToText.isListening ? 'Listening...' : 'Tap to Translate Voice',
          style: TextStyle(
            fontSize: 20,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        if (_lastWords.isNotEmpty || _voiceTranslationResult.isNotEmpty)
          _buildResultCard(
            theme,
            _lastWords,
            _voiceTranslationResult,
            _voiceTranslationFound,
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextTranslationBody(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textInputController,
                maxLines: null,
                onChanged: (value) {
                  if (_textTranslationResult.isNotEmpty) {
                    setState(() {
                      _textTranslationResult = '';
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Type English sentence here...',
                  hintStyle: TextStyle(
                    fontSize: 18,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _translateText,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
            ),
            child: const Text(
              'Translate',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          if (_textTranslationResult.isNotEmpty)
            _buildResultCard(
              theme,
              _textInputController.text,
              _textTranslationResult,
              !_textTranslationResult.startsWith('No translation found') &&
                  !_textTranslationResult.startsWith('Please enter'),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    ThemeData theme,
    String source,
    String result,
    bool showSpeaker,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source,
            style: TextStyle(color: theme.disabledColor, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  result,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              if (showSpeaker)
                IconButton(
                  icon: _currentlySpeakingText == result
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                      : const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.redAccent,
                        ),
                  onPressed: _currentlySpeakingText != null
                      ? null
                      : () => _speakWithLoading(result),
                ),
              if (showSpeaker)
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: _copyToClipboard,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredWords.length,
      itemBuilder: (context, index) {
        final word = _filteredWords[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            title: Text(
              word.higaonon,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(word.english),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WordDetailScreen(word: word),
                ),
              );
            },
            trailing: IconButton(
              icon: _currentlySpeakingText == word.higaonon
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.redAccent,
                      ),
                    )
                  : const Icon(
                      Icons.volume_up_rounded,
                      color: Colors.redAccent,
                    ),
              onPressed: _currentlySpeakingText != null
                  ? null
                  : () => _speak(word),
            ),
          ),
        );
      },
    );
  }
}
