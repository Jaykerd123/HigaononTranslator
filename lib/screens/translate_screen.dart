import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:fireb/models/word.dart';
import 'package:fireb/screens/services/history_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  List<Word> _words = [];
  List<Word> _filteredWords = [];
  final TextEditingController _searchController = TextEditingController();
  late FlutterTts _flutterTts;
  bool _isSearching = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String _translationResult = '';
  bool _translationFound = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadDictionary();
    _searchController.addListener(_onSearchChanged);
    _initSpeech();
  }

  void _initSpeech() async {
    final status = await Permission.microphone.request();
    if (mounted) {
      if (status.isGranted) {
        _speechEnabled = await _speechToText.initialize(
          onStatus: (status) => print('[SpeechToText] Status: $status'),
          onError: (error) => print('[SpeechToText] Error: $error'),
        );
      } else {
        _speechEnabled = false;
      }
      setState(() {});
    }
  }

  void _startListening() async {
    if (!_speechEnabled || _speechToText.isListening) return;
    await _audioPlayer.play(AssetSource('sounds/mic_on.mp3'));
    print("--- Start Listening ---");
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    setState(() {
      _lastWords = '';
      _translationResult = 'Listening...';
      _translationFound = false;
    });
  }

  void _stopListening() async {
    if (!_speechEnabled) return;
    await _audioPlayer.play(AssetSource('sounds/mic_off.mp3'));
    print("--- Stop Listening (Manual) ---");
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    setState(() {
      if (_lastWords.isEmpty && _translationResult == 'Listening...') {
        _translationResult = '';
        _translationFound = false;
      }
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    print("[SpeechToText] Result: ${result.recognizedWords}, Final: ${result.finalResult}");
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult) {
      print("[SpeechToText] Final result received. Translating.");
      _translateVoiceInput();
    }
  }

  String _normalizeString(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  void _translateVoiceInput() {
    print("--- Translating Voice Input: '$_lastWords' ---");
    if (_lastWords.isNotEmpty) {
      final normalizedLastWords = _normalizeString(_lastWords);
      final foundSentence = _words.firstWhere(
        (word) => _normalizeString(word.exampleEnglish) == normalizedLastWords,
        orElse: () => Word(
            higaonon: '',
            english: '',
            tagalog: '',
            partOfSpeech: '',
            exampleHigaonon: 'No translation found for sentence',
            exampleEnglish: ''),
      );
      print("Translation result: ${foundSentence.exampleHigaonon}");
      setState(() {
        _translationResult = foundSentence.exampleHigaonon;
        _translationFound = foundSentence.higaonon.isNotEmpty;
      });

      if (foundSentence.higaonon.isNotEmpty) {
        Provider.of<HistoryService>(context, listen: false).addWordToHistory(foundSentence);
        _flutterTts.speak(foundSentence.exampleHigaonon);
      }
    } else {
      print("No voice input to translate.");
      setState(() {
        _translationResult = 'Please speak something.';
        _translationFound = false;
      });
    }
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
  }

  Future<void> _loadDictionary() async {
    final String response = await rootBundle.loadString('assets/dictionary.json');
    final data = await json.decode(response) as List;
    if (mounted) {
      setState(() {
        _words = data.map((word) => Word.fromJson(word)).toList();
        _words.sort((a, b) => a.higaonon.compareTo(b.higaonon));
      });
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

  void _speak(Word word) async {
    Provider.of<HistoryService>(context, listen: false).addWordToHistory(word);
    await _flutterTts.speak(word.higaonon);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search dictionary...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildTranslationBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 70), // Placeholder for the waveform
          GestureDetector(
            onTap: _speechToText.isNotListening ? _startListening : _stopListening,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.red,
              child: Icon(
                _speechToText.isNotListening ? Icons.mic : Icons.stop,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _speechToText.isListening
                ? 'Listening...'
                : _speechEnabled
                    ? 'Tap the microphone to start listening...'
                    : 'Speech not available',
            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (_lastWords.isNotEmpty || _translationResult.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Recognized (English):', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_lastWords.isNotEmpty ? _lastWords : 'Speak something...'),
                    const SizedBox(height: 10),
                    const Text('Translation (Higaonon):', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(_translationResult),
                        ),
                        if (_translationFound)
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () =>
                                _flutterTts.speak(_translationResult),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _filteredWords.length,
      itemBuilder: (context, index) {
        final word = _filteredWords[index];
        return _buildWordCard(word);
      },
    );
  }

  Widget _buildWordCard(Word word) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    word.higaonon,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.volume_up, color: theme.colorScheme.secondary, size: 30),
                  onPressed: () => _speak(word),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${word.partOfSpeech} • ${word.tagalog}',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: theme.textTheme.bodySmall?.color),
            ),
            const Divider(height: 24),
            _buildTranslationSection(
              language: 'English',
              definition: word.english,
              example: word.exampleEnglish,
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildTranslationSection(
              language: 'Higaonon Example',
              definition: word.exampleHigaonon,
              example: '',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationSection({
    required String language,
    required String definition,
    required String example,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            definition,
            style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
          ),
        ),
        if (example.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4),
            child: Text(
              '“$example”',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: theme.textTheme.bodySmall?.color),
            ),
          ),
      ],
    );
  }
}
