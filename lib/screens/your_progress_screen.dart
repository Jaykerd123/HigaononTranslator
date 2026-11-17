import 'package:Higa/screens/services/history_service.dart';
import 'package:Higa/screens/services/translation_stats_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/progress_card.dart';

class YourProgressScreen extends StatefulWidget {
  const YourProgressScreen({super.key});

  @override
  State<YourProgressScreen> createState() => _YourProgressScreenState();
}

class _YourProgressScreenState extends State<YourProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure that provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryService>(
        context,
        listen: false,
      ).loadHistoryFromFirestore();
    });
  }

  String _formatTimeSpent(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '${duration.inMinutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<TranslationStatsService>(
          builder: (context, translationStatsService, child) {
            return Consumer<HistoryService>(
              builder: (context, historyService, child) {
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    ProgressCard(
                      icon: Icons.book,
                      value: historyService.history.length.toString(),
                      label: 'Words Learned',
                    ),
                    ProgressCard(
                      icon: Icons.local_fire_department,
                      value: translationStatsService.dayStreak.toString(),
                      label: 'Day Streak',
                    ),
                    ProgressCard(
                      icon: Icons.translate,
                      value: translationStatsService.translationCount
                          .toString(),
                      label: 'Translations',
                    ),
                    ProgressCard(
                      icon: Icons.timer,
                      value: _formatTimeSpent(
                        translationStatsService.timeSpentSeconds,
                      ),
                      label: 'Time Spent',
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
