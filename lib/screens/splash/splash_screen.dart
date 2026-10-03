import 'package:flutter/material.dart';
import '../welcome/welcome_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textPosition;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.55,
          curve: Curves.easeOut,
        ),
      ),
    );

    _textPosition = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.3,
          0.85,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.3,
          0.85,
          curve: Curves.easeOut,
        ),
      ),
    );

    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
  if (!mounted) return;

  Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => const WelcomeScreen(),
  ),
);
});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ============================================================
          // BACKGROUND
          // ============================================================
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF4FFFB),
                  Color(0xFFEAF8F3),
                  Color(0xFFDDF4EC),
                ],
              ),
            ),
          ),

          // ============================================================
          // DECORATIVE SHAPE - TOP RIGHT
          // ============================================================
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E5AA8).withValues(alpha: 0.08),
              ),
            ),
          ),

          // ============================================================
          // DECORATIVE SHAPE - BOTTOM LEFT
          // ============================================================
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF20B978).withValues(alpha: 0.10),
              ),
            ),
          ),

          // ============================================================
          // MAIN CONTENT
          // ============================================================
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // --------------------------------------------------
                    // LOGO
                    // --------------------------------------------------
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 190,
                          height: 190,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF124B88)
                                    .withValues(alpha: 0.12),
                                blurRadius: 35,
                                spreadRadius: 4,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --------------------------------------------------
                    // TITLE + TAGLINE
                    // --------------------------------------------------
                    SlideTransition(
                      position: _textPosition,
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: Column(
                          children: [

                            const Text(
                              'Covoit Campus',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                color: Color(0xFF123D68),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              'Partageons le trajet,\npartageons la route.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF365B73)
                                    .withValues(alpha: 0.85),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ------------------------------------------------
                            // SMALL FEATURE CHIPS
                            // ------------------------------------------------
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                                _buildMiniChip(
                                  icon: Icons.school_rounded,
                                  text: 'Étudiants',
                                ),

                                const SizedBox(width: 8),

                                _buildMiniChip(
                                  icon: Icons.verified_rounded,
                                  text: 'Vérifié',
                                ),

                                const SizedBox(width: 8),

                                _buildMiniChip(
                                  icon: Icons.eco_rounded,
                                  text: 'Éco',
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
            ),
          ),

          // ============================================================
          // BOTTOM LOADING AREA
          // ============================================================
          Positioned(
            left: 40,
            right: 40,
            bottom: 42,
            child: Column(
              children: [

                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF20B978),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Votre trajet commence ici',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: const Color(0xFF365B73)
                        .withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // MINI CHIP
  // ==============================================================
  Widget _buildMiniChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF20B978),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF31536B),
            ),
          ),
        ],
      ),
    );
  }
}