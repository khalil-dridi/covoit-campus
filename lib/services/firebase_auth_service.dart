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
  final bool isGoogleProvider;

  const GoogleAuthIdentity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.emailVerified,
    this.isGoogleProvider = false,
  });

  factory GoogleAuthIdentity.fromFirebaseUser(firebase_auth.User user) {
    return GoogleAuthIdentity(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      isGoogleProvider: user.providerData.any(
        (provider) => provider.providerId == 'google.com',
      ),
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

  Future<GoogleAuthIdentity> createEmailAccount({
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user;
    if (user == null)
      throw StateError('Firebase n’a pas retourné d’utilisateur.');
    return GoogleAuthIdentity.fromFirebaseUser(user);
  }

  Future<GoogleAuthIdentity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user;
    if (user == null)
      throw StateError('Firebase n’a pas retourné d’utilisateur.');
    return GoogleAuthIdentity.fromFirebaseUser(user);
  }

  Future<GoogleAuthIdentity?> reloadCurrentUser() async {
    if (_authOverride == null && Firebase.apps.isEmpty) return null;
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    final refreshed = _auth.currentUser;
    return refreshed == null
        ? null
        : GoogleAuthIdentity.fromFirebaseUser(refreshed);
  }

  Future<void> sendEmailVerification({required String expectedUid}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Aucun utilisateur Firebase connecté.');
    if (user.uid != expectedUid) {
      debugPrint(
        'Vérification e-mail annulée : UID Firebase actif différent du profil '
        '(actif=${_shortUid(user.uid)}, attendu=${_shortUid(expectedUid)}).',
      );
      throw StateError('Le compte Firebase actif ne correspond pas au profil.');
    }

    debugPrint(
      'Envoi vérification Firebase démarré '
      '(uid=${_shortUid(user.uid)}, email=${_maskedEmail(user.email)}).',
    );
    try {
      await user.sendEmailVerification();
      debugPrint(
        'Envoi vérification Firebase terminé avec succès '
        '(uid=${_shortUid(user.uid)}).',
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      debugPrint(
        'Échec envoi vérification Firebase '
        '(uid=${_shortUid(user.uid)}, code=${error.code}).',
      );
      rethrow;
    } catch (error) {
      debugPrint(
        'Échec inattendu envoi vérification Firebase '
        '(uid=${_shortUid(user.uid)}, type=${error.runtimeType}).',
      );
      rethrow;
    }
  }

  String _shortUid(String uid) =>
      uid.length <= 6 ? uid : '…${uid.substring(uid.length - 6)}';

  String _maskedEmail(String? email) {
    if (email == null || email.isEmpty) return 'indisponible';
    final at = email.indexOf('@');
    if (at <= 0 || at == email.length - 1) return 'masquée';
    final local = email.substring(0, at);
    return '${local.substring(0, 1)}***${email.substring(at)}';
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> updateCurrentPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Aucun utilisateur Firebase connecté.');
    await user.updatePassword(password);
  }

  Future<void> changeCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw StateError('Aucun compte e-mail Firebase connecté.');
    }
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
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
