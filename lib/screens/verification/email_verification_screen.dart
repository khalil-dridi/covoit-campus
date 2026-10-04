import 'dart:async';

import 'package:flutter/material.dart';

import '../../repositories/user_repository.dart';
import '../login/login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    this.email = 'votre adresse email',
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
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

  final List<TextEditingController> _controllers =
      List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes =
      List.generate(
    6,
    (_) => FocusNode(),
  );

  final UserRepository _userRepository =
      UserRepository();

  // ==========================================================
  // STATES
  // ==========================================================

  Timer? _timer;

  int _secondsRemaining = 45;

  bool _isVerifying = false;

  // Code temporaire de démonstration
  static const String demoCode = '123456';

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  // ==========================================================
  // TIMER
  // ==========================================================

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 45;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  // ==========================================================
  // CODE
  // ==========================================================

  String get _enteredCode {
    return _controllers.map((controller) {
      return controller.text;
    }).join();
  }

  void _onCodeChanged(
    String value,
    int index,
  ) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  // ==========================================================
  // VERIFY CODE
  // ==========================================================

  Future<void> _verifyCode() async {
    if (_enteredCode.length != 6) {
      _showMessage(
        'Veuillez saisir les 6 chiffres du code.',
      );
      return;
    }

    if (_enteredCode != demoCode) {
      _showMessage(
        'Code incorrect. Utilisez le code de test 123456.',
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final user =
          await _userRepository.findUserByEmail(
        widget.email.trim().toLowerCase(),
      );

      if (user == null || user.id == null) {
        if (!mounted) return;

        setState(() {
          _isVerifying = false;
        });

        _showMessage(
          'Utilisateur introuvable.',
        );

        return;
      }

      await _userRepository.verifyUser(user.id!);

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showMessage(
        'Une erreur est survenue lors de la vérification.',
      );

      debugPrint(
        'Erreur vérification email : $e',
      );
    }
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
                child: const Icon(
                  Icons.check_rounded,
                  color: green,
                  size: 42,
                ),
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
                style: TextStyle(
                  color: textGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
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
                        builder: (context) =>
                            const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
  // RESEND CODE
  // ==========================================================

  void _resendCode() {
    if (_secondsRemaining > 0) {
      return;
    }

    for (final controller in _controllers) {
      controller.clear();
    }

    _focusNodes[0].requestFocus();

    _startTimer();

    _showMessage(
      'Un nouveau code de test a été généré.',
    );
  }

  // ==========================================================
  // EDIT EMAIL
  // ==========================================================

  void _editEmail() {
    Navigator.pop(context);
  }

  // ==========================================================
  // MESSAGE
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
  // OTP BOX
  // ==========================================================

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 58,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,

        style: const TextStyle(
          color: primaryBlue,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),

        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFFE0ECE7),
              width: 1.3,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: secondaryBlue,
              width: 2,
            ),
          ),
        ),

        onChanged: (value) {
          _onCodeChanged(value, index);
        },
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
                  color: secondaryBlue.withValues(
                    alpha: 0.07,
                  ),
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
                  color: green.withValues(
                    alpha: 0.08,
                  ),
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
                padding: const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  30,
                ),

                child: Column(
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
                              Navigator.pop(context);
                            },

                            child: const SizedBox(
                              width: 46,
                              height: 46,

                              child: Icon(
                                Icons
                                    .arrow_back_rounded,
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
                        color: green.withValues(
                          alpha: 0.1,
                        ),
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
                      'Nous avons envoyé un code de '
                      'vérification à',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textGrey.withValues(
                          alpha: 0.85,
                        ),
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

                    // ==================================================
                    // OTP
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) =>
                            _buildOtpBox(index),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // VERIFY BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isVerifying
                            ? null
                            : _verifyCode,

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: green,
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
                                BorderRadius.circular(18),
                          ),
                        ),

                        child: _isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Vérifier mon email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons
                                        .check_circle_outline,
                                    size: 21,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // TIMER / RESEND
                    // ==================================================

                    if (_secondsRemaining > 0)
                      Text(
                        'Vous pouvez demander un nouveau code '
                        'dans $_secondsRemaining s',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textGrey.withValues(
                            alpha: 0.75,
                          ),
                          fontSize: 12,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _resendCode,
                        child: const Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // EDIT EMAIL
                    // ==================================================

                    TextButton.icon(
                      onPressed: _editEmail,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                      ),
                      label: const Text(
                        'Modifier mon adresse email',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: textGrey,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // TEST CODE CARD
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(
                            0xFFE0ECE7,
                          ),
                        ),
                      ),

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const Icon(
                            Icons.science_outlined,
                            color: secondaryBlue,
                            size: 22,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mode développement',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  'Code de test : $demoCode',
                                  style: const TextStyle(
                                    color: textGrey,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  'L’envoi réel d’email sera ajouté '
                                  'ultérieurement.',
                                  style: TextStyle(
                                    color:
                                        textGrey.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // SECURITY
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 15,
                          color: textGrey.withValues(
                            alpha: 0.5,
                          ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          'Votre compte est protégé',
                          style: TextStyle(
                            color:
                                textGrey.withValues(
                              alpha: 0.55,
                            ),
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
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