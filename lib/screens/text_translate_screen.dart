import 'dart:convert';
import 'package:fireb/models/word.dart';
import 'package:fireb/screens/services/history_service.dart';
import 'package:fireb/screens/services/tts_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    final String response = await rootBundle.loadString('assets/dictionary.json');
    final data = await json.decode(response) as List;
    if (mounted) {
      setState(() {
        _words = data.map((word) => Word.fromJson(word)).toList();
      });
    }
  }

  String _normalizeString(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  void _translateText() {
    // Hide the keyboard
    FocusScope.of(context).unfocus();

    final inputText = _textInputController.text;
    if (inputText.isEmpty) {
      setState(() {
        _translationResult = 'Please enter text to translate.';
      });
      return;
    }

    final normalizedInput = _normalizeString(inputText);

<<<<<<< HEAD
    final foundWord = _words.firstWhere(
      (word) => _normalizeString(word.english) == normalizedInput ||
                _normalizeString(word.exampleEnglish) == normalizedInput,
      orElse: () => Word(
          higaonon: '',
          english: '',
          tagalog: '',
          partOfSpeech: '',
          exampleHigaonon: 'No direct translation found',
          exampleEnglish: ''),
    );

    setState(() {
      if (foundWord.higaonon.isNotEmpty) {
        _translationResult = foundWord.higaonon;
        Provider.of<HistoryService>(context, listen: false).addWordToHistory(foundWord);
        Provider.of<TtsService>(context, listen: false).speak(foundWord.higaonon);
      } else {
        final foundSentence = _words.firstWhere(
            (word) => _normalizeString(word.exampleEnglish) == normalizedInput,
            orElse: () => Word(
                higaonon: '',
                english: '',
                tagalog: '',
                partOfSpeech: '',
                exampleHigaonon: 'No translation found for sentence',
                exampleEnglish: '')
        );
        if (foundSentence.higaonon.isNotEmpty) {
           _translationResult = foundSentence.higaonon;
           Provider.of<HistoryService>(context, listen: false).addWordToHistory(foundSentence);
           Provider.of<TtsService>(context, listen: false).speak(foundSentence.higaonon);
        } else {
          _translationResult = 'No translation found for: "$inputText"';
        }
      }
=======
    // 1. Try to find a direct word match first
    try {
      final wordMatch = _words.firstWhere(
        (word) => _normalizeString(word.english) == normalizedInput,
      );
      setState(() {
        _translationResult = wordMatch.higaonon;
        Provider.of<HistoryService>(context, listen: false).addWordToHistory(wordMatch);
        _flutterTts.speak(wordMatch.higaonon);
      });
      return;
    } catch (e) {
      // Word match not found, continue to sentence match
    }

    // 2. Try to find a sentence match
    try {
      final sentenceMatch = _words.firstWhere(
        (word) => _normalizeString(word.exampleEnglish) == normalizedInput,
      );
      setState(() {
        _translationResult = sentenceMatch.exampleHigaonon;
        Provider.of<HistoryService>(context, listen: false).addWordToHistory(sentenceMatch);
        _flutterTts.speak(sentenceMatch.exampleHigaonon);
      });
      return;
    } catch (e) {
      // Sentence match not found
    }

    setState(() {
      _translationResult = 'No translation found for: "$inputText"';
>>>>>>> cb23a018c2822c08a4784565bb3cf6ff843dff81
    });
  }

  void _copyToClipboard() {
    if (_translationResult.isNotEmpty && !_translationResult.startsWith('No translation found') && _translationResult != 'Please enter text to translate.') {
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
      appBar: AppBar(
        title: const Text('Text Translate'),
      ),
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
                decoration: InputDecoration(
                  hintText: 'Enter text to translate...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2.0),
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
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Translation (Higaonon):',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _translationResult.isEmpty ? 'Your translation will appear here.' : _translationResult,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (_translationResult.isNotEmpty && !_translationResult.startsWith('No translation found') && _translationResult != 'Please enter text to translate.')
                      IconButton(
                        icon: Icon(Icons.volume_up, color: theme.colorScheme.secondary),
                        onPressed: () => Provider.of<TtsService>(context, listen: false).speak(_translationResult),
                      ),
                    if (_translationResult.isNotEmpty && _translationResult != 'No translation found for sentence' && _translationResult != 'No translation found for: "${_textInputController.text}"' && _translationResult != 'Please enter text to translate.')
                      IconButton(
                        icon: Icon(Icons.copy, color: theme.colorScheme.secondary),
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
