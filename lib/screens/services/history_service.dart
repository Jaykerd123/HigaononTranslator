import 'package:flutter/foundation.dart';
import 'package:fireb/models/word.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Word> _history = [];

  List<Word> get history => _history;

  HistoryService();

  Future<void> loadHistoryFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      return; // User not logged in
    }

    try {
      final historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      _history.clear();
      for (var doc in historySnapshot.docs) {
        _history.add(Word.fromJson(doc.data()));
      }
      notifyListeners();
    } catch (e) {
      print('Error loading history from Firestore: $e');
    }
  }

  void addWordToHistory(Word word) async {
    final user = _auth.currentUser;
    if (user == null) {
      return; // User not logged in, cannot save history
    }

    // Remove the word if it already exists to avoid duplicates and move it to the top.
    _history.removeWhere((w) => w.higaonon == word.higaonon);
    _history.insert(0, word);

    notifyListeners();

    // Save to Firestore
    try {
      final wordData = word.toJson();
      wordData['timestamp'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .doc(word.higaonon) // Using higaonon as document ID for easy lookup/replacement
          .set(wordData);
    } catch (e) {
      print('Error saving word to history: $e');
    }
  }
}
