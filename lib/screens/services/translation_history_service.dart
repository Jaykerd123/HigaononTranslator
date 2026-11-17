import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:Higa/screens/services/translation_history_store.dart';
import 'package:Higa/screens/services/app_logger.dart';

class TranslationHistoryService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<TranslationHistoryEntry> _history = [];

  List<TranslationHistoryEntry> get history => _history;

  TranslationHistoryService();

  Future<void> loadTranslationHistoryFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
        'TranslationHistoryService: Cannot load translation history, user is not logged in.',
      );
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('translation_history')
          .orderBy('timestamp', descending: true)
          .get();

      _history.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _history.add(
          TranslationHistoryEntry(
            source: data['source']?.toString() ?? '',
            result: data['result']?.toString() ?? '',
            type: data['type']?.toString() ?? 'Text',
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        );
      }

      notifyListeners();
    } catch (error, stackTrace) {
      _logFirestoreError('load translation history', error, stackTrace);
    }
  }

  Future<void> addTranslationToHistory({
    required String sourceText,
    required String translatedText,
    required String type,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
        'TranslationHistoryService: Cannot save translation history, user is not logged in.',
      );
      return;
    }

    final entry = TranslationHistoryEntry(
      source: sourceText,
      result: translatedText,
      type: type,
      timestamp: DateTime.now(),
    );

    _history.clear();
    _history.addAll(TranslationHistoryStore.addEntry(_history, entry));
    notifyListeners();

    try {
      AppLogger.debug('FIRESTORE', 'Saving translation history.');
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('translation_history')
          .doc('${DateTime.now().millisecondsSinceEpoch}_$type')
          .set({
            'source': entry.source,
            'result': entry.result,
            'type': entry.type,
            'timestamp': FieldValue.serverTimestamp(),
          });
      AppLogger.debug('FIRESTORE', 'History saved successfully.');
    } catch (error, stackTrace) {
      _logFirestoreError('save translation history', error, stackTrace);
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
}
