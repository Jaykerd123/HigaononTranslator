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

class _TranslateScreenState extends State<TranslateScreen> with AutomaticKeepAliveClientMixin {
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
  bool get wantKeepAlive => true;

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

  void _translateVoiceInput() {
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
      setState(() {
        _voiceTranslationResult = foundSentence.exampleHigaonon;
        _voiceTranslationFound = foundSentence.higaonon.isNotEmpty;
      });

      if (foundSentence.higaonon.isNotEmpty) {
        Provider.of<HistoryService>(context, listen: false).addWordToHistory(foundSentence);
        _flutterTts.speak(foundSentence.exampleHigaonon);
      }
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
    if (_textTranslationResult.isNotEmpty) {
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
                : (_isVoiceMode ? _buildVoiceTranslationBody(theme) : _buildTextTranslationBody(theme)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Translator',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Quick dictionary search...',
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.redAccent),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
          _buildModeTab('Voice', Icons.mic_rounded, _isVoiceMode, () => setState(() => _isVoiceMode = true), theme),
          const SizedBox(width: 12),
          _buildModeTab('Text', Icons.text_fields_rounded, !_isVoiceMode, () => setState(() => _isVoiceMode = false), theme),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, IconData icon, bool isActive, VoidCallback onTap, ThemeData theme) {
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
            boxShadow: isActive ? [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
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
          onTap: _speechToText.isNotListening ? _startListening : _stopListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _speechToText.isListening ? Colors.redAccent : theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: (_speechToText.isListening ? Colors.redAccent : Colors.grey).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              _speechToText.isNotListening ? Icons.mic_rounded : Icons.stop_rounded,
              color: _speechToText.isListening ? Colors.white : Colors.redAccent,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _speechToText.isListening ? 'Listening...' : 'Tap to Translate Voice',
          style: TextStyle(fontSize: 18, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        ),
        const Spacer(),
        if (_lastWords.isNotEmpty || _voiceTranslationResult.isNotEmpty)
          _buildResultCard(theme, _lastWords, _voiceTranslationResult, _voiceTranslationFound),
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
                decoration: const InputDecoration(
                  hintText: 'Type English sentence here...',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 5,
            ),
            child: const Text('Translate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          if (_textTranslationResult.isNotEmpty)
             _buildResultCard(theme, _textInputController.text, _textTranslationResult, true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, String source, String result, bool showSpeaker) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(source, style: TextStyle(color: theme.disabledColor, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  result,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
              if (showSpeaker)
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: Colors.redAccent),
                  onPressed: () => _flutterTts.speak(result),
                ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.grey, size: 20),
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
            title: Text(word.higaonon, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(word.english),
            trailing: IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: Colors.redAccent),
              onPressed: () => _speak(word),
            ),
          ),
        );
      },
    );
  }
}
