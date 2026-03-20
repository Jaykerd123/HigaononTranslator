import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Higa/models/word.dart';
import 'package:Higa/screens/services/bookmark_service.dart';
import 'package:Higa/screens/services/history_service.dart';
import 'package:Higa/screens/services/tts_service.dart';

class WordDetailScreen extends StatelessWidget {
  final Word word;

  const WordDetailScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.redAccent,
            actions: [
              Consumer<BookmarkService>(
                builder: (context, bookmarkService, child) {
                  final isBookmarked = bookmarkService.isBookmarked(word);
                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => bookmarkService.toggleBookmark(word),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                word.higaonon,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent,
                      Colors.orangeAccent.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        word.english,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          word.partOfSpeech,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'Tagalog Translation',
                    content: word.tagalog,
                    icon: Icons.translate_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Example in Higaonon',
                    content: word.exampleHigaonon,
                    icon: Icons.format_quote_rounded,
                    theme: theme,
                    isExample: true,
                    exampleLanguage: 'Higaonon',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Example in English',
                    content: word.exampleEnglish,
                    icon: Icons.format_quote_rounded,
                    theme: theme,
                    isExample: true,
                    exampleLanguage: 'English',
                  ),
                  const SizedBox(height: 30),
                  _buildActionButtons(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    required IconData icon,
    required ThemeData theme,
    bool isExample = false,
    String? exampleLanguage,
  }) {
    return Container(
      width: double.infinity,
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.redAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (isExample && exampleLanguage != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      exampleLanguage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Provider.of<HistoryService>(context, listen: false).addWordToHistory(word);
              Provider.of<TtsService>(context, listen: false).speak(word.higaonon);
            },
            icon: const Icon(Icons.volume_up_rounded, size: 24),
            label: const Text(
              'Pronounce Word',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 24),
            label: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
