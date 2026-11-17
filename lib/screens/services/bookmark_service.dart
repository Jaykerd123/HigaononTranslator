import 'package:flutter/foundation.dart';
import 'package:Higa/models/word.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Higa/screens/services/app_logger.dart';

class BookmarkService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Word> _bookmarks = [];

  List<Word> get bookmarks => _bookmarks;

  BookmarkService();

  Future<void> loadBookmarksFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.debug(
        'FIRESTORE',
        'Bookmark load skipped because no user is authenticated.',
      );
      return;
    }

    AppLogger.debug('FIRESTORE', 'Loading bookmarks.');
    try {
      final bookmarkSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .orderBy('timestamp', descending: true)
          .get();

      _bookmarks.clear();
      for (var doc in bookmarkSnapshot.docs) {
        _bookmarks.add(Word.fromJson(doc.data()));
      }
      AppLogger.debug(
        'FIRESTORE',
        'Bookmarks loaded (${_bookmarks.length} entries).',
      );
      notifyListeners();
    } catch (error, stackTrace) {
      _logFirestoreError('load bookmarks', error, stackTrace);
    }
  }

  void toggleBookmark(Word word) async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.debug(
        'FIRESTORE',
        'Bookmark update skipped because no user is authenticated.',
      );
      return;
    }

    final isBookmarked = _bookmarks.any((w) => w.higaonon == word.higaonon);

    if (isBookmarked) {
      _bookmarks.removeWhere((w) => w.higaonon == word.higaonon);
      AppLogger.debug('FIRESTORE', 'Removing bookmark.');
    } else {
      _bookmarks.insert(0, word);
      AppLogger.debug('FIRESTORE', 'Saving bookmark.');
    }

    notifyListeners();

    try {
      if (isBookmarked) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookmarks')
            .doc(word.higaonon)
            .delete();
      } else {
        final wordData = word.toJson();
        wordData['timestamp'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookmarks')
            .doc(word.higaonon)
            .set(wordData);
      }
      AppLogger.debug(
        'FIRESTORE',
        'Bookmark operation completed successfully.',
      );
    } catch (error, stackTrace) {
      _logFirestoreError(
        isBookmarked ? 'delete bookmark' : 'save bookmark',
        error,
        stackTrace,
      );
    }
  }

  void _logFirestoreError(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    final message =
        error is FirebaseException && error.code == 'permission-denied'
        ? 'Permission denied. Operation: $operation.'
        : 'Operation $operation failed (${error.runtimeType}).';
    AppLogger.error('FIRESTORE', message, stackTrace: stackTrace);
  }

  bool isBookmarked(Word word) {
    return _bookmarks.any((w) => w.higaonon == word.higaonon);
  }
}
