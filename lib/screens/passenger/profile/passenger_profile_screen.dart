import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../repositories/user_repository.dart';
import '../../login/login_screen.dart';
import '../../../utils/logout_flow.dart';

class PassengerProfileScreen extends StatefulWidget {
  final User user;

  const PassengerProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<PassengerProfileScreen> createState() =>
      _PassengerProfileScreenState();
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
  static const Color lightRed = Color(0xFFFFECEC);

  // ==========================================================
  // STATES
  // ==========================================================

  bool smokingPreference = false;
  bool musicPreference = true;
  bool petsPreference = false;

  late bool driverMode;
  late String _fullName;
  late String _phone;
  late String _university;

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
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),

              const SizedBox(height: 30),

              _buildProfileHeader(context),

              const SizedBox(height: 28),

              _buildStatistics(),

              const SizedBox(height: 28),

              _buildPersonalInformation(context),

              const SizedBox(height: 24),

              _buildTravelPreferences(context),

              const SizedBox(height: 20),

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
            Navigator.of(context).maybePop();
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

    return Center(
      child: Column(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  color: lightBlue,
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
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: secondaryBlue,
                  size: 62,
                ),
              ),

              // Camera
              Positioned(
                right: -2,
                bottom: 2,
                child: Material(
                  color: secondaryBlue,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      _showPhotoDialog(context);
                    },
                    child: Container(
                      width: 42,
                      height: 42,
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
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            _fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 9),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isVerified
                  ? green.withValues(alpha: 0.10)
                  : Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: isVerified ? green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isVerified
                      ? 'Email vérifié'
                      : 'Email non vérifié',
                  style: TextStyle(
                    color: isVerified ? green : Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATISTICS
  // ==========================================================

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF2B84B),
            value: '4.8',
            label: 'Note',
            subtitle: '(32 avis)',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildStatCard(
            icon: Icons.route_rounded,
            iconColor: secondaryBlue,
            value: '12',
            label: 'Trajets',
            subtitle: 'en tant que passager',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildStatCard(
            icon: Icons.eco_rounded,
            iconColor: green,
            value: '8.4',
            label: 'kg CO₂ évités',
            subtitle: 'Bravo !',
          ),
        ),
      ],
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
      constraints: const BoxConstraints(
        minHeight: 158,
      ),
      padding: const EdgeInsets.fromLTRB(
        10,
        18,
        10,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE1ECE8),
        ),
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
          Icon(
            icon,
            color: iconColor,
            size: 30,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 24,
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
              fontSize: 11.5,
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
              fontSize: 9.5,
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
          value: _phone.trim().isNotEmpty
              ? _phone
              : 'Non renseigné',
          onTap: () {
            _showEditPersonalInfoDialog(context);
          },
        ),

        _buildDivider(),

        _buildInformationRow(
          icon: Icons.school_outlined,
          label: 'Université',
          value: _university.trim().isNotEmpty
              ? _university
              : 'Non renseignée',
          onTap: () {
            _showEditPersonalInfoDialog(context);
          },
        ),
      ],
    );
  }

  // ==========================================================
  // TRAVEL PREFERENCES
  // ==========================================================

  Widget _buildTravelPreferences(BuildContext context) {
    return _buildLargeSectionCard(
      title: 'Préférences de trajet',
      icon: Icons.tune_rounded,
      onEdit: () {
        _showInfoDialog(
          context,
          title: 'Préférences',
          message:
              'Vous pourrez bientôt modifier vos villes, '
              'horaires et préférences de trajet.',
          icon: Icons.tune_rounded,
        );
      },
      children: [
        _buildInformationRow(
          icon: Icons.route_rounded,
          label: 'Villes préférées',
          value: 'Tunis, Ariana, Manouba',
        ),

        _buildDivider(),

        _buildInformationRow(
          icon: Icons.access_time_rounded,
          label: 'Horaires préférés',
          value: 'Matin (7h–9h)',
        ),

        _buildDivider(),

        _buildInformationRow(
          icon: Icons.groups_rounded,
          label: 'Type de trajet',
          value: 'Uniquement étudiants',
        ),
      ],
    );
  }

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
        border: Border.all(
          color: const Color(0xFFE1ECE8),
        ),
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
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              12,
              14,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: secondaryBlue,
                    size: 21,
                  ),
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
                    backgroundColor:
                        lightBlue.withValues(alpha: 0.65),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                  ),
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

          const Divider(
            height: 1,
            color: Color(0xFFE5ECE9),
          ),

          Column(
            children: children,
          ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: secondaryBlue,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                color: textGrey.withValues(alpha: 0.88),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                if (trailing != null) ...[
                  const SizedBox(width: 7),
                  trailing,
                ],

                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: textGrey,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }

  // ==========================================================
  // DIVIDER
  // ==========================================================

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(
        left: 66,
      ),
      child: Divider(
        height: 1,
        color: Color(0xFFE5ECE9),
      ),
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
        color: driverMode
            ? lightGreen
            : lightBlue.withValues(alpha: 0.75),
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
        border: Border.all(
          color: const Color(0xFFE1ECE8),
        ),
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

          const Divider(
            height: 1,
            color: Color(0xFFE7ECEA),
          ),

          _buildAccountAction(
            icon: Icons.delete_outline_rounded,
            title: 'Supprimer mon compte',
            subtitle: 'Cette action est définitive.',
            color: const Color(0xFFE53935),
            backgroundColor: lightRed,
            onTap: () {
              _showDeleteAccountDialog(context);
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
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                        color: textGrey.withValues(
                          alpha: 0.75,
                        ),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: textGrey,
              ),
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

  void _showDisableDriverModeDialog(
    BuildContext context,
  ) {
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
        content: Text(
          'Impossible de modifier votre rôle. Veuillez réessayer.',
        ),
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
  // DELETE ACCOUNT DIALOG
  // ==========================================================

  void _showDeleteAccountDialog(
    BuildContext context,
  ) {
    _showConfirmationDialog(
      context,
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFE53935),
      title: 'Supprimer votre compte ?',
      message:
          'Cette action est définitive. Les informations '
          'associées à votre compte pourront être supprimées.',
      cancelText: 'Annuler',
      confirmText: 'Supprimer',
      onConfirm: () {
        _showInfoDialog(
          context,
          title: 'Suppression du compte',
          message:
              'La suppression réelle du compte sera connectée '
              'à SQLite dans une prochaine étape.',
          icon: Icons.info_outline_rounded,
        );
      },
    );
  }

  // ==========================================================
  // EDIT PERSONAL INFO
  // ==========================================================

  void _showEditPersonalInfoDialog(
    BuildContext context,
  ) {
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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              20,
            ),
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
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 31,
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
                          minimumSize:
                              const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
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
                          minimumSize:
                              const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
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
                        borderRadius:
                            BorderRadius.circular(15),
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
  final void Function(String fullName, String phone, String university)
      onSaved;

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
        fillColor:
            _PassengerProfileScreenState.lightBlue.withValues(alpha: 0.45),
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
