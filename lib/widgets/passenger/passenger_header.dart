import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../screens/passenger/profile/passenger_profile_screen.dart';
import '../../utils/logout_flow.dart';
import '../shared/notification_bell.dart';

class PassengerHeader extends StatelessWidget {
  final User user;
  final VoidCallback? onNotificationTap;

  const PassengerHeader({
    super.key,
    required this.user,
    this.onNotificationTap,
  });

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color green = Color(0xFF20B978);

  String get _firstName {
    final nameParts = user.fullName.trim().split(RegExp(r'\s+'));
    return nameParts.isEmpty || nameParts.first.isEmpty
        ? ''
        : nameParts.first;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        width: double.infinity,
        height: 276,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/back1.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildBrand()),
                      const SizedBox(width: 12),
                      _buildNotificationButton(),
                      const SizedBox(width: 10),
                      _buildAvatar(context),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _firstName.isEmpty ? 'Bonjour 👋' : 'Bonjour $_firstName 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Prêt pour votre prochain trajet ?',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF547080),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 9),
        const Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Covoit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              Text(
                'Campus',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: green,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.11),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: onNotificationTap == null
          ? NotificationBell(user: user, iconColor: primaryBlue, size: 23)
          : IconButton(
              tooltip: 'Notifications',
              onPressed: onNotificationTap,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.notifications_none_rounded, color: primaryBlue, size: 23),
            ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final imagePath = user.profileImage?.trim();
    final imageUri = imagePath == null ? null : Uri.tryParse(imagePath);
    final isNetworkImage = imageUri != null &&
        (imageUri.scheme == 'http' || imageUri.scheme == 'https');
    final isAssetImage = imagePath?.startsWith('assets/') == true;

    Widget image;
    if (imagePath == null || imagePath.isEmpty) {
      image = _buildAvatarFallback();
    } else if (isNetworkImage) {
      image = Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
      );
    } else if (isAssetImage) {
      image = Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
      );
    } else {
      image = _buildAvatarFallback();
    }

    return PopupMenuButton<_PassengerHeaderAction>(
      tooltip: 'Profil et compte',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 240),
      color: Colors.white,
      elevation: 12,
      shadowColor: primaryBlue.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2EBE7)),
      ),
      onSelected: (action) {
        if (action == _PassengerHeaderAction.logout) {
          unawaited(LogoutFlow.confirmAndLogout(context));
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PassengerProfileScreen(user: user),
            ),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _PassengerHeaderAction.profile,
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: _PassengerHeaderMenuItem(
            icon: Icons.person_outline_rounded,
            label: 'Mon profil',
          ),
        ),
        PopupMenuItem(
          value: _PassengerHeaderAction.logout,
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: _PassengerHeaderMenuItem(
            icon: Icons.logout_rounded,
            label: 'Se déconnecter',
            destructive: true,
          ),
        ),
      ],
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(child: image),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFEAF3FC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        color: primaryBlue,
        size: 27,
      ),
    );
  }
}

enum _PassengerHeaderAction { profile, logout }

class _PassengerHeaderMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;

  const _PassengerHeaderMenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 22,
            child: Icon(
              icon,
              size: 20,
              color: destructive
                  ? const Color(0xFFD87532)
                  : PassengerHeader.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: destructive
                  ? const Color(0xFFD87532)
                  : PassengerHeader.primaryBlue,
              fontSize: 14,
              fontWeight: destructive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      );
}
