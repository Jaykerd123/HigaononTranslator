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
  String _voiceTranslationResult = '';
  bool _voiceTranslationFound = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // State for Text Translation Mode
  bool _isVoiceMode = true; // True for Voice, False for Text
  final TextEditingController _textInputController = TextEditingController();
  String _textTranslationResult = '';

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
      _voiceTranslationResult = 'Listening...';
      _voiceTranslationFound = false;
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
      if (_lastWords.isEmpty && _voiceTranslationResult == 'Listening...') {
        _voiceTranslationResult = '';
        _voiceTranslationFound = false;
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
        _voiceTranslationResult = foundSentence.exampleHigaonon;
        _voiceTranslationFound = foundSentence.higaonon.isNotEmpty;
      });

      if (foundSentence.higaonon.isNotEmpty) {
        Provider.of<HistoryService>(context, listen: false).addWordToHistory(foundSentence);
        _flutterTts.speak(foundSentence.exampleHigaonon);
      }
    } else {
      print("No voice input to translate.");
      setState(() {
        _voiceTranslationResult = 'Please speak something.';
        _voiceTranslationFound = false;
      });
    }
  }

  void _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("ceb-PH");
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

  // Text Translation Methods
  void _translateText() {
    final inputText = _textInputController.text;
    if (inputText.isEmpty) {
      setState(() {
        _textTranslationResult = 'Please enter text to translate.';
      });
      return;
    }

    final normalizedInput = _normalizeString(inputText);

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
        _textTranslationResult = foundWord.higaonon;
        Provider.of<HistoryService>(context, listen: false).addWordToHistory(foundWord);
        _flutterTts.speak(foundWord.higaonon);
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
           _textTranslationResult = foundSentence.higaonon;
           Provider.of<HistoryService>(context, listen: false).addWordToHistory(foundSentence);
           _flutterTts.speak(foundSentence.higaonon);
        } else {
          _textTranslationResult = 'No translation found for: "$inputText"';
        }
      }
    });
  }

  void _copyToClipboard() {
    if (_textTranslationResult.isNotEmpty && 
        _textTranslationResult != 'No translation found for sentence' && 
        _textTranslationResult != 'No translation found for: "${_textInputController.text}"' && 
        _textTranslationResult != 'Please enter text to translate.') {
      Clipboard.setData(ClipboardData(text: _textTranslationResult));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation copied to clipboard!')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _textInputController.dispose();
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
            child: _isSearching ? _buildSearchResults() : (_isVoiceMode ? _buildVoiceTranslationBody() : _buildTextTranslationBody()),
          ),
        ],
      ),
      floatingActionButton: _isSearching ? null : _buildModeToggleButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildModeToggleButton() {
    final theme = Theme.of(context);
    return SizedBox(
      width: 60.0, // Smaller size for the button
      height: 60.0, // Smaller size for the button
      child: FloatingActionButton(
        backgroundColor: theme.colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
        onPressed: () {
          setState(() {
            _isVoiceMode = !_isVoiceMode;
            // Clear results when switching modes
            _lastWords = '';
            _voiceTranslationResult = '';
            _voiceTranslationFound = false;
            _textInputController.clear();
            _textTranslationResult = '';
          });
        },
        child: Icon(
          _isVoiceMode ? Icons.text_fields : Icons.mic, // Icon changes based on mode
          color: Colors.white,
          size: 30, // Smaller icon size
        ),
      ),
    );
  }

  Widget _buildVoiceTranslationBody() {
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
              backgroundColor: Theme.of(context).colorScheme.primary, // Using theme color
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
          if (_lastWords.isNotEmpty || _voiceTranslationResult.isNotEmpty)
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
                          child: Text(_voiceTranslationResult),
                        ),
                        if (_voiceTranslationFound)
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () =>
                                _flutterTts.speak(_voiceTranslationResult),
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

  Widget _buildTextTranslationBody() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: _textInputController,
              maxLines: null, // Allows multiple lines
              expands: true, // Makes the TextField take available height
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
                      _textTranslationResult.isEmpty ? 'Your translation will appear here.' : _textTranslationResult,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  if (_textTranslationResult.isNotEmpty && 
                      _textTranslationResult != 'No translation found for sentence' && 
                      _textTranslationResult != 'No translation found for: "${_textInputController.text}"' && 
                      _textTranslationResult != 'Please enter text to translate.')
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