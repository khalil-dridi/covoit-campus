import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';

import '../../auth/auth_coordinator.dart';
import '../login/login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final int userId;
  final String firebaseUid;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.userId,
    required this.firebaseUid,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final AuthCoordinator _authCoordinator = AuthCoordinator();

  // ==========================================================
  // STATES
  // ==========================================================

  bool _isVerifying = false;
  bool _isSending = false;
  bool _verified = false;
  String? _message;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _sendVerificationEmail(),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _verifyEmailStatus();
  }

  Future<void> _sendVerificationEmail({bool showSuccess = true}) async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _message = null;
    });
    try {
      await _authCoordinator.sendVerificationEmail(
        expectedUid: widget.firebaseUid,
      );
      if (mounted && showSuccess)
        setState(() => _message = 'E-mail de vérification envoyé.');
    } catch (error) {
      if (mounted) setState(() => _message = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyEmailStatus() async {
    if (_isVerifying || _verified) return;
    setState(() {
      _isVerifying = true;
      _message = null;
    });
    try {
      final user = await _authCoordinator.refreshVerification(
        userId: widget.userId,
      );
      if (!mounted) return;
      if (user?.isVerified == true) {
        _verified = true;
        await _authCoordinator.signOut();
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        setState(
          () => _message = 'Adresse toujours en attente. Ouvrez le lien reçu, puis réessayez.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = _errorMessage(e));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  String _errorMessage(Object error) {
    final code = error is FirebaseAuthException ? error.code : '';
    return switch (code) {
      'network-request-failed' =>
        'Réseau indisponible. Vérifiez votre connexion.',
      'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
      _ => 'Impossible de contacter Firebase. Réessayez.',
    };
  }

  // ==========================================================
  // SUCCESS DIALOG
  // ==========================================================

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: green, size: 42),
              ),

              const SizedBox(height: 20),

              const Text(
                'Email vérifié !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Votre compte a été vérifié avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textGrey, fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // RESEND CODE
  // ==========================================================

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Stack(
          children: [
            // ========================================================
            // BACKGROUND
            // ========================================================

            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondaryBlue.withValues(alpha: 0.07),
                ),
              ),
            ),

            Positioned(
              bottom: -80,
              left: -70,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: green.withValues(alpha: 0.08),
                ),
              ),
            ),

            // ========================================================
            // CONTENT
            // ========================================================
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),

                child: Column(
                  children: [
                    // ==================================================
                    // TOP BAR
                    // ==================================================

                    Row(
                      children: [
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),

                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),

                            onTap: () {
                              Navigator.pop(context);
                            },

                            child: const SizedBox(
                              width: 46,
                              height: 46,

                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        Image.asset(
                          'assets/images/logo.png',
                          width: 52,
                          height: 52,
                        ),
                      ],
                    ),

                    const SizedBox(height: 45),

                    // ==================================================
                    // ICON
                    // ==================================================
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: green,
                        size: 42,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // TITLE
                    // ==================================================
                    const Text(
                      'Vérifiez votre email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Adresse à vérifier :',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textGrey.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 36),

                    const SizedBox(height: 28),

                    if (_message != null) ...[
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textGrey, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyEmailStatus,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          disabledBackgroundColor: green.withValues(
                            alpha: 0.45,
                          ),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),

                        child: _isVerifying || _isSending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'J’ai vérifié mon adresse',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.check_circle_outline, size: 21),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: _isSending
                          ? null
                          : () => _sendVerificationEmail(),
                      child: Text(_isSending ? 'Envoi…' : 'Renvoyer l’e-mail'),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // EDIT EMAIL
                    // ==================================================
                    TextButton.icon(
                      onPressed: () async {
                        await _authCoordinator.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(),
                          ),
                          (_) => false,
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Revenir à la connexion'),
                      style: TextButton.styleFrom(foregroundColor: textGrey),
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(height: 24),

                    // ==================================================
                    // SECURITY
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 15,
                          color: textGrey.withValues(alpha: 0.5),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          'Votre compte est protégé',
                          style: TextStyle(
                            color: textGrey.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
