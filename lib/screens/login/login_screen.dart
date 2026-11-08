import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;

import '../../auth/auth_coordinator.dart';
import '../../auth/auth_navigation.dart';
import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../../services/firebase_auth_service.dart';
import '../register/register_screen.dart';
import '../verification/email_verification_screen.dart';
import '../welcome/welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);

  void _returnToPreviousScreen() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  void _handleSystemBack(bool didPop) {
    if (!didPop && !Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  // ==========================================================
  // REPOSITORY
  // ==========================================================

  final UserRepository _userRepository = UserRepository();
  final AuthCoordinator _authCoordinator = AuthCoordinator();

  // ==========================================================
  // STATES
  // ==========================================================

  bool obscurePassword = true;
  bool isLoggingIn = false;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ==========================================================
  // PASSWORD HASH
  // ==========================================================

  // ==========================================================
  // EMAIL VALIDATION
  // ==========================================================

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return emailRegex.hasMatch(email);
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> _login() async {
    if (isLoggingIn) return;
    final email = emailController.text.trim().toLowerCase();

    final password = passwordController.text;

    // ----------------------------------------------------------
    // EMPTY FIELDS
    // ----------------------------------------------------------

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Veuillez remplir tous les champs.');
      return;
    }

    // ----------------------------------------------------------
    // EMAIL
    // ----------------------------------------------------------

    if (!_isValidEmail(email)) {
      _showMessage('Veuillez saisir une adresse email valide.');
      return;
    }

    setState(() {
      isLoggingIn = true;
    });

    try {
      final User user = await _authCoordinator.signInWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      setState(() {
        isLoggingIn = false;
      });

      await _showLoginSuccessOverlay();
      if (!mounted) return;
      navigateToRoleShell(context, user);
    } catch (e) {
      if (!mounted) return;

      if (e is AuthFlowException && e.error == AuthFlowError.emailNotVerified) {
        final user = await _userRepository.findUserByEmail(email);
        if (!mounted) return;
        if (user?.id != null && user?.firebaseUid != null && mounted) {
          setState(() => isLoggingIn = false);
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EmailVerificationScreen(
                email: email,
                userId: user!.id!,
                firebaseUid: user.firebaseUid!,
              ),
            ),
          );
          return;
        }
      }

      setState(() {
        isLoggingIn = false;
      });

      _showMessage(_loginErrorMessage(e));

      debugPrint('Échec de connexion e-mail/mot de passe.');
    }
  }

  String _loginErrorMessage(Object error) {
    if (error is AuthFlowException) {
      return switch (error.error) {
        AuthFlowError.invalidCredentials => 'E-mail ou mot de passe incorrect.',
        AuthFlowError.inactiveAccount => 'Ce compte a été désactivé.',
        AuthFlowError.accountConflict =>
          'Ce compte Firebase ne correspond pas au profil local.',
        AuthFlowError.emailNotVerified =>
          'Vérifiez votre adresse e-mail avant de vous connecter.',
        _ => 'Connexion impossible. Réessayez.',
      };
    }
    final code = error is FirebaseAuthException ? error.code : '';
    return switch (code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'E-mail ou mot de passe incorrect.',
      'network-request-failed' =>
        'Réseau indisponible. Vérifiez votre connexion.',
      'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
      'user-disabled' => 'Ce compte Firebase a été désactivé.',
      _ => 'Une erreur est survenue lors de la connexion.',
    };
  }

  Future<void> _forgotPassword() async {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final email = await showDialog<String>(
      context: context,
      builder: (_) =>
          _ForgotPasswordDialog(initialEmail: emailController.text.trim()),
    );
    if (email == null || !mounted) return;
    if (!emailRegex.hasMatch(email)) {
      _showMessage('Veuillez saisir une adresse e-mail valide.');
      return;
    }
    try {
      final localUser = await _userRepository.findUserByEmail(email);
      if (!mounted) return;
      if (localUser != null && localUser.firebaseUid == null) {
        if (mounted) {
          _showMessage(
            'Ancien compte détecté. Connectez-vous une fois avec votre mot de passe actuel pour activer sa migration, puis demandez la réinitialisation.',
          );
        }
        return;
      }
      await _authCoordinator.sendPasswordResetEmail(email);
      if (mounted)
        _showMessage(
          'Si un compte correspond à cette adresse, un lien de réinitialisation a été envoyé.',
        );
    } catch (error) {
      if (!mounted) return;
      final code = error is FirebaseAuthException ? error.code : '';
      _showMessage(switch (code) {
        'invalid-email' => 'Cette adresse e-mail est invalide.',
        'network-request-failed' =>
          'Réseau indisponible. Vérifiez votre connexion.',
        'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
        _ => 'Impossible d’envoyer le lien. Vérifiez l’adresse et réessayez.',
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (isLoggingIn) return;
    setState(() => isLoggingIn = true);

    GoogleAuthIdentity? identity;
    try {
      identity = await _authCoordinator.signInWithGoogle();
      if (identity == null) return;
      if (!mounted) {
        await _authCoordinator.signOut();
        return;
      }

      final resolution = await _authCoordinator.resolveGoogleIdentity(identity);
      if (!mounted) {
        await _authCoordinator.signOut();
        return;
      }
      User? user;

      if (resolution.status == GoogleProfileStatus.authenticated) {
        user = resolution.user;
      } else if (resolution.status == GoogleProfileStatus.linkExistingAccount) {
        final existingUser = resolution.user!;
        final password = await _askExistingAccountPassword(existingUser);
        if (!mounted) {
          await _authCoordinator.signOut();
          return;
        }
        if (password == null) {
          await _authCoordinator.signOut();
          return;
        }
        user = await _authCoordinator.linkExistingAccount(
          identity: identity,
          existingUser: existingUser,
          password: password,
        );
      } else if (resolution.status == GoogleProfileStatus.createNewAccount) {
        final profile = await _askNewGoogleProfile(identity);
        if (!mounted) {
          await _authCoordinator.signOut();
          return;
        }
        if (profile == null) {
          await _authCoordinator.signOut();
          return;
        }
        user = await _authCoordinator.createGoogleAccount(
          identity: identity,
          fullName: profile.fullName,
          role: profile.role,
        );
      } else {
        await _authCoordinator.signOut();
        if (mounted) _showMessage(_googleResolutionMessage(resolution.status));
        return;
      }

      if (user == null) {
        await _authCoordinator.signOut();
        if (mounted) _showMessage('Profil utilisateur introuvable.');
        return;
      }
      if (!mounted) {
        await _authCoordinator.signOut();
        return;
      }
      await _showLoginSuccessOverlay();
      if (!mounted) return;
      if (!navigateToRoleShell(context, user)) {
        await _authCoordinator.signOut();
        _showMessage('Le rôle de ce compte n’est pas reconnu.');
      }
    } catch (error) {
      try {
        await _authCoordinator.signOut();
      } catch (signOutError) {
        debugPrint('Échec de nettoyage Firebase : $signOutError');
      }
      if (mounted) _showMessage(_googleErrorMessage(error));
      debugPrint('Échec de connexion Google.');
    } finally {
      if (mounted) setState(() => isLoggingIn = false);
    }
  }

  Future<String?> _askExistingAccountPassword(User user) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExistingAccountPasswordDialog(email: user.email),
    );
  }

  Future<_GoogleProfileData?> _askNewGoogleProfile(
    GoogleAuthIdentity identity,
  ) async {
    return showDialog<_GoogleProfileData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NewGoogleProfileDialog(identity: identity),
    );
  }

  String _googleResolutionMessage(GoogleProfileStatus status) {
    switch (status) {
      case GoogleProfileStatus.inactive:
        return 'Ce compte a été désactivé.';
      case GoogleProfileStatus.conflict:
        return 'Cet e-mail ou cet UID Google est déjà associé à un autre compte.';
      case GoogleProfileStatus.invalidIdentity:
        return 'Le compte Google ne fournit pas une adresse e-mail valide.';
      case GoogleProfileStatus.unverified:
        return 'Google n’a pas confirmé cette adresse e-mail.';
      case GoogleProfileStatus.authenticated:
      case GoogleProfileStatus.linkExistingAccount:
      case GoogleProfileStatus.createNewAccount:
        return 'Impossible de résoudre le profil local.';
    }
  }

  String _googleErrorMessage(Object error) {
    if (error is AuthFlowException) {
      switch (error.error) {
        case AuthFlowError.invalidLocalPassword:
          return 'Mot de passe incorrect. Le compte n’a pas été associé.';
        case AuthFlowError.inactiveAccount:
          return 'Ce compte a été désactivé.';
        case AuthFlowError.accountConflict:
          return 'Ce compte Google est déjà associé à un autre profil.';
        case AuthFlowError.unverifiedGoogleEmail:
          return 'Google n’a pas confirmé cette adresse e-mail.';
        case AuthFlowError.invalidRole:
          return 'Le rôle choisi n’est pas autorisé.';
        case AuthFlowError.invalidIdentity:
          return 'Les informations du compte Google sont incomplètes.';
        case AuthFlowError.invalidCredentials:
          return 'E-mail ou mot de passe incorrect.';
        case AuthFlowError.emailNotVerified:
          return 'Vérifiez votre adresse e-mail avant de continuer.';
      }
    }
    final value = error.toString();
    if (value.contains('account-exists-with-different-credential')) {
      return 'Cette adresse utilise déjà une autre méthode de connexion.';
    }
    if (value.contains('network-request-failed')) {
      return 'Connexion réseau indisponible. Réessayez.';
    }
    return 'Connexion Google impossible. Vérifiez la configuration et réessayez.';
  }

  // ==========================================================
  // SUCCESS TRANSITION
  // ==========================================================

  Future<void> _showLoginSuccessOverlay() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: primaryBlue.withValues(alpha: 0.28),
      builder: (_) => const _LoginSuccessOverlay(),
    );
  }

  // ==========================================================
  // SHOW MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(
        icon,
        color: primaryBlue.withValues(alpha: 0.65),
        size: 21,
      ),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),

      labelStyle: const TextStyle(color: textGrey, fontWeight: FontWeight.w600),

      hintStyle: TextStyle(color: textGrey.withValues(alpha: 0.45)),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFFE0ECE7), width: 1.3),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: secondaryBlue, width: 1.8),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) => _handleSystemBack(didPop),
      child: Scaffold(
        backgroundColor: background,

        body: SafeArea(
          child: Stack(
            children: [
              // ========================================================
              // DECORATIVE BACKGROUND - TOP
              // ========================================================

              Positioned(
                top: -70,
                right: -55,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: secondaryBlue.withValues(alpha: 0.07),
                  ),
                ),
              ),

              // ========================================================
              // DECORATIVE BACKGROUND - BOTTOM
              // ========================================================
              Positioned(
                bottom: -90,
                left: -70,
                child: Container(
                  width: 190,
                  height: 190,
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
                    crossAxisAlignment: CrossAxisAlignment.start,

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

                              onTap: _returnToPreviousScreen,

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
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),

                      const SizedBox(height: 42),

                      // ==================================================
                      // HEADER
                      // ==================================================
                      const Text(
                        'Bon retour 👋',

                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Connectez-vous pour retrouver '
                        'vos trajets et votre communauté.',

                        style: TextStyle(
                          color: textGrey.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 34),

                      // ==================================================
                      // EMAIL
                      // ==================================================
                      const Text(
                        'Email universitaire',

                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: emailController,

                        keyboardType: TextInputType.emailAddress,

                        decoration: _inputDecoration(
                          label: 'Email universitaire',
                          hint: 'prenom.nom@universite.tn',
                          icon: Icons.school_outlined,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // PASSWORD
                      // ==================================================
                      const Text(
                        'Mot de passe',

                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: passwordController,

                        obscureText: obscurePassword,

                        onSubmitted: (_) {
                          _login();
                        },

                        decoration: _inputDecoration(
                          label: 'Mot de passe',
                          hint: 'Votre mot de passe',
                          icon: Icons.lock_outline_rounded,

                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },

                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textGrey,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // FORGOT PASSWORD
                      // ==================================================
                      Align(
                        alignment: Alignment.centerRight,

                        child: TextButton(
                          onPressed: _forgotPassword,

                          child: const Text(
                            'Mot de passe oublié ?',

                            style: TextStyle(
                              color: secondaryBlue,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // LOGIN BUTTON
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        height: 58,

                        child: ElevatedButton(
                          onPressed: isLoggingIn ? null : _login,

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

                          child: isLoggingIn
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
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    SizedBox(width: 10),

                                    Icon(Icons.arrow_forward_rounded, size: 21),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // DIVIDER
                      // ==================================================
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFD8E6E1),
                              thickness: 1,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),

                            child: Text(
                              'OU',

                              style: TextStyle(
                                color: textGrey.withValues(alpha: 0.55),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const Expanded(
                            child: Divider(
                              color: Color(0xFFD8E6E1),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // GOOGLE
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        height: 56,

                        child: OutlinedButton(
                          onPressed: isLoggingIn ? null : _signInWithGoogle,

                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryBlue,

                            side: const BorderSide(
                              color: Color(0xFFD5E5DF),
                              width: 1.4,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),

                          child: isLoggingIn
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: primaryBlue,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,

                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFE1E8E5),
                                        ),
                                      ),

                                      child: const Text(
                                        'G',

                                        style: TextStyle(
                                          color: Color(0xFF4285F4),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    const Text(
                                      'Continuer avec Google',

                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ==================================================
                      // REGISTER LINK
                      // ==================================================
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,

                          children: [
                            Text(
                              'Vous n’avez pas encore de compte ? ',

                              style: TextStyle(
                                color: textGrey.withValues(alpha: 0.78),
                                fontSize: 13,
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },

                              child: const Text(
                                'S’inscrire',

                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // SECURITY FOOTER
                      // ==================================================
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(
                              Icons.security_rounded,
                              size: 14,
                              color: textGrey.withValues(alpha: 0.55),
                            ),

                            const SizedBox(width: 6),

                            Text(
                              'Vos données restent protégées',

                              style: TextStyle(
                                color: textGrey.withValues(alpha: 0.55),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginSuccessOverlay extends StatefulWidget {
  const _LoginSuccessOverlay();

  @override
  State<_LoginSuccessOverlay> createState() => _LoginSuccessOverlayState();
}

class _LoginSuccessOverlayState extends State<_LoginSuccessOverlay> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color green = Color(0xFF20B978);
  static const Color textGrey = Color(0xFF547080);

  late final Timer _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _dismissTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: green,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Connexion réussie',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Redirection vers votre espace...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  label: 'Redirection en cours',
                  child: SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleProfileData {
  final String fullName;
  final String role;

  const _GoogleProfileData({required this.fullName, required this.role});
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Réinitialiser le mot de passe'),
    content: TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Adresse e-mail'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _emailController.text.trim()),
        child: const Text('Envoyer'),
      ),
    ],
  );
}

class _ExistingAccountPasswordDialog extends StatefulWidget {
  const _ExistingAccountPasswordDialog({required this.email});

  final String email;

  @override
  State<_ExistingAccountPasswordDialog> createState() =>
      _ExistingAccountPasswordDialogState();
}

class _ExistingAccountPasswordDialogState
    extends State<_ExistingAccountPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Associer votre compte'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Un compte existe déjà pour ${widget.email}. '
          'Saisissez son mot de passe pour conserver votre profil et votre rôle.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          autofocus: true,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Mot de passe actuel',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            ),
          ),
          onSubmitted: (_) => Navigator.pop(context, _passwordController.text),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _passwordController.text),
        child: const Text('Vérifier et associer'),
      ),
    ],
  );
}

class _NewGoogleProfileDialog extends StatefulWidget {
  const _NewGoogleProfileDialog({required this.identity});

  final GoogleAuthIdentity identity;

  @override
  State<_NewGoogleProfileDialog> createState() =>
      _NewGoogleProfileDialogState();
}

class _NewGoogleProfileDialogState extends State<_NewGoogleProfileDialog> {
  late final TextEditingController _nameController;
  String _role = 'passenger';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.identity.displayName?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Compléter votre profil'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom complet'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.identity.email ?? ''),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _role,
          decoration: const InputDecoration(labelText: 'Votre rôle'),
          items: const [
            DropdownMenuItem(value: 'passenger', child: Text('Passager')),
            DropdownMenuItem(value: 'driver', child: Text('Conducteur')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _role = value);
          },
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () {
          final fullName = _nameController.text.trim();
          if (fullName.length < 3) return;
          Navigator.pop(
            context,
            _GoogleProfileData(fullName: fullName, role: _role),
          );
        },
        child: const Text('Continuer'),
      ),
    ],
  );
}
