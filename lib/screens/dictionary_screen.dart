import 'dart:convert';
import 'package:Higa/models/word.dart';
import 'package:Higa/screens/services/history_service.dart';
import 'package:Higa/screens/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  List<Word> _words = [];
  List<Word> _filteredWords = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDictionary();
    _searchController.addListener(_filterWords);
  }

  Future<void> _loadDictionary() async {
    final String response = await rootBundle.loadString('assets/dictionary.json');
    final data = await json.decode(response) as List;
    setState(() {
      _words = data.map((word) => Word.fromJson(word)).toList();
      _words.sort((a, b) => a.higaonon.compareTo(b.higaonon));
      _filteredWords = _words;
    });
  }

  void _speak(Word word) {
    Provider.of<HistoryService>(context, listen: false).addWordToHistory(word);
    Provider.of<TtsService>(context, listen: false).speak(word.higaonon);
  }

  void _filterWords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWords = _words.where((word) {
        return word.higaonon.toLowerCase().contains(query) ||
               word.tagalog.toLowerCase().contains(query) ||
               word.english.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredWords.length,
              itemBuilder: (context, index) {
                final word = _filteredWords[index];
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
                            Text(
                              word.higaonon,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: Colors.blueAccent),
                              onPressed: () => _speak(word),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${word.partOfSpeech} • ${word.tagalog}',
                          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                        const Divider(height: 24),
                        _buildTranslationSection(
                          language: 'English',
                          definition: word.english,
                          example: word.exampleEnglish,
                        ),
                        const SizedBox(height: 16),
                        _buildTranslationSection(
                          language: 'Higaonon Example',
                          definition: word.exampleHigaonon,
                          example: '',
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
  }
}

Widget _buildTranslationSection({
  required String language,
  required String definition,
  required String example,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        language,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
          definition,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      if (example.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 4),
          child: Text(
            example,
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
    ],
  );
}

