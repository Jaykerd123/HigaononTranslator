import 'package:Higa/models/word.dart';
import 'package:Higa/screens/services/history_service.dart';
import 'package:Higa/screens/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({super.key});

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load history when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryService>(context, listen: false).loadHistoryFromFirestore();
    });
  }

  void _speak(Word word) {
    Provider.of<HistoryService>(context, listen: false).addWordToHistory(word);
    Provider.of<TtsService>(context, listen: false).speak(word.higaonon);
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

