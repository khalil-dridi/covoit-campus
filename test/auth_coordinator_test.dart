import 'package:flutter_test/flutter_test.dart';

import 'package:covoit_campus/auth/auth_coordinator.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/repositories/user_repository.dart';
import 'package:covoit_campus/services/firebase_auth_service.dart';
import 'package:covoit_campus/utils/password_hasher.dart';

void main() {
  final identity = GoogleAuthIdentity(
    uid: 'google-uid-1',
    email: 'person@example.tn',
    displayName: 'Google Person',
    photoUrl: 'https://example.tn/photo.png',
    emailVerified: true,
  );

  User makeUser({
    int id = 7,
    String role = 'passenger',
    bool active = true,
    String? firebaseUid,
  }) => User(
    id: id,
    fullName: 'Local Person',
    email: 'person@example.tn',
    passwordHash: hashPassword('secret123'),
    firebaseUid: firebaseUid,
    role: role,
    isVerified: true,
    isActive: active,
    createdAt: '2025-01-01T00:00:00.000',
    updatedAt: '2025-01-01T00:00:00.000',
  );

  group('AuthCoordinator profile resolution', () {
    test(
      'matches Firebase UID before email and preserves admin role',
      () async {
        final admin = makeUser(role: 'admin', firebaseUid: identity.uid);
        final repository = _FakeUserRepository(uidUser: admin);
        final coordinator = AuthCoordinator(
          firebaseAuthService: _FakeFirebaseAuthService(),
          userRepository: repository,
        );

        final result = await coordinator.resolveGoogleIdentity(identity);

        expect(result.status, GoogleProfileStatus.authenticated);
        expect(result.user?.role, 'admin');
        expect(repository.emailLookups, 0);
      },
    );

    test('requires local password proof for an existing email', () async {
      final repository = _FakeUserRepository(
        emailUser: makeUser(role: 'driver'),
      );
      final coordinator = AuthCoordinator(
        firebaseAuthService: _FakeFirebaseAuthService(),
        userRepository: repository,
      );

      final result = await coordinator.resolveGoogleIdentity(identity);

      expect(result.status, GoogleProfileStatus.linkExistingAccount);
      expect(result.user?.role, 'driver');
    });

    test('rejects inactive matching profiles', () async {
      final repository = _FakeUserRepository(
        emailUser: makeUser(active: false),
      );
      final coordinator = AuthCoordinator(
        firebaseAuthService: _FakeFirebaseAuthService(),
        userRepository: repository,
      );

      final result = await coordinator.resolveGoogleIdentity(identity);

      expect(result.status, GoogleProfileStatus.inactive);
    });

    test('detects UID collision on a matching local email', () async {
      final repository = _FakeUserRepository(
        emailUser: makeUser(firebaseUid: 'another-uid'),
      );
      final coordinator = AuthCoordinator(
        firebaseAuthService: _FakeFirebaseAuthService(),
        userRepository: repository,
      );

      final result = await coordinator.resolveGoogleIdentity(identity);

      expect(result.status, GoogleProfileStatus.conflict);
    });

    test('allows only Passenger or Driver for a new Google profile', () async {
      final repository = _FakeUserRepository();
      final coordinator = AuthCoordinator(
        firebaseAuthService: _FakeFirebaseAuthService(),
        userRepository: repository,
      );

      expect(
        await coordinator.resolveGoogleIdentity(identity),
        isA<GoogleProfileResolution>().having(
          (result) => result.status,
          'status',
          GoogleProfileStatus.createNewAccount,
        ),
      );
      await expectLater(
        coordinator.createGoogleAccount(
          identity: identity,
          fullName: 'Google Person',
          role: 'admin',
        ),
        throwsA(isA<AuthFlowException>()),
      );
    });

    test('links after local password proof and does not change role', () async {
      final existing = makeUser(role: 'driver');
      final repository = _FakeUserRepository(emailUser: existing);
      final coordinator = AuthCoordinator(
        firebaseAuthService: _FakeFirebaseAuthService(),
        userRepository: repository,
      );

      final linked = await coordinator.linkExistingAccount(
        identity: identity,
        existingUser: existing,
        password: 'secret123',
      );

      expect(repository.lastLinkedHash, hashPassword('secret123'));
      expect(linked.firebaseUid, identity.uid);
      expect(linked.role, 'driver');
    });
  });

  group('Firebase email authentication', () {
    test('registers a Firebase profile and keeps its requested role', () async {
      final repo = _EmailUserRepository();
      final service = _FakeEmailFirebaseAuthService(emailVerified: false);
      final coordinator = AuthCoordinator(
        firebaseAuthService: service,
        userRepository: repo,
      );
      final user = await coordinator.registerEmailAccount(
        fullName: 'New Driver',
        email: 'NEW@example.tn',
        password: 'Secret1234',
        role: 'driver',
      );
      expect(user.firebaseUid, 'email-uid');
      expect(user.email, 'new@example.tn');
      expect(user.passwordHash, isEmpty);
      expect(user.role, 'driver');
      expect(user.isVerified, isFalse);
    });

    test('migrates legacy profile only after local password proof', () async {
      final legacy = makeUser(role: 'admin');
      final repo = _EmailUserRepository(legacy);
      final service = _FakeEmailFirebaseAuthService(emailVerified: false);
      final coordinator = AuthCoordinator(
        firebaseAuthService: service,
        userRepository: repo,
      );
      await expectLater(
        coordinator.signInWithPassword(
          email: legacy.email,
          password: 'secret123',
        ),
        throwsA(
          isA<AuthFlowException>().having(
            (error) => error.error,
            'error',
            AuthFlowError.emailNotVerified,
          ),
        ),
      );
      expect(service.emailCreateCalls, 1);
      expect(service.verificationSends, 0);
      expect(repo.linkedUser?.id, legacy.id);
      expect(repo.linkedUser?.role, 'admin');
      expect(repo.linkedUser?.firebaseUid, 'email-uid');
      expect(repo.linkedUser?.passwordHash, isEmpty);
      expect(repo.linkedUser?.isVerified, isFalse);
    });

    test(
      'does not create Firebase identity for invalid legacy password',
      () async {
        final legacy = makeUser(role: 'driver');
        final repo = _EmailUserRepository(legacy);
        final service = _FakeEmailFirebaseAuthService();
        final coordinator = AuthCoordinator(
          firebaseAuthService: service,
          userRepository: repo,
        );
        await expectLater(
          coordinator.signInWithPassword(
            email: legacy.email,
            password: 'wrong',
          ),
          throwsA(isA<AuthFlowException>()),
        );
        expect(service.emailCreateCalls, 0);
        expect(repo.linkedUser, isNull);
      },
    );
  });
}

