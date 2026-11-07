import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../utils/password_hasher.dart';
import '../services/firebase_auth_service.dart';

enum GoogleProfileStatus {
  authenticated,
  linkExistingAccount,
  createNewAccount,
  inactive,
  conflict,
  invalidIdentity,
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
      if (!linkedUser.isActive) {
        return GoogleProfileResolution(
          GoogleProfileStatus.inactive,
          user: linkedUser,
        );
      }
      return GoogleProfileResolution(
        GoogleProfileStatus.authenticated,
        user: linkedUser,
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
}

class AuthFlowException implements Exception {
  final AuthFlowError error;

  const AuthFlowException(this.error);
}
