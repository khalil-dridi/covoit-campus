import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../screens/driver/profile/driver_profile_screen.dart';
import '../../utils/logout_flow.dart';
import '../shared/notification_bell.dart';

class DriverHeader extends StatelessWidget {
  final User user;
  final VoidCallback? onNotificationTap;

  const DriverHeader({
    super.key,
    required this.user,
    this.onNotificationTap,
  });

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color green = Color(0xFF20B978);

  String get _firstName {
    final parts = user.fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? '' : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 248,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/back1.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildBrand()),
                      const SizedBox(width: 9),
                      _notificationButton(),
                      const SizedBox(width: 9),
                      _avatar(context),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car_rounded, color: green, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'ESPACE CONDUCTEUR',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _firstName.isEmpty ? 'Bonjour 👋' : 'Bonjour $_firstName 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Prêt à partager votre prochain trajet ?',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF547080),
                      fontSize: 13,
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
          width: 46,
          height: 46,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        const Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Covoit',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              Text(
                'Campus',
                style: TextStyle(
                  color: green,
                  fontSize: 13,
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

  Widget _notificationButton() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.1),
              blurRadius: 11,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: onNotificationTap == null
            ? NotificationBell(user: user, iconColor: primaryBlue, size: 22)
            : IconButton(
                tooltip: 'Notifications',
                onPressed: onNotificationTap,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.notifications_none_rounded, color: primaryBlue, size: 22),
              ),
      );

  Widget _avatar(BuildContext context) {
    final path = user.profileImage?.trim();
    final uri = path == null ? null : Uri.tryParse(path);
    final isNetwork = uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    final isAsset = path?.startsWith('assets/') == true;
    Widget image;
    if (path == null || path.isEmpty) {
      image = _avatarFallback();
    } else if (isNetwork) {
      image = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _avatarFallback(),
      );
    } else if (isAsset) {
      image = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _avatarFallback(),
      );
    } else {
      image = _avatarFallback();
    }

    return PopupMenuButton<_DriverHeaderAction>(
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
        if (action == _DriverHeaderAction.logout) {
          unawaited(LogoutFlow.confirmAndLogout(context));
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DriverProfileScreen(user: user),
            ),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _DriverHeaderAction.profile,
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: _DriverHeaderMenuItem(
            icon: Icons.person_outline_rounded,
            label: 'Mon profil',
          ),
        ),
        PopupMenuItem(
          value: _DriverHeaderAction.logout,
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: _DriverHeaderMenuItem(
            icon: Icons.logout_rounded,
            label: 'Se déconnecter',
            destructive: true,
          ),
        ),
      ],
      child: Container(
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.09),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(child: image),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: const Color(0xFFEAF3FC),
        alignment: Alignment.center,
        child: const Icon(Icons.person_rounded, color: primaryBlue, size: 26),
      );
}

enum _DriverHeaderAction { profile, logout }

class _DriverHeaderMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;

  const _DriverHeaderMenuItem({
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
                  : DriverHeader.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: destructive
                  ? const Color(0xFFD87532)
                  : DriverHeader.primaryBlue,
              fontSize: 14,
              fontWeight: destructive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      );
}
