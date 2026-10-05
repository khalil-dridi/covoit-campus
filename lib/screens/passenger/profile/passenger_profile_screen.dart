import 'package:flutter/material.dart';

class PassengerProfileScreen extends StatelessWidget {
  const PassengerProfileScreen({super.key});

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Column(
          children: [
            // ========================================================
            // HEADER
            // ========================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                0,
              ),
              child: Row(
                children: [
                  _headerButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  const Spacer(),

                  const Text(
                    'Mon profil',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const Spacer(),

                  _headerButton(
                    icon: Icons.settings_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // ========================================================
            // PROFILE CONTENT
            // ========================================================

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(
                  20,
                  30,
                  20,
                  30,
                ),

                child: Column(
                  children: [
                    // ==================================================
                    // AVATAR
                    // ==================================================

                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 112,
                          height: 112,

                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FC),
                            shape: BoxShape.circle,

                            border: Border.all(
                              color: Colors.white,
                              width: 5,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withValues(
                                  alpha: 0.10,
                                ),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),

                          child: const Icon(
                            Icons.person_rounded,
                            color: secondaryBlue,
                            size: 60,
                          ),
                        ),

                        // Camera button
                        Positioned(
                          right: -3,
                          bottom: 2,

                          child: Material(
                            color: secondaryBlue,
                            shape: const CircleBorder(),

                            child: InkWell(
                              customBorder:
                                  const CircleBorder(),

                              onTap: () {
                                _showInfoDialog(
                                  context,
                                  title: 'Photo de profil',
                                  message:
                                      'La modification de votre photo '
                                      'sera disponible prochainement.',
                                  icon:
                                      Icons.camera_alt_outlined,
                                );
                              },

                              child: Container(
                                width: 38,
                                height: 38,

                                decoration: BoxDecoration(
                                  color: secondaryBlue,
                                  shape: BoxShape.circle,

                                  border: Border.all(
                                    color: background,
                                    width: 4,
                                  ),
                                ),

                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // NAME
                    // ==================================================

                    const Text(
                      'Khalil Dridi',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // VERIFIED EMAIL
                    // ==================================================

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),

                      decoration: BoxDecoration(
                        color: green.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(30),
                      ),

                      child: const Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: green,
                            size: 17,
                          ),

                          SizedBox(width: 6),

                          Text(
                            'Email vérifié',
                            style: TextStyle(
                              color: green,
                              fontSize: 12.5,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // STATISTICS
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star_rounded,
                            iconColor:
                                const Color(0xFFF2B84B),
                            value: '4.8',
                            label: 'Note',
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.route_rounded,
                            iconColor: secondaryBlue,
                            value: '12',
                            label: 'Trajets',
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.eco_rounded,
                            iconColor: green,
                            value: '8.4',
                            label: 'kg CO₂ évités',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // NEXT SECTION PLACEHOLDER
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(24),

                        border: Border.all(
                          color:
                              const Color(0xFFE0ECE7),
                        ),
                      ),

                      child: const Text(
                        'Informations personnelles',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
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

  // ==========================================================
  // STAT CARD
  // ==========================================================

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: const Color(0xFFE0ECE7),
        ),

        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(
              alpha: 0.04,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              color: textGrey.withValues(
                alpha: 0.75,
              ),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER BUTTON
  // ==========================================================

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),

      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,

        child: SizedBox(
          width: 46,
          height: 46,

          child: Icon(
            icon,
            color: primaryBlue,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // INFO DIALOG
  // ==========================================================

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,

          insetPadding:
              const EdgeInsets.all(24),

          child: Container(
            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(28),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 64,
                  height: 64,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FC),
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    icon,
                    color: secondaryBlue,
                    size: 29,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  title,
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },

                    style: ElevatedButton
                        .styleFrom(
                      backgroundColor:
                          primaryBlue,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),

                    child: const Text(
                      'Fermer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}