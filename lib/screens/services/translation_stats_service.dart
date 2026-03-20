import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TranslationStatsService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _translationCount = 0;

  int get translationCount => _translationCount;

  TranslationStatsService();

  Future<void> loadTranslationStatsFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('TranslationStatsService: Cannot load stats, user is not logged in.');
      return;
    }

    print('TranslationStatsService: Loading translation stats for user ${user.uid}...');
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('translation_stats')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        _translationCount = data['translationCount'] ?? 0;
        print('TranslationStatsService: Loaded translation count: $_translationCount');
      } else {
        _translationCount = 0;
        print('TranslationStatsService: No stats found, starting from 0');
      }
      notifyListeners();
    } catch (e) {
      print('TranslationStatsService: Error loading translation stats: $e');
      _translationCount = 0;
      notifyListeners();
    }
  }

  Future<void> incrementTranslationCount() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('TranslationStatsService: Cannot increment count, user is not logged in.');
      return;
    }

    _translationCount++;
    notifyListeners();

    print('TranslationStatsService: Incrementing translation count to $_translationCount for user ${user.uid}.');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('translation_stats')
          .set({
            'translationCount': _translationCount,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      print('TranslationStatsService: Successfully saved translation count to Firestore.');
    } catch (e) {
      print('TranslationStatsService: Error saving translation count: $e');
      // Revert the increment if save failed
      _translationCount--;
      notifyListeners();
    }
  }

  Future<void> resetTranslationCount() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('TranslationStatsService: Cannot reset count, user is not logged in.');
      return;
    }

    _translationCount = 0;
    notifyListeners();

    print('TranslationStatsService: Resetting translation count for user ${user.uid}.');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('translation_stats')
          .set({
            'translationCount': 0,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      print('TranslationStatsService: Successfully reset translation count in Firestore.');
    } catch (e) {
      print('TranslationStatsService: Error resetting translation count: $e');
    }
  }
}
