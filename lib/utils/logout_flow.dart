import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import '../screens/login/login_screen.dart';

class LogoutFlow {
  LogoutFlow._();

  static const Color _primaryBlue = Color(0xFF123D68);
  static const Color _textGrey = Color(0xFF547080);
  static const Color _logoutColor = Color(0xFFD87532);

  static bool _isActive = false;

  static Future<void> confirmAndLogout(BuildContext context) async {
    if (_isActive) return;
    _isActive = true;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.logout_rounded, color: _logoutColor),
          title: const Text(
            'Se déconnecter ?',
            style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de votre compte ?',
            style: TextStyle(color: _textGrey, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: _logoutColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      );

      if (!context.mounted || confirmed != true) return;

      try {
        await FirebaseAuthService().signOut();
      } catch (error) {
        debugPrint('Firebase sign-out failed: $error');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La session distante n’a pas pu être effacée. Réessayez.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } finally {
      _isActive = false;
    }
  }
}
