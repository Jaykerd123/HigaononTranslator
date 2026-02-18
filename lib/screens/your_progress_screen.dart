
import 'package:flutter/material.dart';
import '../widgets/progress_card.dart';

class YourProgressScreen extends StatelessWidget {
  const YourProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: const [
            ProgressCard(
              icon: Icons.book,
              value: '0',
              label: 'Words Learned',
            ),
            ProgressCard(
              icon: Icons.local_fire_department,
              value: '0',
              label: 'Day Streak',
            ),
            ProgressCard(
              icon: Icons.translate,
              value: '0',
              label: 'Translations',
            ),
            ProgressCard(
              icon: Icons.timer,
              value: '0h',
              label: 'Time Spent',
            ),
          ],
        ),
      ),
    );
  }
}
