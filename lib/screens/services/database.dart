import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Higa/models/brew.dart';
import 'package:Higa/screens/services/app_logger.dart';

import '../../models/user.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // collection reference

  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Refactored updateUserData to use named optional parameters for flexibility
  Future<void> updateUserData({
    String? sugar,
    String? name,
    int? strength,
    String? profileImageUrl, // Maps to 'avatarUrl' in Firestore
    bool? isDarkMode,
    bool? onboardingCompleted,
    bool? soundEffectsEnabled,
  }) async {
    Map<String, dynamic> dataToUpdate = {};
    if (sugar != null) {
      dataToUpdate['sugar'] = sugar;
    }
    if (name != null) {
      dataToUpdate['name'] = name;
    }
    if (strength != null) {
      dataToUpdate['strength'] = strength;
    }
    if (profileImageUrl != null) {
      dataToUpdate['avatarUrl'] = profileImageUrl;
    }
    if (isDarkMode != null) {
      dataToUpdate['isDarkMode'] = isDarkMode;
    }
    if (onboardingCompleted != null) {
      dataToUpdate['onboardingCompleted'] = onboardingCompleted;
    }
    if (soundEffectsEnabled != null) {
      dataToUpdate['soundEffectsEnabled'] = soundEffectsEnabled;
    }

    if (dataToUpdate.isNotEmpty) {
      AppLogger.debug(
        'FIRESTORE',
        'Saving user profile fields: ${dataToUpdate.keys.join(', ')}.',
      );
      // Use set with merge: true to create the document if it doesn't exist,
      // or update it if it does, without overwriting existing fields.
      try {
        await usersCollection
            .doc(uid)
            .set(dataToUpdate, SetOptions(merge: true));
        AppLogger.debug('FIRESTORE', 'User profile saved successfully.');
      } catch (error, stackTrace) {
        _logFirestoreError('save user profile', error, stackTrace);
        rethrow;
      }
    } else {
      AppLogger.debug('FIRESTORE', 'No user profile fields to save.');
    }
  }

  // New method to update theme preference (isDarkMode)
  Future<void> updateTheme(bool isDarkMode) async {
    // Use set with merge: true for theme preference as well
    AppLogger.debug('FIRESTORE', 'Saving theme preference.');
    try {
      await usersCollection.doc(uid).set({
        'isDarkMode': isDarkMode,
      }, SetOptions(merge: true));
      AppLogger.debug('FIRESTORE', 'Theme preference saved successfully.');
    } catch (error, stackTrace) {
      _logFirestoreError('save theme preference', error, stackTrace);
      rethrow;
    }
  }

  // New method to update sound effects preference
  Future<void> updateSoundEffects(bool soundEffectsEnabled) async {
    AppLogger.debug('FIRESTORE', 'Saving sound effects preference.');
    try {
      await usersCollection.doc(uid).set({
        'soundEffectsEnabled': soundEffectsEnabled,
      }, SetOptions(merge: true));
      AppLogger.debug(
        'FIRESTORE',
        'Sound effects preference saved successfully.',
      );
    } catch (error, stackTrace) {
      _logFirestoreError('save sound effects preference', error, stackTrace);
      rethrow;
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

  // brew list from snapshot
  List<Brew> _brewListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return Brew(
        name: data?['name'] ?? '',
        sugars: data?['sugar'] ?? '0',
        strength: data?['strength'] ?? 0,
      );
    }).toList();
  }

  // userData from snapshot
  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    return UserData(
      uid: uid!,
      name: data?['name'] ?? 'new crew member',
      sugar: data?['sugar'] ?? '0',
      strength: data?['strength'] ?? 100,
      avatarUrl: data?['avatarUrl'] ?? '',
      isDarkMode: data?['isDarkMode'] ?? false,
      onboardingCompleted: data?['onboardingCompleted'] ?? false,
      soundEffectsEnabled: data?['soundEffectsEnabled'],
    );
  }

  //   get brew stream
  Stream<List<Brew>> get users {
    return usersCollection.snapshots().map(_brewListFromSnapshot);
  }

  //   get user doc stream
  Stream<UserData> get userData {
    return usersCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }
}
