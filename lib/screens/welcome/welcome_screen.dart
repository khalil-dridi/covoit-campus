import 'package:flutter/material.dart';

import '../login/login_screen.dart';
import '../register/register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);

  final List<OnboardingData> pages = [
    OnboardingData(
      title: 'Le covoiturage\nentre étudiants',
      description:
          'Partagez vos trajets avec des étudiants de confiance '
          'et rendez vos déplacements plus simples.',
      icon: Icons.groups_rounded,
      iconColor: Color(0xFF123D68),
    ),
    OnboardingData(
      title: 'Trouvez le trajet\nqui vous correspond',
      description:
          'Recherchez facilement un trajet selon votre destination, '
          'votre horaire, votre budget et vos préférences.',
      icon: Icons.route_rounded,
      iconColor: Color(0xFF1E5AA8),
    ),
    OnboardingData(
      title: 'Voyagez ensemble,\npartagez plus',
      description:
          'Réservez votre place, échangez avec votre conducteur '
          'et rendez chaque trajet plus écologique.',
      icon: Icons.eco_rounded,
      iconColor: Color(0xFF20B978),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _openAuthentication(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================================
            // LOGO
            // ==========================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ==========================================================
            // PAGES
            // ==========================================================
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(pages[index]);
                },
              ),
            ),

            // ==========================================================
            // BOTTOM AREA
            // ==========================================================
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                MediaQuery.sizeOf(context).height < 700 ? 16 : 24,
              ),
              child: Column(
                children: [
                  // ------------------------------------------------------
                  // INDICATORS
                  // ------------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (index) {
                      final bool isActive = index == _currentPage;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? green : const Color(0xFFD2E3DD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                  ),

                  // ------------------------------------------------------
                  // PAGE NUMBER
                  // ------------------------------------------------------
                  Text(
                    '${_currentPage + 1} / ${pages.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue.withValues(alpha: 0.45),
                    ),
                  ),
                  SizedBox(height: _currentPage == pages.length - 1 ? 16 : 22),
                  if (_currentPage == pages.length - 1) ...[
                    _buildActionButton(
                      label: 'Créer un compte',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () =>
                          _openAuthentication(const RegisterScreen()),
                      primary: true,
                    ),
                    const SizedBox(height: 10),
                    _buildActionButton(
                      label: 'Se connecter',
                      onPressed: () => _openAuthentication(const LoginScreen()),
                      primary: false,
                    ),
                  ] else
                    _buildActionButton(
                      label: 'Suivant',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _nextPage,
                      primary: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD ONE ONBOARDING PAGE
  // ==========================================================
  Widget _buildPage(OnboardingData page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 430;
        final heroSize = (constraints.maxHeight * 0.48).clamp(
          compact ? 160.0 : 190.0,
          300.0,
        );
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ----------------------------------------------------------
                  // HERO CARD
                  // ----------------------------------------------------------
                  Container(
                    width: double.infinity,
                    height: heroSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE8F9F2),
                          const Color(0xFFDDEFFC),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative circle
                        Positioned(
                          top: -30,
                          right: -20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: secondaryBlue.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        // Decorative circle
                        Positioned(
                          bottom: -30,
                          left: -25,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        // Main icon
                        Center(
                          child: Container(
                            width: heroSize * 0.57,
                            height: heroSize * 0.57,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: page.iconColor.withValues(alpha: 0.12),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Icon(
                              page.icon,
                              size: heroSize * 0.30,
                              color: page.iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: compact ? 20 : 30),

                  // ----------------------------------------------------------
                  // TITLE
                  // ----------------------------------------------------------
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: compact ? 26 : 30,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ----------------------------------------------------------
                  // DESCRIPTION
                  // ----------------------------------------------------------
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF456477),
                      fontSize: compact ? 14 : 15,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required bool primary,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: primary ? green : Colors.white,
          foregroundColor: primary ? Colors.white : secondaryBlue,
          side: BorderSide(color: primary ? green : const Color(0xFFD6E2E8)),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (icon != null) ...[
              const SizedBox(width: 10),
              Icon(icon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ================================================================
// ONBOARDING DATA
// ================================================================
class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}
