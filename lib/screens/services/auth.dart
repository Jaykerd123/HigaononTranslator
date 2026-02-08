import 'package:firebase_auth/firebase_auth.dart';
import 'package:fireb/models/user.dart';
import 'package:fireb/screens/services/database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fb;

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // create custom user object based on Firebase User
  CustomUser? _userFromFirebaseUser(User? user) {
    return user != null ? CustomUser(uid: user.uid) : null;
  }

  // auth change user stream
  Stream<CustomUser?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // sign in anon
  Future<CustomUser?> signInAnon() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      return null;
    }
  }

  // sign in with email and password
  Future<CustomUser?> signInWithEmailAndPassword(String email, String password) async {
    try{
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch(e){
      return null;
    }
  }

  Future<CustomUser?> registerWithEmailAndPassword(String email, String password) async {
    try{
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch(e){
      return null;
    }
  }

  // sign in with google
  Future<CustomUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      return null;
    }
  }

  // sign in with facebook
  Future<CustomUser?> signInWithFacebook() async {
    try {
      final fb.LoginResult result = await fb.FacebookAuth.instance.login();
      if (result.status == fb.LoginStatus.success) {
        final fb.AccessToken? accessToken = result.accessToken;
        if (accessToken != null) {
          final AuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);
          UserCredential userCredential = await _auth.signInWithCredential(credential);
          User? user = userCredential.user;
          return _userFromFirebaseUser(user);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await fb.FacebookAuth.instance.logOut();
      await _auth.signOut();
    } catch (e) {
      // It's generally safe to ignore errors on sign out
    }
  }

}