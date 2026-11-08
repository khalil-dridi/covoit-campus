import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../utils/password_hasher.dart';
import '../services/firebase_auth_service.dart';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

enum GoogleProfileStatus {
  authenticated,
  linkExistingAccount,
  createNewAccount,
  inactive,
  conflict,
  invalidIdentity,
  unverified,
}

class GoogleProfileResolution {
  final GoogleProfileStatus status;
  final User? user;

  const GoogleProfileResolution(this.status, {this.user});
}

class AuthCoordinator {
  AuthCoordinator({
    FirebaseAuthService? firebaseAuthService,
    UserRepository? userRepository,
  }) : _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService(),
       _userRepository = userRepository ?? UserRepository();

  final FirebaseAuthService _firebaseAuthService;
  final UserRepository _userRepository;

  Future<GoogleAuthIdentity?> signInWithGoogle() =>
      _firebaseAuthService.signInWithGoogle();

  GoogleAuthIdentity? get currentIdentity =>
      _firebaseAuthService.currentIdentity;

  Future<User?> restoreSession() async {
    final identity = await _firebaseAuthService.reloadCurrentUser();
    if (identity == null || identity.uid.isEmpty) return null;
    if (identity.isGoogleProvider) {
      final resolution = await resolveGoogleIdentity(identity);
      return resolution.status == GoogleProfileStatus.authenticated
          ? resolution.user
          : null;
    }
    final local = await _userRepository.findUserByFirebaseUid(identity.uid);
    if (local == null ||
        !local.isActive ||
        !identity.emailVerified ||
        identity.email?.trim().toLowerCase() != local.email.toLowerCase()) {
      return null;
    }
    return _userRepository.syncFirebaseVerification(identity.uid, true);
  }

