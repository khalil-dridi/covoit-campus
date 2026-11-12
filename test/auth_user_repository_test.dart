import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/repositories/user_repository.dart';
import 'package:covoit_campus/utils/password_hasher.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final repository = UserRepository();

  test('default administrator is created as active and verified', () async {
    final db = await DatabaseHelper.instance.database;
    final admins = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: ['admin@covoitcampus.tn'],
      limit: 1,
    );

    expect(admins, hasLength(1));
    expect(admins.single['role'], 'admin');
    expect(admins.single['is_verified'], 1);
    expect(admins.single['is_active'], 1);
  });

  test(
    'links an existing profile without changing its role or password',
    () async {
      final now = DateTime.now().toIso8601String();
      final email = 'link-${DateTime.now().microsecondsSinceEpoch}@example.tn';
      final localUser = User(
        fullName: 'Conducteur conservé',
        email: email,
        passwordHash: hashPassword('legacy-pass-123'),
        role: 'driver',
        isVerified: false,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      final id = await repository.registerUser(localUser);
      addTearDown(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('users', where: 'id = ?', whereArgs: [id]);
      });

      final linked = await repository.linkFirebaseUidToVerifiedAccount(
        userId: id,
        email: email.toUpperCase(),
        passwordHash: hashPassword('legacy-pass-123'),
        firebaseUid: 'firebase-link-$id',
        emailVerified: true,
      );

      expect(linked.id, id);
      expect(linked.role, 'driver');
      expect(linked.passwordHash, isEmpty);
      expect(linked.firebaseUid, 'firebase-link-$id');
      expect(linked.isVerified, isTrue);
    },
  );

  test(
    'rejects a wrong local password and leaves the profile unlinked',
    () async {
      final now = DateTime.now().toIso8601String();
      final email = 'proof-${DateTime.now().microsecondsSinceEpoch}@example.tn';
      final id = await repository.registerUser(
        User(
          fullName: 'Passager conservé',
          email: email,
          passwordHash: hashPassword('correct-pass-123'),
          role: 'passenger',
          isVerified: true,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      addTearDown(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('users', where: 'id = ?', whereArgs: [id]);
      });

      await expectLater(
        repository.linkFirebaseUidToVerifiedAccount(
          userId: id,
          email: email,
          passwordHash: hashPassword('wrong-pass-123'),
          firebaseUid: 'firebase-wrong-$id',
          emailVerified: true,
        ),
        throwsA(
          isA<UserProfileConflictException>().having(
            (error) => error.reason,
            'reason',
            UserProfileConflictReason.invalidProof,
          ),
        ),
      );
      expect(
        await repository.findUserByFirebaseUid('firebase-wrong-$id'),
        isNull,
      );
    },
  );

  test(
    'creates Google profiles and prevents UID and normalized-email duplicates',
    () async {
      final unique = DateTime.now().microsecondsSinceEpoch;
      final email = 'google-$unique@example.tn';
      final user = await repository.registerGoogleUser(
        fullName: 'Google Passenger',
        email: email,
        profileImage: 'https://example.tn/avatar.png',
        firebaseUid: 'firebase-new-$unique',
        role: 'passenger',
        emailVerified: true,
      );
      addTearDown(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('users', where: 'id = ?', whereArgs: [user.id]);
      });

      expect(user.passwordHash, isEmpty);
      expect(user.role, 'passenger');
      expect(user.isVerified, isTrue);
      expect(
        (await repository.findUserByFirebaseUid('firebase-new-$unique'))?.id,
        user.id,
      );
      await expectLater(
        repository.registerGoogleUser(
          fullName: 'Duplicate Google User',
          email: email.toUpperCase(),
          profileImage: null,
          firebaseUid: 'firebase-duplicate-$unique',
          role: 'driver',
          emailVerified: true,
        ),
        throwsA(
          isA<UserProfileConflictException>().having(
            (error) => error.reason,
            'reason',
            UserProfileConflictReason.emailAlreadyExists,
          ),
        ),
      );
      await expectLater(
        repository.registerGoogleUser(
          fullName: 'Duplicate UID User',
          email: 'another-$unique@example.tn',
          profileImage: null,
          firebaseUid: 'firebase-new-$unique',
          role: 'driver',
          emailVerified: true,
        ),
        throwsA(
          isA<UserProfileConflictException>().having(
            (error) => error.reason,
            'reason',
            UserProfileConflictReason.uidAlreadyLinked,
          ),
        ),
      );
    },
  );

  test('creates Firebase profile and syncs verification by UID', () async {
    final unique = DateTime.now().microsecondsSinceEpoch;
    final now = DateTime.now().toIso8601String();
    final email = 'firebase-$unique@example.tn';
    final created = await repository.registerFirebaseUser(
      User(
        fullName: 'Firebase Passenger',
        email: email,
        passwordHash: '',
        firebaseUid: 'firebase-profile-$unique',
        role: 'passenger',
        isVerified: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    addTearDown(() async {
      final db = await DatabaseHelper.instance.database;
      await db.delete('users', where: 'id = ?', whereArgs: [created.id]);
    });

    expect(created.isVerified, isFalse);
    final synced = await repository.syncFirebaseVerification(
      'firebase-profile-$unique',
      true,
    );
    expect(synced?.id, created.id);
    expect(synced?.role, 'passenger');
    expect(synced?.isVerified, isTrue);
  });

  test('Firebase false verification never un-verifies linked admin', () async {
    final unique = DateTime.now().microsecondsSinceEpoch;
    final now = DateTime.now().toIso8601String();
    final email = 'admin-sync-$unique@example.tn';
    final id = await repository.registerUser(
      User(
        fullName: 'Admin test',
        email: email,
        passwordHash: 'legacy-hash',
        role: 'admin',
        isVerified: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    addTearDown(() async {
      final db = await DatabaseHelper.instance.database;
      await db.delete('users', where: 'id = ?', whereArgs: [id]);
    });

    final linked = await repository.linkAuthenticatedEmailAccount(
      userId: id,
      email: email,
      firebaseUid: 'firebase-admin-$unique',
      emailVerified: false,
    );
    final synced = await repository.syncFirebaseVerification(
      'firebase-admin-$unique',
      false,
    );

    expect(linked.isVerified, isTrue);
    expect(synced?.role, 'admin');
    expect(synced?.isVerified, isTrue);
  });

  test(
    'links authenticated legacy profile without changing role or row ID',
    () async {
      final unique = DateTime.now().microsecondsSinceEpoch;
      final now = DateTime.now().toIso8601String();
      final email = 'legacy-link-$unique@example.tn';
      final id = await repository.registerUser(
        User(
          fullName: 'Legacy Driver',
          email: email,
          passwordHash: hashPassword('legacy-pass-123'),
          role: 'driver',
          isVerified: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      addTearDown(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('users', where: 'id = ?', whereArgs: [id]);
      });

      final linked = await repository.linkAuthenticatedEmailAccount(
        userId: id,
        email: email,
        firebaseUid: 'firebase-legacy-$unique',
        emailVerified: false,
      );
      expect(linked.id, id);
      expect(linked.role, 'driver');
      expect(linked.firebaseUid, 'firebase-legacy-$unique');
      expect(linked.passwordHash, isEmpty);
      expect(linked.isVerified, isFalse);
    },
  );
}
