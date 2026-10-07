import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../register/register_screen.dart';

import '../passenger/passenger_shell.dart';
import '../driver/driver_shell.dart';
import '../admin/admin_shell.dart';
import '../../utils/password_hasher.dart';

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

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // ==========================================================
  // REPOSITORY
  // ==========================================================

  final UserRepository _userRepository =
      UserRepository();

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
    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> _login() async {
    final email =
        emailController.text.trim().toLowerCase();

    final password = passwordController.text;

    // ----------------------------------------------------------
    // EMPTY FIELDS
    // ----------------------------------------------------------

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Veuillez remplir tous les champs.',
      );
      return;
    }

    // ----------------------------------------------------------
    // EMAIL
    // ----------------------------------------------------------

    if (!_isValidEmail(email)) {
      _showMessage(
        'Veuillez saisir une adresse email valide.',
      );
      return;
    }

    setState(() {
      isLoggingIn = true;
    });

    try {
      // --------------------------------------------------------
      // FIND USER
      // --------------------------------------------------------

      final User? user =
          await _userRepository.findUserByEmail(email);

      if (!mounted) return;

      if (user == null) {
        setState(() {
          isLoggingIn = false;
        });

        _showMessage(
          'Aucun compte associé à cette adresse email.',
        );

        return;
      }

      // --------------------------------------------------------
      // ACTIVE ACCOUNT
      // --------------------------------------------------------

      if (!user.isActive) {
        setState(() {
          isLoggingIn = false;
        });

        _showMessage(
          'Ce compte a été désactivé.',
        );

        return;
      }

      // --------------------------------------------------------
      // PASSWORD
      // --------------------------------------------------------

      final passwordHash = hashPassword(password);

      if (passwordHash != user.passwordHash) {
        setState(() {
          isLoggingIn = false;
        });

        _showMessage(
          'Email ou mot de passe incorrect.',
        );

        return;
      }

      // --------------------------------------------------------
      // EMAIL VERIFIED
      // --------------------------------------------------------

      if (!user.isVerified) {
        setState(() {
          isLoggingIn = false;
        });

        _showMessage(
          'Veuillez vérifier votre adresse email '
          'avant de vous connecter.',
        );

        return;
      }

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      setState(() {
        isLoggingIn = false;
      });

      _showLoginSuccessDialog(user);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoggingIn = false;
      });

      _showMessage(
        'Une erreur est survenue lors de la connexion.',
      );

      debugPrint(
        'Erreur login : $e',
      );
    }
  }

  // ==========================================================
  // SUCCESS DIALOG
  // ==========================================================

  void _showLoginSuccessDialog(User user) {
    final bool isDriver = user.role == 'driver';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding:
              const EdgeInsets.all(28),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color:
                      green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDriver
                      ? Icons.directions_car_rounded
                      : Icons.backpack_rounded,
                  color: green,
                  size: 38,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Connexion réussie !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Bienvenue ${user.fullName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                isDriver
                    ? 'Vous êtes connecté en tant que conducteur.'
                    : 'Vous êtes connecté en tant que passager.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      textGrey.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
  Navigator.pop(context);

  if (user.role == 'passenger') {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerShell(
  user: user,
),
      ),
      (route) => false,
    );
  } else if (user.role == 'driver') {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => DriverShell(user: user),
      ),
      (route) => false,
    );
  } else if (user.role == 'admin') {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => AdminShell(user: user),
      ),
      (route) => false,
    );
  }
},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
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
  // SHOW MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
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
        color:
            primaryBlue.withValues(alpha: 0.65),
        size: 21,
      ),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),

      labelStyle:
          const TextStyle(
        color: textGrey,
        fontWeight: FontWeight.w600,
      ),

      hintStyle: TextStyle(
        color:
            textGrey.withValues(alpha: 0.45),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(17),
        borderSide:
            const BorderSide(
          color: Color(0xFFE0ECE7),
          width: 1.3,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(17),
        borderSide:
            const BorderSide(
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
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color: secondaryBlue
                      .withValues(alpha: 0.07),
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
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color: green
                      .withValues(alpha: 0.08),
                ),
              ),
            ),

            // ========================================================
            // CONTENT
            // ========================================================

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),

              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  30,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // ==================================================
                    // TOP BAR
                    // ==================================================

                    Row(
                      children: [
                        Material(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(14),

                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(14),

                            onTap: () {
                              Navigator.pop(
                                context,
                              );
                            },

                            child:
                                const SizedBox(
                              width: 46,
                              height: 46,

                              child: Icon(
                                Icons
                                    .arrow_back_rounded,
                                color:
                                    primaryBlue,
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

                    const SizedBox(
                      height: 42,
                    ),

                    // ==================================================
                    // HEADER
                    // ==================================================

                    const Text(
                      'Bon retour 👋',

                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 32,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Connectez-vous pour retrouver '
                      'vos trajets et votre communauté.',

                      style: TextStyle(
                        color: textGrey.withValues(
                          alpha: 0.9,
                        ),
                        fontSize: 15,
                        height: 1.5,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(
                      height: 34,
                    ),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    const Text(
                      'Email universitaire',

                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    TextField(
                      controller:
                          emailController,

                      keyboardType:
                          TextInputType
                              .emailAddress,

                      decoration:
                          _inputDecoration(
                        label:
                            'Email universitaire',
                        hint:
                            'prenom.nom@universite.tn',
                        icon:
                            Icons.school_outlined,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    const Text(
                      'Mot de passe',

                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    TextField(
                      controller:
                          passwordController,

                      obscureText:
                          obscurePassword,

                      onSubmitted: (_) {
                        _login();
                      },

                      decoration:
                          _inputDecoration(
                        label:
                            'Mot de passe',
                        hint:
                            'Votre mot de passe',
                        icon:
                            Icons
                                .lock_outline_rounded,

                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
                            });
                          },

                          icon: Icon(
                            obscurePassword
                                ? Icons
                                    .visibility_off_outlined
                                : Icons
                                    .visibility_outlined,
                            color:
                                textGrey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // FORGOT PASSWORD
                    // ==================================================

                    Align(
                      alignment:
                          Alignment.centerRight,

                      child:
                          TextButton(
                        onPressed: () {
                          _showMessage(
                            'La récupération du mot '
                            'de passe sera ajoutée prochainement.',
                          );
                        },

                        child: const Text(
                          'Mot de passe oublié ?',

                          style:
                              TextStyle(
                            color:
                                secondaryBlue,
                            fontSize: 12.5,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 58,

                      child:
                          ElevatedButton(
                        onPressed:
                            isLoggingIn
                                ? null
                                : _login,

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              green,

                          disabledBackgroundColor:
                              green.withValues(
                            alpha: 0.45,
                          ),

                          foregroundColor:
                              Colors.white,

                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                        ),

                        child:
                            isLoggingIn
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child:
                                        CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth:
                                          2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      Text(
                                        'Se connecter',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              16,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),

                                      SizedBox(
                                        width: 10,
                                      ),

                                      Icon(
                                        Icons
                                            .arrow_forward_rounded,
                                        size: 21,
                                      ),
                                    ],
                                  ),
                      ),
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==================================================
                    // DIVIDER
                    // ==================================================

                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color:
                                Color(
                              0xFFD8E6E1,
                            ),
                            thickness: 1,
                          ),
                        ),

                        Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 14,
                          ),

                          child:
                              Text(
                            'OU',

                            style:
                                TextStyle(
                              color:
                                  textGrey
                                      .withValues(
                                alpha:
                                    0.55,
                              ),
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),

                        const Expanded(
                          child: Divider(
                            color:
                                Color(
                              0xFFD8E6E1,
                            ),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // GOOGLE
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 56,

                      child:
                          OutlinedButton(
                        onPressed: () {
                          _showMessage(
                            'Connexion Google disponible '
                            'prochainement.',
                          );
                        },

                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              primaryBlue,

                          side:
                              const BorderSide(
                            color:
                                Color(
                              0xFFD5E5DF,
                            ),
                            width: 1.4,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment:
                                  Alignment.center,

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                shape:
                                    BoxShape
                                        .circle,
                                border:
                                    Border.all(
                                  color:
                                      const Color(
                                    0xFFE1E8E5,
                                  ),
                                ),
                              ),

                              child:
                                  const Text(
                                'G',

                                style:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFF4285F4,
                                  ),
                                  fontSize:
                                      15,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            const Text(
                              'Continuer avec Google',

                              style:
                                  TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    // ==================================================
                    // REGISTER LINK
                    // ==================================================

                    Center(
                      child:
                          Wrap(
                        alignment:
                            WrapAlignment
                                .center,

                        children: [
                          Text(
                            'Vous n’avez pas encore de compte ? ',

                            style:
                                TextStyle(
                              color:
                                  textGrey
                                      .withValues(
                                alpha:
                                    0.78,
                              ),
                              fontSize:
                                  13,
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const RegisterScreen(),
                                ),
                              );
                            },

                            child:
                                const Text(
                              'S’inscrire',

                              style:
                                  TextStyle(
                                color:
                                    primaryBlue,
                                fontSize:
                                    13,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // ==================================================
                    // SECURITY FOOTER
                    // ==================================================

                    Center(
                      child:
                          Row(
                        mainAxisSize:
                            MainAxisSize
                                .min,

                        children: [
                          Icon(
                            Icons
                                .security_rounded,
                            size: 14,
                            color:
                                textGrey
                                    .withValues(
                              alpha:
                                  0.55,
                            ),
                          ),

                          const SizedBox(
                            width: 6,
                          ),

                          Text(
                            'Vos données restent protégées',

                            style:
                                TextStyle(
                              color:
                                  textGrey
                                      .withValues(
                                alpha:
                                    0.55,
                              ),
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight
                                      .w600,
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
