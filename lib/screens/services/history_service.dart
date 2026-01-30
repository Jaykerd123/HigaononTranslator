import 'package:flutter/foundation.dart';
import 'package:fireb/models/word.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth';

class HistoryService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Word> _history = [];

  List<Word> get history => _history;

  void addWordToHistory(Word word) async {
    final user = _auth.currentUser;
    if (user == null) {
      return; // User not logged in, cannot save history
    }

    // Remove the word if it already exists to avoid duplicates and move it to the top.
    _history.removeWhere((w) => w.higaonon == word.higaonon);
    _history.insert(0, word);

    // To keep the list from getting too long, you can limit its size.
    if (_history.length > 20) {
      _history.removeLast();
    }

    notifyListeners();

    // Save to Firestore
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .doc(word.higaonon) // Using higaonon as document ID for easy lookup/replacement
          .set(word.toJson());
    } catch (e) {
      print('Error saving word to history: $e');
    }
  }
}
