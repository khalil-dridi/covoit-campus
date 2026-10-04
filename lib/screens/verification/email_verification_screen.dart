import 'dart:async';

import 'package:flutter/material.dart';

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
  // OTP
  // ==========================================================
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 45;
  Timer? _timer;

  // ==========================================================
  // LIFECYCLE
  // ==========================================================
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
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
        if (_secondsRemaining == 0) {
          timer.cancel();
        } else {
          setState(() {
            _secondsRemaining--;
          });
        }
      },
    );
  }

  // ==========================================================
  // OTP VALUE
  // ==========================================================
  String get _otp {
    return _controllers.map((controller) => controller.text).join();
  }

  bool get _isOtpComplete {
    return _otp.length == 6;
  }

  // ==========================================================
  // VERIFY
  // ==========================================================
  void _verifyCode() {
    if (!_isOtpComplete) {
      _showMessage('Veuillez saisir les 6 chiffres du code.');
      return;
    }

    _showMessage('Code vérifié avec succès.');
  }

  // ==========================================================
  // RESEND
  // ==========================================================
  void _resendCode() {
    if (_secondsRemaining > 0) {
      return;
    }

    for (final controller in _controllers) {
      controller.clear();
    }

    _focusNodes.first.requestFocus();

    _startTimer();

    _showMessage('Un nouveau code a été envoyé.');
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
  // OTP FIELD
  // ==========================================================
  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          color: primaryBlue,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFDCEAE5),
              width: 1.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: green,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }

          setState(() {});
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
            // DECORATIVE BACKGROUND
            // ========================================================
            Positioned(
              top: -80,
              right: -65,
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
              bottom: -100,
              left: -80,
              child: Container(
                width: 210,
                height: 210,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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

                    const SizedBox(height: 48),

                    // ==================================================
                    // EMAIL ICON
                    // ==================================================
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.08),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.11),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          size: 42,
                          color: green,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // TITLE
                    // ==================================================
                    const Text(
                      'Vérifiez votre email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================
                    Text(
                      'Nous avons envoyé un code de vérification '
                      'à votre adresse email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textGrey.withValues(alpha: 0.88),
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // EMAIL
                    // ==================================================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFE0ECE7),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: secondaryBlue,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            widget.email,
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 38),

                    // ==================================================
                    // OTP TITLE
                    // ==================================================
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Code de vérification',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // OTP BOXES
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) => _buildOtpField(index),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // TIMER
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: textGrey.withValues(alpha: 0.65),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _secondsRemaining > 0
                              ? 'Renvoyer le code dans '
                                  '00:${_secondsRemaining.toString().padLeft(2, '0')}'
                              : 'Vous pouvez renvoyer le code',
                          style: TextStyle(
                            color: textGrey.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // RESEND
                    // ==================================================
                    TextButton(
                      onPressed:
                          _secondsRemaining == 0 ? _resendCode : null,
                      child: Text(
                        'Renvoyer le code',
                        style: TextStyle(
                          color: _secondsRemaining == 0
                              ? secondaryBlue
                              : textGrey.withValues(alpha: 0.35),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // VERIFY BUTTON
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isOtpComplete
                            ? _verifyCode
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
                              'Vérifier mon email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.verified_rounded,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // EDIT EMAIL
                    // ==================================================
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Modifier mon adresse email',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // SECURITY CARD
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE1ECE8),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: secondaryBlue.withValues(alpha: 0.09),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: secondaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pourquoi cette vérification ?',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Elle nous permet de confirmer votre '
                                  'adresse et de garder la communauté '
                                  'Covoit Campus plus sûre.',
                                  style: TextStyle(
                                    color: textGrey.withValues(alpha: 0.78),
                                    fontSize: 11.5,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // FOOTER
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: textGrey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Vos données restent protégées',
                          style: TextStyle(
                            color: textGrey.withValues(alpha: 0.5),
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