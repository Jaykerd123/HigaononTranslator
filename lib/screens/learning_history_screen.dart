import 'dart:math';

import 'package:fireb/models/word.dart';
import 'package:fireb/screens/services/history_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({super.key});

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen> {
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
  }

  void _speak(Word word) async {
    Provider.of<HistoryService>(context, listen: false).addWordToHistory(word);
    await _flutterTts.speak(word.higaonon);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning History'),
      ),
      body: Consumer<HistoryService>(
        builder: (context, historyService, child) {
          if (historyService.history.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Your browsing history will appear here.',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: historyService.history.length,
              itemBuilder: (context, index) {
                final word = historyService.history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(word.higaonon, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(word.english),
                    trailing: IconButton(
                      icon: const Icon(Icons.volume_up, size: 22),
                      onPressed: () => _speak(word),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
