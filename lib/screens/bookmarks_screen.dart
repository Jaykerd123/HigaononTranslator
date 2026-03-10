import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fireb/screens/services/bookmark_service.dart';
import 'package:fireb/screens/services/tts_service.dart';
import 'package:fireb/models/word.dart';

class BookmarkedWordsScreen extends StatelessWidget {
  const BookmarkedWordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarked Words'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<BookmarkService>(
        builder: (context, bookmarkService, child) {
          if (bookmarkService.bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline_rounded,
                    size: 80,
                    color: theme.disabledColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarked words yet.',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.disabledColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarkService.bookmarks.length,
            itemBuilder: (context, index) {
              final word = bookmarkService.bookmarks[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    word.higaonon,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(word.english),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bookmark_rounded, color: Colors.redAccent),
                        onPressed: () => bookmarkService.toggleBookmark(word),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 18, color: Colors.redAccent),
                          onPressed: () {
                            Provider.of<TtsService>(context, listen: false).speak(word.higaonon);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
