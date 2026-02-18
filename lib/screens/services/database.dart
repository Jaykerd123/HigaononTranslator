import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fireb/models/brew.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/user.dart';

class DatabaseService{

  final String? uid;
  DatabaseService({this.uid});

  // collection reference

  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Refactored updateUserData to use named optional parameters for flexibility
  Future<void> updateUserData({
    String? sugar,
    String? name,
    int? strength,
    String? profileImageUrl, // Maps to 'avatarUrl' in Firestore
    bool? isDarkMode,
    bool? onboardingCompleted,
  }) async {
    print('[DatabaseService] updateUserData called for uid: $uid');
    Map<String, dynamic> dataToUpdate = {};
    if (sugar != null) dataToUpdate['sugar'] = sugar;
    if (name != null) dataToUpdate['name'] = name;
    if (strength != null) dataToUpdate['strength'] = strength;
    if (profileImageUrl != null) dataToUpdate['avatarUrl'] = profileImageUrl;
    if (isDarkMode != null) dataToUpdate['isDarkMode'] = isDarkMode;
    if (onboardingCompleted != null) dataToUpdate['onboardingCompleted'] = onboardingCompleted;

    if (dataToUpdate.isNotEmpty) {
      print('[DatabaseService] Data to update: $dataToUpdate');
      // Use set with merge: true to create the document if it doesn't exist,
      // or update it if it does, without overwriting existing fields.
      return await usersCollection.doc(uid).set(dataToUpdate, SetOptions(merge: true));
    } else {
      print('[DatabaseService] No data to update.');
    }
  }

  Future<String> uploadProfilePicture(String imagePath) async {
    print('[DatabaseService] Starting profile picture upload from path: $imagePath');
    try {
      final ref = _storage.ref().child('user_avatars').child('$uid.jpg');
      print('[DatabaseService] Storage reference: ${ref.fullPath}');
      final uploadTask = await ref.putFile(File(imagePath), SettableMetadata(contentType: 'image/jpeg'));
      final url = await uploadTask.ref.getDownloadURL();
      print('[DatabaseService] Upload successful. Image URL: $url');
      return url;
    } catch (e) {
      print('[DatabaseService] Error uploading profile picture: $e');
      return '';
    }
  }


  // New method to update the theme preference (isDarkMode)
  Future<void> updateTheme(bool isDarkMode) async {
    // Use set with merge: true for theme preference as well
    return await usersCollection.doc(uid).set({
      'isDarkMode': isDarkMode,
    }, SetOptions(merge: true));
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
