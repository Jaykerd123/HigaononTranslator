import 'package:fireb/models/word.dart';
import 'package:fireb/screens/services/history_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LearningHistoryScreen extends StatelessWidget {
  const LearningHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyService = Provider.of<HistoryService>(context);
    final history = historyService.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning History'),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text('Your learning history is empty.'),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final word = history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(word.higaonon, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(word.english),
                    // You can add more details or actions here if you want
                  ),
                );
              },
            ),
    );
  }
}
