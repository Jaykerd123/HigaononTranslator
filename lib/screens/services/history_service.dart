import 'package:flutter/foundation.dart';
import 'package:Higa/models/word.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Higa/screens/services/app_logger.dart';

class HistoryService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Word> _history = [];

  List<Word> get history => _history;

  HistoryService();

  Future<void> loadHistoryFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.debug(
        'FIRESTORE',
        'History load skipped because no user is authenticated.',
      );
      return;
    }

    AppLogger.debug('FIRESTORE', 'Loading translation history.');
    try {
      final historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      _history.clear();
      for (var doc in historySnapshot.docs) {
        if (doc.id == 'progress_stats') continue;
        _history.add(Word.fromJson(doc.data()));
      }
      AppLogger.debug(
        'FIRESTORE',
        'Translation history loaded (${_history.length} entries).',
      );
      notifyListeners();
    } catch (error, stackTrace) {
      _logFirestoreError('load translation history', error, stackTrace);
    }
  }

  void addWordToHistory(Word word) async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.debug(
        'FIRESTORE',
        'History save skipped because no user is authenticated.',
      );
      return;
    }
    // Remove the word if it already exists to avoid duplicates and move it to the top.
    _history.removeWhere((w) => w.higaonon == word.higaonon);
    _history.insert(0, word);

    notifyListeners();

    // Save to Firestore
    try {
      AppLogger.debug('FIRESTORE', 'Saving translation history.');
      final wordData = word.toJson();
      wordData['timestamp'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .doc(
            word.higaonon,
          ) // Using higaonon as document ID for easy lookup/replacement
          .set(wordData);
      AppLogger.debug('FIRESTORE', 'History saved successfully.');
    } catch (error, stackTrace) {
      _logFirestoreError('save translation history', error, stackTrace);
    }
  }

  Future<void> deleteHistoryItems(Iterable<String> higaononWords) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Cannot delete history, user is not logged in.');
    }

    final ids = higaononWords.toSet().toList();
    if (ids.isEmpty) return;

    AppLogger.debug('FIRESTORE', 'Deleting translation history entries.');
    final historyCollection = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('history');

    for (var offset = 0; offset < ids.length; offset += 500) {
      final batch = _firestore.batch();
      for (final id in ids.skip(offset).take(500)) {
        batch.delete(historyCollection.doc(id));
      }
      try {
        await batch.commit();
      } catch (error, stackTrace) {
        _logFirestoreError('delete translation history', error, stackTrace);
        rethrow;
      }
    }

    _history.removeWhere((word) => ids.contains(word.higaonon));
    notifyListeners();
    AppLogger.debug('FIRESTORE', 'Translation history entries deleted.');
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
}
