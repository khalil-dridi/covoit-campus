import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/rating_repository.dart';
import '../../login/login_screen.dart';
import '../../../utils/logout_flow.dart';

class PassengerProfileScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onBack;

  const PassengerProfileScreen({super.key, required this.user, this.onBack});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);

  static const Color lightBlue = Color(0xFFEAF3FC);
  static const Color lightGreen = Color(0xFFE8F8F1);
  static const Color lightOrange = Color(0xFFFFF1E6);

  // ==========================================================
  // STATES
  // ==========================================================

  late bool driverMode;
  late String _fullName;
  late String _phone;
  late String _university;
  bool _statisticsLoading = true;
  bool _statisticsAvailable = false;
  double? _averageRating;
  int _ratingCount = 0;
  int _completedTripCount = 0;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    driverMode = widget.user.role == 'driver';
    _fullName = widget.user.fullName;
    _phone = widget.user.phone ?? '';
    _university = widget.user.university ?? '';
    unawaited(_loadStatistics());
  }

  Future<void> _loadStatistics() async {
    final userId = widget.user.id;
    if (userId == null) {
      if (mounted) setState(() => _statisticsLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        RatingRepository().getPublicStats(userId),
        BookingRepository().getCompletedPassengerTripCount(userId),
      ]);
      if (!mounted) return;
      final rating = results[0] as ({double? average, int count});
      setState(() {
        _averageRating = rating.average;
        _ratingCount = rating.count;
        _completedTripCount = results[1] as int;
        _statisticsAvailable = true;
        _statisticsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statisticsLoading = false);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),

              const SizedBox(height: 16),

              _buildProfileHeader(context),

              const SizedBox(height: 22),

              _buildSectionHeading(
                'Mon activité',
                'Votre expérience sur Covoit Campus',
              ),

              const SizedBox(height: 12),

              _buildStatistics(),

              const SizedBox(height: 24),

              _buildPersonalInformation(context),

              const SizedBox(height: 24),

              _buildDriverModeCard(context),

              const SizedBox(height: 18),

              _buildAccountActions(context),

              const SizedBox(height: 10),

              _buildSecurityFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildHeaderButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              widget.onBack?.call();
            }
          },
        ),

        const Spacer(),

        const Text(
          'Mon profil',
          style: TextStyle(
            color: primaryBlue,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),

        const Spacer(),

        _buildHeaderButton(
          icon: Icons.settings_outlined,
          onTap: () {
            _showInfoDialog(
              context,
              title: 'Paramètres',
              message:
                  'Les paramètres généraux de votre compte '
                  'seront disponibles ici.',
              icon: Icons.settings_outlined,
            );
          },
        ),
      ],
    );
  }

  // ==========================================================
  // PROFILE HEADER
  // ==========================================================

  Widget _buildProfileHeader(BuildContext context) {
    final bool isVerified = widget.user.isVerified;
    final imagePath = widget.user.profileImage?.trim();
    final verifiedColor = isVerified ? green : const Color(0xFFFFD2C8);
    final avatar = _buildAvatar(imagePath);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ClipOval(child: avatar),
              ),
              Positioned(
                right: -2,
                bottom: -1,
                child: Material(
                  color: secondaryBlue,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _showPhotoDialog(context),
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _university.trim().isEmpty ? 'Espace passager' : _university,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _heroPill(
                      icon: Icons.person_outline_rounded,
                      label: 'Passager',
                      color: Colors.white,
                    ),
                    _heroPill(
                      icon: isVerified
                          ? Icons.verified_rounded
                          : Icons.error_outline_rounded,
                      label: isVerified ? 'Email vérifié' : 'À vérifier',
                      color: verifiedColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? imagePath) {
    final uri = imagePath == null ? null : Uri.tryParse(imagePath);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (imagePath != null && imagePath.isNotEmpty && isNetwork) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _avatarFallback(),
      );
    }
    if (imagePath?.startsWith('assets/') == true) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _avatarFallback(),
      );
    }
    return _avatarFallback();
  }

  Widget _avatarFallback() {
    final initials = _fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      color: lightBlue,
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'CC' : initials,
        style: const TextStyle(
          color: primaryBlue,
          fontSize: 25,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _heroPill({
    required IconData icon,
    required String label,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  // ==========================================================
  // STATISTICS
  // ==========================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 340 ? 7.0 : 10.0;
        final cardWidth = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF2B84B),
                value: _statisticsLoading
                    ? '…'
                    : _averageRating?.toStringAsFixed(1) ?? '—',
                label: 'Note / 5',
                subtitle: _statisticsLoading
                    ? 'Chargement'
                    : !_statisticsAvailable
                    ? 'Indisponible'
                    : _ratingCount == 0
                    ? 'Aucun avis'
                    : '$_ratingCount avis',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                icon: Icons.route_rounded,
                iconColor: secondaryBlue,
                value: _statisticsLoading
                    ? '…'
                    : _statisticsAvailable
                    ? '$_completedTripCount'
                    : '—',
                label: 'Trajets',
                subtitle: 'terminés',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                icon: Icons.eco_rounded,
                iconColor: green,
                value: '—',
                label: 'CO₂ évités',
                subtitle: 'Calcul en préparation',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String subtitle,
  }) {
    return Container(
      constraints: const BoxConstraints.tightFor(height: 150),
      padding: const EdgeInsets.fromLTRB(7, 13, 7, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE1ECE8)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 25),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textGrey.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textGrey.withValues(alpha: 0.60),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PERSONAL INFORMATION
  // ==========================================================

  Widget _buildPersonalInformation(BuildContext context) {
    final bool isVerified = widget.user.isVerified;

    return _buildLargeSectionCard(
      title: 'Informations personnelles',
      icon: Icons.person_rounded,
      onEdit: () {
        _showEditPersonalInfoDialog(context);
      },
      children: [
        _buildInformationRow(
          icon: Icons.person_outline_rounded,
          label: 'Nom complet',
          value: _fullName,
          onTap: () {
            _showEditPersonalInfoDialog(context);
          },
        ),

        _buildDivider(),

        _buildInformationRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: widget.user.email,
          trailing: Icon(
            isVerified
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: isVerified ? green : Colors.red,
            size: 19,
          ),
        ),

        _buildDivider(),

        _buildInformationRow(
          icon: Icons.phone_outlined,
          label: 'Téléphone',
          value: _phone.trim().isNotEmpty ? _phone : 'Non renseigné',
          onTap: () {
            _showEditPersonalInfoDialog(context);
          },
        ),

        _buildDivider(),

        _buildInformationRow(
          icon: Icons.school_outlined,
          label: 'Université',
          value: _university.trim().isNotEmpty ? _university : 'Non renseignée',
          onTap: () {
            _showEditPersonalInfoDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.insights_rounded, color: green, size: 18),
        ),
      ],
    ),
  );

  // ==========================================================
  // LARGE SECTION CARD
  // ==========================================================

  Widget _buildLargeSectionCard({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1ECE8)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: secondaryBlue, size: 21),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: secondaryBlue,
                    backgroundColor: lightBlue.withValues(alpha: 0.65),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'Modifier',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5ECE9)),

          Column(children: children),
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMATION ROW
  // ==========================================================

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: secondaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.84),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
          if (onTap != null) ...[
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: textGrey, size: 20),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }

  // ==========================================================
  // DIVIDER
  // ==========================================================

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 66),
      child: Divider(height: 1, color: Color(0xFFE5ECE9)),
    );
  }

  // ==========================================================
  // DRIVER MODE
  // ==========================================================

  Widget _buildDriverModeCard(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: driverMode ? lightGreen : lightBlue.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: driverMode
              ? green.withValues(alpha: 0.20)
              : secondaryBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: driverMode
                  ? green.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.70),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_rounded,
              color: driverMode ? green : secondaryBlue,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverMode
                      ? 'Mode conducteur actif'
                      : 'Passer en mode conducteur',
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  driverMode
                      ? 'Publiez et gérez vos propres trajets.'
                      : 'Proposez vos trajets et aidez '
                            'd’autres étudiants.',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: driverMode,
            activeThumbColor: green,
            onChanged: (value) {
              if (value) {
                _showDriverModeDialog(context);
              } else {
                _showDisableDriverModeDialog(context);
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACCOUNT ACTIONS
  // ==========================================================

  Widget _buildAccountActions(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECE8)),
      ),
      child: Column(
        children: [
          _buildAccountAction(
            icon: Icons.logout_rounded,
            title: 'Se déconnecter',
            subtitle: 'Quitter votre session actuelle.',
            color: const Color(0xFFE96A2C),
            backgroundColor: lightOrange,
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 23),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textGrey.withValues(alpha: 0.75),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: textGrey),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SECURITY FOOTER
  // ==========================================================

  Widget _buildSecurityFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: textGrey.withValues(alpha: 0.50),
            size: 15,
          ),

          const SizedBox(width: 6),

          Text(
            'Vos données restent protégées',
            style: TextStyle(
              color: textGrey.withValues(alpha: 0.55),
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

  Widget _buildHeaderButton({
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
          child: Icon(icon, color: primaryBlue, size: 22),
        ),
      ),
    );
  }

  // ==========================================================
  // PHOTO DIALOG
  // ==========================================================

  void _showPhotoDialog(BuildContext context) {
    _showInfoDialog(
      context,
      title: 'Photo de profil',
      message:
          'Vous pourrez bientôt choisir une photo depuis '
          'la galerie ou prendre une nouvelle photo.',
      icon: Icons.camera_alt_outlined,
    );
  }

  // ==========================================================
  // DRIVER MODE DIALOG
  // ==========================================================

  void _showDriverModeDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      icon: Icons.directions_car_rounded,
      iconColor: secondaryBlue,
      title: 'Passer en mode conducteur ?',
      message:
          'Votre espace changera pour vous permettre de '
          'publier et gérer vos propres trajets.',
      cancelText: 'Annuler',
      confirmText: 'Continuer',
      onConfirm: () {
        _updateRoleAndRequireLogout(context, 'driver');
      },
    );
  }

  // ==========================================================
  // DISABLE DRIVER MODE
  // ==========================================================

  void _showDisableDriverModeDialog(BuildContext context) {
    _showConfirmationDialog(
      context,
      icon: Icons.person_rounded,
      iconColor: secondaryBlue,
      title: 'Revenir en mode passager ?',
      message:
          'Vous reviendrez à votre espace passager. '
          'Vos trajets publiés seront conservés.',
      cancelText: 'Annuler',
      confirmText: 'Continuer',
      onConfirm: () {
        _updateRoleAndRequireLogout(context, 'passenger');
      },
    );
  }

  Future<void> _updateRoleAndRequireLogout(
    BuildContext context,
    String role,
  ) async {
    final userId = widget.user.id;
    if (userId == null) {
      _showRoleUpdateError(context);
      return;
    }

    try {
      final updatedRows = await UserRepository().updateUserRole(userId, role);
      if (!mounted || !context.mounted) {
        return;
      }
      if (updatedRows == 0) {
        _showRoleUpdateError(context);
        return;
      }

      setState(() {
        driverMode = role == 'driver';
      });
      _showForcedLogoutDialog(context);
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      _showRoleUpdateError(context);
    }
  }

  void _showRoleUpdateError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible de modifier votre rôle. Veuillez réessayer.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showForcedLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: secondaryBlue.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: secondaryBlue,
                      size: 31,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Déconnexion requise',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Votre rôle a été modifié avec succès. Pour appliquer '
                    'votre nouvel espace utilisateur, vous devez vous '
                    'déconnecter puis vous reconnecter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textGrey.withValues(alpha: 0.82),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final navigator = Navigator.of(dialogContext);
                        navigator.pop();
                        navigator.pushAndRemoveUntil<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

  // ==========================================================
  // LOGOUT DIALOG
  // ==========================================================

  void _showLogoutDialog(BuildContext context) {
    unawaited(LogoutFlow.confirmAndLogout(context));
  }

  // ==========================================================
  // EDIT PERSONAL INFO
  // ==========================================================

  void _showEditPersonalInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _EditPersonalInfoDialog(
        userId: widget.user.id,
        fullName: _fullName,
        phone: _phone,
        university: _university,
        onSaved: (fullName, phone, university) {
          if (!mounted) {
            return;
          }

          setState(() {
            _fullName = fullName;
            _phone = phone;
            _university = university;
          });
        },
      ),
    );
  }

  // ==========================================================
  // CONFIRMATION DIALOG
  // ==========================================================

  void _showConfirmationDialog(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String cancelText,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 31),
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
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.82),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textGrey,
                          side: const BorderSide(
                            color: Color(0xFFD8E6E1),
                            width: 1.3,
                          ),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    color: lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: secondaryBlue, size: 29),
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
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.82),
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
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
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