  Future<User> registerEmailAccount({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    if (role != 'passenger' && role != 'driver') {
      throw const AuthFlowException(AuthFlowError.invalidRole);
    }
    final normalized = email.trim().toLowerCase();
    if (await _userRepository.findUserByEmail(normalized) != null) {
      throw const AuthFlowException(AuthFlowError.accountConflict);
    }
    GoogleAuthIdentity identity;
    try {
      identity = await _firebaseAuthService.createEmailAccount(
        email: normalized,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      // Recovery path for a previous Firebase success followed by a local
      // SQLite failure. The password proves control before recreating a row.
      identity = await _firebaseAuthService.signInWithEmail(
        email: normalized,
        password: password,
      );
    }
    if (identity.uid.isEmpty)
      throw const AuthFlowException(AuthFlowError.invalidIdentity);
    final now = DateTime.now().toIso8601String();
    final profile = User(
      fullName: fullName.trim(),
      email: normalized,
      passwordHash: '',
      firebaseUid: identity.uid,
      role: role,
      isVerified: identity.emailVerified,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    final saved = await _userRepository.registerFirebaseUser(profile);
    // Keep the Firebase identity and local profile if sending fails; the
    // verification screen exposes a retry action.
    return saved;
  }

  Future<void> sendVerificationEmail({required String expectedUid}) =>
      _firebaseAuthService.sendEmailVerification(expectedUid: expectedUid);

  Future<User?> refreshVerification({required int userId}) async {
    final identity = await _firebaseAuthService.reloadCurrentUser();
    if (identity == null || identity.uid.isEmpty) return null;
    final local = await _userRepository.findUserByFirebaseUid(identity.uid);
    if (local == null || local.id != userId || !local.isActive) return null;
    return _userRepository.syncFirebaseVerification(
      identity.uid,
      identity.emailVerified,
    );
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _firebaseAuthService.sendPasswordResetEmail(email);

  Future<bool> changeAdminPassword({
    required User admin,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (admin.role != 'admin' ||
        admin.id == null ||
        admin.firebaseUid == null) {
      throw const AuthFlowException(AuthFlowError.invalidIdentity);
    }
    final identity = _firebaseAuthService.currentIdentity;
    if (identity == null ||
        identity.uid != admin.firebaseUid ||
        identity.email?.toLowerCase() != admin.email.toLowerCase()) {
      throw const AuthFlowException(AuthFlowError.accountConflict);
    }
    await _firebaseAuthService.changeCurrentPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return _userRepository.changeAdminPassword(userId: admin.id!);
  }

  Future<User> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final local = await _userRepository.findUserByEmail(normalized);
    if (local == null)
      throw const AuthFlowException(AuthFlowError.invalidCredentials);
    if (!local.isActive)
      throw const AuthFlowException(AuthFlowError.inactiveAccount);

    GoogleAuthIdentity identity;
    if (local.firebaseUid == null) {
      if (local.passwordHash.isEmpty ||
          hashPassword(password) != local.passwordHash) {
        throw const AuthFlowException(AuthFlowError.invalidCredentials);
      }
      try {
        identity = await _firebaseAuthService.createEmailAccount(
          email: normalized,
          password: password,
        );
      } on firebase_auth.FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        // Existing Firebase identity must prove control with its password.
        identity = await _firebaseAuthService.signInWithEmail(
          email: normalized,
          password: password,
        );
      }
      if (identity.uid.isEmpty)
        throw const AuthFlowException(AuthFlowError.invalidIdentity);
      late User linked;
      try {
        linked = await _userRepository.linkAuthenticatedEmailAccount(
          userId: local.id!,
          email: normalized,
          firebaseUid: identity.uid,
          emailVerified: identity.emailVerified,
        );
      } catch (_) {
        // A partial Firebase success must not become an app session without
        // a matching local profile. The Firebase account remains recoverable.
        try {
          await _firebaseAuthService.signOut();
        } catch (_) {}
        rethrow;
      }
      if (!identity.emailVerified)
        throw const AuthFlowException(AuthFlowError.emailNotVerified);
      return linked;
    }

    identity = await _firebaseAuthService.signInWithEmail(
      email: normalized,
      password: password,
    );
    if (identity.uid.isEmpty || identity.uid != local.firebaseUid) {
      await _firebaseAuthService.signOut();
      throw const AuthFlowException(AuthFlowError.accountConflict);
    }
    final refreshed = await _firebaseAuthService.reloadCurrentUser();
    if (refreshed == null || refreshed.uid != local.firebaseUid) {
      throw const AuthFlowException(AuthFlowError.invalidIdentity);
    }
    final synced = await _userRepository.syncFirebaseVerification(
      refreshed.uid,
      refreshed.emailVerified,
    );
    if (!refreshed.emailVerified) {
      throw const AuthFlowException(AuthFlowError.emailNotVerified);
    }
    if (synced == null || !synced.isActive)
      throw const AuthFlowException(AuthFlowError.inactiveAccount);
    return synced;
  }

  Future<GoogleProfileResolution> resolveGoogleIdentity(
    GoogleAuthIdentity identity,
  ) async {
    final email = identity.email?.trim().toLowerCase();
    if (identity.uid.isEmpty || email == null || email.isEmpty) {
      return const GoogleProfileResolution(GoogleProfileStatus.invalidIdentity);
    }

    final linkedUser = await _userRepository.findUserByFirebaseUid(
      identity.uid,
    );
    if (linkedUser != null) {
      if (linkedUser.email.trim().toLowerCase() != email) {
        return GoogleProfileResolution(
          GoogleProfileStatus.conflict,
          user: linkedUser,
        );
      }
      if (!identity.emailVerified) {
        return GoogleProfileResolution(
          GoogleProfileStatus.unverified,
          user: linkedUser,
        );
      }
      if (!linkedUser.isActive) {
        return GoogleProfileResolution(
          GoogleProfileStatus.inactive,
          user: linkedUser,
        );
      }
      final synced = await _userRepository.syncFirebaseVerification(
        identity.uid,
        identity.emailVerified,
      );
      return GoogleProfileResolution(
        GoogleProfileStatus.authenticated,
        user: synced ?? linkedUser,
      );
    }

    final emailUser = await _userRepository.findUserByEmail(email);
    if (emailUser != null) {
      if (!emailUser.isActive) {
        return GoogleProfileResolution(
          GoogleProfileStatus.inactive,
          user: emailUser,
        );
      }
      if (emailUser.firebaseUid != null &&
          emailUser.firebaseUid != identity.uid) {
        return GoogleProfileResolution(
          GoogleProfileStatus.conflict,
          user: emailUser,
        );
      }
      return GoogleProfileResolution(
        GoogleProfileStatus.linkExistingAccount,
        user: emailUser,
      );
    }

    return const GoogleProfileResolution(GoogleProfileStatus.createNewAccount);
  }

  Future<User> linkExistingAccount({
    required GoogleAuthIdentity identity,
    required User existingUser,
    required String password,
  }) async {
    if (!identity.emailVerified) {
      throw const AuthFlowException(AuthFlowError.unverifiedGoogleEmail);
    }
    final email = identity.email?.trim().toLowerCase();
    if (email == null || email.isEmpty || existingUser.id == null) {
      throw const AuthFlowException(AuthFlowError.invalidIdentity);
    }
    try {
      return await _userRepository.linkFirebaseUidToVerifiedAccount(
        userId: existingUser.id!,
        email: email,
        passwordHash: hashPassword(password),
        firebaseUid: identity.uid,
        emailVerified: identity.emailVerified,
      );
    } on UserProfileConflictException catch (error) {
      switch (error.reason) {
        case UserProfileConflictReason.invalidProof:
          throw const AuthFlowException(AuthFlowError.invalidLocalPassword);
        case UserProfileConflictReason.inactive:
          throw const AuthFlowException(AuthFlowError.inactiveAccount);
        case UserProfileConflictReason.uidAlreadyLinked:
        case UserProfileConflictReason.emailAlreadyExists:
        case UserProfileConflictReason.accountChanged:
          throw const AuthFlowException(AuthFlowError.accountConflict);
      }
    }
  }

  Future<User> createGoogleAccount({
    required GoogleAuthIdentity identity,
    required String fullName,
    required String role,
  }) async {
    if (!identity.emailVerified) {
      throw const AuthFlowException(AuthFlowError.unverifiedGoogleEmail);
    }
    final email = identity.email?.trim().toLowerCase();
    final name = fullName.trim();
    if (email == null || email.isEmpty || name.length < 3) {
      throw const AuthFlowException(AuthFlowError.invalidIdentity);
    }
    if (role != 'passenger' && role != 'driver') {
      throw const AuthFlowException(AuthFlowError.invalidRole);
    }
    try {
      return await _userRepository.registerGoogleUser(
        fullName: name,
        email: email,
        profileImage: identity.photoUrl,
        firebaseUid: identity.uid,
        role: role,
        emailVerified: identity.emailVerified,
      );
    } on UserProfileConflictException {
      throw const AuthFlowException(AuthFlowError.accountConflict);
    }
  }

  Future<void> signOut() => _firebaseAuthService.signOut();
}

enum AuthFlowError {
  invalidIdentity,
  invalidRole,
  invalidLocalPassword,
  inactiveAccount,
  accountConflict,
  unverifiedGoogleEmail,
  invalidCredentials,
  emailNotVerified,
}

class AuthFlowException implements Exception {
  final AuthFlowError error;

  const AuthFlowException(this.error);
}
