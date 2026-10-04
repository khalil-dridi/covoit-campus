import 'package:flutter/material.dart';
import '../login/login_screen.dart';
import '../verification/email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // ==========================================================
  // STATES
  // ==========================================================
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool acceptedTerms = false;

  // ==========================================================
  // DISPOSE
  // ==========================================================
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================================
  // CHECK FORM
  // ==========================================================
  bool get canSubmit {
    return nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        acceptedTerms;
  }

  // ==========================================================
  // CREATE ACCOUNT
  // ==========================================================
  void _createAccount() {
  if (!canSubmit) {
    return;
  }

  if (passwordController.text != confirmPasswordController.text) {
    _showMessage(
      'Les mots de passe ne correspondent pas.',
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EmailVerificationScreen(
        email: emailController.text.trim(),
      ),
    ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),

      labelStyle: const TextStyle(
        color: textGrey,
        fontWeight: FontWeight.w600,
      ),

      hintStyle: TextStyle(
        color: textGrey.withValues(alpha: 0.45),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: Color(0xFFE0ECE7),
          width: 1.3,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: secondaryBlue,
          width: 1.8,
        ),
      ),
    );
  }

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
                padding: const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  30,
                ),

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
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // HEADER
                    // ==================================================
                    const Text(
                      'Créer un compte',

                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Rejoignez la communauté Covoit Campus '
                      'et partagez vos trajets en toute confiance.',

                      style: TextStyle(
                        color: textGrey.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // NAME
                    // ==================================================
                    const Text(
                      'Nom complet',

                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: nameController,

                      onChanged: (_) {
                        setState(() {});
                      },

                      textCapitalization: TextCapitalization.words,

                      decoration: _inputDecoration(
                        label: 'Nom complet',
                        hint: 'Ex. Khalil Dridi',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),

                    const SizedBox(height: 18),

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

                      onChanged: (_) {
                        setState(() {});
                      },

                      keyboardType: TextInputType.emailAddress,

                      decoration: _inputDecoration(
                        label: 'Email universitaire',
                        hint: 'prenom.nom@universite.tn',
                        icon: Icons.school_outlined,
                      ),
                    ),

                    const SizedBox(height: 18),

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

                      onChanged: (_) {
                        setState(() {});
                      },

                      obscureText: obscurePassword,

                      decoration: _inputDecoration(
                        label: 'Mot de passe',
                        hint: 'Au moins 8 caractères',
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

                    const SizedBox(height: 18),

                    // ==================================================
                    // CONFIRM PASSWORD
                    // ==================================================
                    const Text(
                      'Confirmer le mot de passe',

                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: confirmPasswordController,

                      onChanged: (_) {
                        setState(() {});
                      },

                      obscureText: obscureConfirmPassword,

                      decoration: _inputDecoration(
                        label: 'Confirmation',
                        hint: 'Retapez votre mot de passe',
                        icon: Icons.lock_outline_rounded,

                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },

                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: textGrey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // PASSWORD INFO
                    // ==================================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: secondaryBlue,
                        ),

                        const SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            'Utilisez au moins 8 caractères avec une '
                            'combinaison de lettres et de chiffres.',

                            style: TextStyle(
                              color: textGrey.withValues(alpha: 0.78),
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // TERMS
                    // ==================================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Checkbox(
                          value: acceptedTerms,

                          activeColor: green,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),

                          onChanged: (value) {
                            setState(() {
                              acceptedTerms = value ?? false;
                            });
                          },
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),

                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 12,
                                  height: 1.4,
                                ),

                                children: [
                                  TextSpan(
                                    text: 'J’accepte les ',
                                  ),

                                  TextSpan(
                                    text: 'conditions d’utilisation',

                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  TextSpan(
                                    text: ' et la ',
                                  ),

                                  TextSpan(
                                    text: 'politique de confidentialité',

                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  TextSpan(
                                    text: '.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // CREATE ACCOUNT
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 58,

                      child: ElevatedButton(
                        onPressed: canSubmit
                            ? _createAccount
                            : null,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,

                          disabledBackgroundColor:
                              green.withValues(alpha: 0.35),

                          foregroundColor: Colors.white,

                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.8),

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),

                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Text(
                              'Créer mon compte',

                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            SizedBox(width: 10),

                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),

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
                        onPressed: () {
                          _showMessage(
                            'Inscription Google disponible prochainement.',
                          );
                        },

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

                        child: Row(
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

                    const SizedBox(height: 24),

                    // ==================================================
                    // LOGIN LINK
                    // ==================================================
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,

                        children: [
                          Text(
                            'Vous avez déjà un compte ? ',

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
                                      const LoginScreen(),
                                ),
                              );
                            },

                            child: const Text(
                              'Se connecter',

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
                    // FOOTER
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
    );
  }
}