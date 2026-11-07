import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthIdentity {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  const GoogleAuthIdentity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.emailVerified,
  });

  factory GoogleAuthIdentity.fromFirebaseUser(firebase_auth.User user) {
    return GoogleAuthIdentity(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }
}

class FirebaseAuthService {
  FirebaseAuthService({
    firebase_auth.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) : _authOverride = auth,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static Future<void>? _googleInitialization;

  final firebase_auth.FirebaseAuth? _authOverride;
  final GoogleSignIn _googleSignIn;

  firebase_auth.FirebaseAuth get _auth =>
      _authOverride ?? firebase_auth.FirebaseAuth.instance;

  Future<void> _initializeGoogleSignIn() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }

  Future<GoogleAuthIdentity?> signInWithGoogle() async {
    await _initializeGoogleSignIn();
    try {
      final googleAccount = await _googleSignIn.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google Sign-In n’a pas retourné d’ID token.');
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw StateError('Firebase n’a pas retourné d’utilisateur.');
      }
      return GoogleAuthIdentity.fromFirebaseUser(firebaseUser);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  GoogleAuthIdentity? get currentIdentity {
    if (_authOverride == null && Firebase.apps.isEmpty) return null;
    final currentUser = _auth.currentUser;
    return currentUser == null
        ? null
        : GoogleAuthIdentity.fromFirebaseUser(currentUser);
  }

  Future<void> signOut() async {
    if (_authOverride == null && Firebase.apps.isEmpty) return;
    await _auth.signOut();
    if (_googleInitialization != null) {
      await _googleInitialization;
      try {
        await _googleSignIn.signOut();
      } catch (error) {
        // Firebase is already signed out; this only affects account-picker UX.
        debugPrint('Google account picker sign-out failed: $error');
      }
    }
  }
}
