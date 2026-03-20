import 'package:Higa/screens/services/history_service.dart';
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
    // Use a post-frame callback to ensure that the provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryService>(context, listen: false).loadHistoryFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<HistoryService>(
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
                const ProgressCard(
                  icon: Icons.local_fire_department,
                  value: '0',
                  label: 'Day Streak',
                ),
                const ProgressCard(
                  icon: Icons.translate,
                  value: '0',
                  label: 'Translations',
                ),
                const ProgressCard(
                  icon: Icons.timer,
                  value: '0h',
                  label: 'Time Spent',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

