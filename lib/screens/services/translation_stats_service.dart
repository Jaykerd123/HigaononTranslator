import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:Higa/screens/services/app_logger.dart';

class TranslationStatsService with ChangeNotifier, WidgetsBindingObserver {
  static const String _progressDocumentId = 'progress_stats';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _trackingUserId;
  int _translationCount = 0;
  int _dayStreak = 0;
  int _timeSpentSeconds = 0;
  final Stopwatch _activeStopwatch = Stopwatch();
  Duration _pendingTime = Duration.zero;
  Timer? _timeTrackingTimer;
  bool _isAppActive = false;
  bool _isFlushingTime = false;
  bool _isDisposed = false;

  int get translationCount => _translationCount;
  int get dayStreak => _dayStreak;
  int get timeSpentSeconds => _timeSpentSeconds;

  TranslationStatsService()
    : _trackingUserId = FirebaseAuth.instance.currentUser?.uid {
    WidgetsBinding.instance.addObserver(this);
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (_trackingUserId != null &&
        lifecycleState != AppLifecycleState.paused &&
        lifecycleState != AppLifecycleState.detached) {
      _resumeTimeTracking();
    }
  }

  DocumentReference<Map<String, dynamic>> _statsDocument(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('history')
        .doc(_progressDocumentId);
  }

  Map<String, dynamic> _historyDocumentFields() {
    return {
      'higaonon': '',
      'tagalog': '',
      'part_of_speech': '',
      'english': '',
      'example_higaonon': '',
      'example_english': '',
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  Future<void> loadTranslationStatsFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.debug(
        'FIRESTORE',
        'Statistics load skipped because no user is authenticated.',
      );
      return;
    }

    try {
      final docSnapshot = await _statsDocument(user.uid).get();
      final data = docSnapshot.data();
      _translationCount = (data?['translationCount'] as num?)?.toInt() ?? 0;
      _dayStreak = (data?['currentStreak'] as num?)?.toInt() ?? 0;
      _timeSpentSeconds = (data?['timeSpentSeconds'] as num?)?.toInt() ?? 0;
      AppLogger.debug(
        'FIRESTORE',
        docSnapshot.exists
            ? 'Translation statistics loaded.'
            : 'No translation statistics document found.',
      );
      notifyListeners();
    } catch (error, stackTrace) {
      _logFirestoreError('load translation statistics', error, stackTrace);
    }
  }

  Future<void> recordTranslation() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.debug(
        'FIRESTORE',
        'Statistics save skipped because no user is authenticated.',
      );
      return;
    }

    final today = _dateKey(DateTime.now());
    var updatedCount = 0;
    var updatedStreak = 0;

    try {
      AppLogger.debug('FIRESTORE', 'Saving translation statistics.');
      await _firestore.runTransaction((transaction) async {
        final document = _statsDocument(user.uid);
        final snapshot = await transaction.get(document);
        final data = snapshot.data() ?? <String, dynamic>{};
        final storedDate = data['lastTranslationDate'];
        final currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;

        updatedCount = (data['translationCount'] as num?)?.toInt() ?? 0;
        updatedCount++;
        updatedStreak = calculateDayStreak(
          currentStreak: currentStreak,
          lastTranslationDate: storedDate is String ? storedDate : null,
          activityDate: DateTime.parse(today),
        );

        transaction.set(document, {
          ..._historyDocumentFields(),
          'translationCount': updatedCount,
          'currentStreak': updatedStreak,
          'lastTranslationDate': today,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      _translationCount = updatedCount;
      _dayStreak = updatedStreak;
      notifyListeners();
      AppLogger.debug('FIRESTORE', 'Statistics saved successfully.');
    } catch (error, stackTrace) {
      _logFirestoreError('save translation statistics', error, stackTrace);
    }
  }

  Future<void> resetTranslationCount() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.debug(
        'FIRESTORE',
        'Statistics reset skipped because no user is authenticated.',
      );
      return;
    }

    try {
      AppLogger.debug('FIRESTORE', 'Resetting translation statistics.');
      await _statsDocument(user.uid).set({
        ..._historyDocumentFields(),
        'translationCount': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _translationCount = 0;
      notifyListeners();
      AppLogger.debug('FIRESTORE', 'Statistics reset successfully.');
    } catch (error, stackTrace) {
      _logFirestoreError('reset translation statistics', error, stackTrace);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeTimeTracking();
    } else {
      _pauseTimeTracking();
    }
  }

  void _resumeTimeTracking() {
    if (_trackingUserId == null || _isAppActive || _isDisposed) return;

    _isAppActive = true;
    _activeStopwatch.start();
    _timeTrackingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_flushActiveTime()),
    );
  }

  void _pauseTimeTracking() {
    if (!_isAppActive) return;

    _isAppActive = false;
    _timeTrackingTimer?.cancel();
    _timeTrackingTimer = null;
    _pendingTime += _activeStopwatch.elapsed;
    _activeStopwatch
      ..stop()
      ..reset();
    unawaited(_flushActiveTime());
  }

  Future<void> _flushActiveTime() async {
    if (_activeStopwatch.isRunning) {
      _pendingTime += _activeStopwatch.elapsed;
      _activeStopwatch
        ..stop()
        ..reset();
      if (_isAppActive) _activeStopwatch.start();
    }
    final userId = _trackingUserId;
    if (_isFlushingTime || userId == null) return;

    final seconds = _pendingTime.inSeconds;
    if (seconds == 0) return;
    _pendingTime -= Duration(seconds: seconds);
    _isFlushingTime = true;
    var saved = false;

    try {
      AppLogger.debug('FIRESTORE', 'Saving active app time.');
      await _statsDocument(userId).set({
        ..._historyDocumentFields(),
        'timeSpentSeconds': FieldValue.increment(seconds),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _timeSpentSeconds += seconds;
      saved = true;
      if (!_isDisposed) notifyListeners();
      AppLogger.debug('FIRESTORE', 'Active app time saved successfully.');
    } catch (error, stackTrace) {
      _pendingTime += Duration(seconds: seconds);
      _logFirestoreError('save time spent', error, stackTrace);
    } finally {
      _isFlushingTime = false;
      if (saved && _pendingTime.inSeconds > 0) {
        unawaited(_flushActiveTime());
      }
    }
  }

  @visibleForTesting
  static int calculateDayStreak({
    required int currentStreak,
    required String? lastTranslationDate,
    required DateTime activityDate,
  }) {
    final today = _dateKey(activityDate);
    if (lastTranslationDate == today) {
      return currentStreak == 0 ? 1 : currentStreak;
    }

    final lastDate = lastTranslationDate == null
        ? null
        : DateTime.tryParse(lastTranslationDate);
    if (lastDate == null) return 1;

    final previousDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final todayDate = DateTime(
      activityDate.year,
      activityDate.month,
      activityDate.day,
    );
    return todayDate.difference(previousDate).inDays == 1
        ? currentStreak + 1
        : 1;
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timeTrackingTimer?.cancel();
    _timeTrackingTimer = null;
    _isAppActive = false;
    _pendingTime += _activeStopwatch.elapsed;
    _activeStopwatch
      ..stop()
      ..reset();
    unawaited(_flushActiveTime());
    super.dispose();
  }
}
