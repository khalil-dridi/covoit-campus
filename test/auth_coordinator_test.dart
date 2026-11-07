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