class _EditPersonalInfoDialog extends StatefulWidget {
  final int? userId;
  final String fullName;
  final String phone;
  final String university;
  final void Function(String fullName, String phone, String university) onSaved;

  const _EditPersonalInfoDialog({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.university,
    required this.onSaved,
  });

  @override
  State<_EditPersonalInfoDialog> createState() =>
      _EditPersonalInfoDialogState();
}

class _EditPersonalInfoDialogState extends State<_EditPersonalInfoDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _universityController;

  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _phoneController = TextEditingController(text: widget.phone);
    _universityController = TextEditingController(text: widget.university);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext dialogContext) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = widget.userId;
    if (userId == null) {
      setState(() {
        _saveError = 'Impossible d’identifier votre compte.';
      });
      return;
    }

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final university = _universityController.text.trim();

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final updatedRows = await UserRepository().updateUserProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        university: university,
      );

      if (!mounted) {
        return;
      }
      if (updatedRows == 0) {
        throw StateError('No user row was updated.');
      }

      widget.onSaved(fullName, phone, university);

      if (!mounted || !dialogContext.mounted) {
        return;
      }
      Navigator.of(dialogContext).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveError =
            'Impossible d’enregistrer vos informations. Veuillez réessayer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _PassengerProfileScreenState.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: _PassengerProfileScreenState.secondaryBlue,
                        size: 29,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Modifier mes informations',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _PassengerProfileScreenState.primaryBlue,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildEditField(
                      label: 'Nom complet',
                      icon: Icons.person_outline_rounded,
                      controller: _fullNameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom complet est obligatoire.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildEditField(
                      label: 'Téléphone',
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildEditField(
                      label: 'Université',
                      icon: Icons.school_outlined,
                      controller: _universityController,
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _saveError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  _PassengerProfileScreenState.textGrey,
                              side: const BorderSide(
                                color: Color(0xFFD8E6E1),
                                width: 1.3,
                              ),
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Annuler',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () => _save(dialogContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _PassengerProfileScreenState.primaryBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _PassengerProfileScreenState.secondaryBlue,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Enregistrer',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        color: _PassengerProfileScreenState.primaryBlue,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: _PassengerProfileScreenState.secondaryBlue,
          size: 20,
        ),
        filled: true,
        fillColor: _PassengerProfileScreenState.lightBlue.withValues(
          alpha: 0.45,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFD8E6E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFD8E6E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: _PassengerProfileScreenState.secondaryBlue,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.4),
        ),
      ),
    );
  }
}
