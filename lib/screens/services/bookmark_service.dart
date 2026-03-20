import 'package:flutter/foundation.dart';
import 'package:Higa/models/word.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Word> _bookmarks = [];

  List<Word> get bookmarks => _bookmarks;

  BookmarkService();

  Future<void> loadBookmarksFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('BookmarkService: Cannot load bookmarks, user is not logged in.');
      return;
    }

    print('BookmarkService: Loading bookmarks for user ${user.uid}...');
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
      print('BookmarkService: Loaded ${_bookmarks.length} items from Firestore.');
      notifyListeners();
    } catch (e) {
      print('BookmarkService: Error loading bookmarks from Firestore: $e');
    }
  }

  void toggleBookmark(Word word) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('BookmarkService: Cannot toggle bookmark, user is not logged in.');
      return;
    }

    final isBookmarked = _bookmarks.any((w) => w.higaonon == word.higaonon);

    if (isBookmarked) {
      _bookmarks.removeWhere((w) => w.higaonon == word.higaonon);
      print('BookmarkService: Removing word ${word.higaonon} from bookmarks.');
    } else {
      _bookmarks.insert(0, word);
      print('BookmarkService: Adding word ${word.higaonon} to bookmarks.');
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
      print('BookmarkService: Successfully updated bookmarks in Firestore.');
    } catch (e) {
      print('BookmarkService: Error updating bookmarks: $e');
    }
  }

  bool isBookmarked(Word word) {
    return _bookmarks.any((w) => w.higaonon == word.higaonon);
  }
}