class _FakeFirebaseAuthService extends FirebaseAuthService {
  @override
  Future<GoogleAuthIdentity?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}
}

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository({this.uidUser, this.emailUser});

  User? uidUser;
  User? emailUser;
  int emailLookups = 0;
  String? lastLinkedHash;

  @override
  Future<User?> findUserByFirebaseUid(String firebaseUid) async => uidUser;

  @override
  Future<User?> syncFirebaseVerification(String firebaseUid, bool verified) async {
    if (uidUser?.firebaseUid == firebaseUid) {
      uidUser = uidUser!.copyWith(isVerified: verified);
      return uidUser;
    }
    return null;
  }

  @override
  Future<User?> findUserByEmail(String email) async {
    emailLookups++;
    return emailUser;
  }

  @override
  Future<User> linkFirebaseUidToVerifiedAccount({
    required int userId,
    required String email,
    required String passwordHash,
    required String firebaseUid,
    required bool emailVerified,
  }) async {
    lastLinkedHash = passwordHash;
    if (emailUser == null || emailUser!.passwordHash != passwordHash) {
      throw const UserProfileConflictException(
        UserProfileConflictReason.invalidProof,
      );
    }
    return emailUser!.copyWith(firebaseUid: firebaseUid, isVerified: true);
  }
}

class _EmailUserRepository extends UserRepository {
  _EmailUserRepository([this.existing]);

  User? existing;
  User? linkedUser;

  @override
  Future<User?> findUserByEmail(String email) async =>
      existing?.email.toLowerCase() == email.toLowerCase() ? existing : null;

  @override
  Future<User?> findUserByFirebaseUid(String firebaseUid) async =>
      linkedUser?.firebaseUid == firebaseUid ? linkedUser : null;

  @override
  Future<User> registerFirebaseUser(User user) async {
    existing = user.copyWith(id: 81);
    return existing!;
  }

  @override
  Future<User> linkAuthenticatedEmailAccount({
    required int userId,
    required String email,
    required String firebaseUid,
    required bool emailVerified,
  }) async {
    linkedUser = existing!.copyWith(
      passwordHash: '',
      firebaseUid: firebaseUid,
      isVerified: emailVerified,
    );
    existing = linkedUser;
    return linkedUser!;
  }

  @override
  Future<User?> syncFirebaseVerification(
    String firebaseUid,
    bool verified,
  ) async => linkedUser?.copyWith(isVerified: verified);
}

class _FakeEmailFirebaseAuthService extends FirebaseAuthService {
  _FakeEmailFirebaseAuthService({bool emailVerified = true})
    : identity = GoogleAuthIdentity(
        uid: 'email-uid',
        email: 'person@example.tn',
        displayName: 'Person',
        photoUrl: null,
        emailVerified: emailVerified,
      );

  final GoogleAuthIdentity identity;
  int emailCreateCalls = 0;
  int verificationSends = 0;

  @override
  Future<GoogleAuthIdentity> createEmailAccount({
    required String email,
    required String password,
  }) async {
    emailCreateCalls++;
    return identity;
  }

  @override
  Future<GoogleAuthIdentity> signInWithEmail({
    required String email,
    required String password,
  }) async => identity;

  @override
  Future<GoogleAuthIdentity?> reloadCurrentUser() async => identity;

  @override
  GoogleAuthIdentity? get currentIdentity => identity;

  @override
  Future<void> sendEmailVerification({required String expectedUid}) async {
    verificationSends++;
  }

  @override
  Future<void> signOut() async {}
}
