import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Shared password hashing used by registration, login, and password updates.
String hashPassword(String password) =>
    sha256.convert(utf8.encode(password)).toString();
