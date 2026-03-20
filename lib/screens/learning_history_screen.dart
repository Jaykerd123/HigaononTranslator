import 'package:Higa/models/word.dart';
import 'package:Higa/screens/services/history_service.dart';
import 'package:Higa/screens/services/tts_service.dart';
import 'package:Higa/screens/services/bookmark_service.dart';
import 'package:Higa/screens/word_detail_screen.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.redAccent,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Learning History',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.redAccent, Colors.orangeAccent.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer<HistoryService>(
              builder: (context, historyService, child) {
                if (historyService.history.isEmpty) {
                  return _buildEmptyHistoryState(theme);
                } else {
                  return _buildHistoryHeader(historyService.history.length, theme);
                }
              },
            ),
          ),
          Consumer<HistoryService>(
            builder: (context, historyService, child) {
              if (historyService.history.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final word = historyService.history[index];
                      return _buildHistoryCard(word, theme, index);
                    },
                    childCount: historyService.history.length,
                  ),
                );
              }
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.history_edu_rounded,
            size: 64,
            color: theme.disabledColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No learning history yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start translating words to build your history',
            style: TextStyle(
              fontSize: 14,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.arrow_downward_rounded,
            size: 32,
            color: Colors.redAccent.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Translate tab to get started',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(int count, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            color: Colors.redAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Words Learned',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.redAccent.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$count words',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Recent',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Word word, ThemeData theme, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WordDetailScreen(word: word)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.higaonon,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.english,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          word.partOfSpeech,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Consumer<BookmarkService>(
                      builder: (context, bookmarkService, child) {
                        final isBookmarked = bookmarkService.isBookmarked(word);
                        return IconButton(
                          onPressed: () => bookmarkService.toggleBookmark(word),
                          icon: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            color: isBookmarked ? Colors.redAccent : Colors.grey,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isBookmarked 
                                ? Colors.redAccent.withOpacity(0.1) 
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () => _speak(word),
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

