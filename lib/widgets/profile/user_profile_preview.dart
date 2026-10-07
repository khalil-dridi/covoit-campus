import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/user_profile_context.dart';
import '../../repositories/driver_profile_repository.dart';
import '../../repositories/user_repository.dart';
import '../../screens/shared/profile/user_public_profile_screen.dart';
import 'user_profile_avatar.dart';

const _profileBlue = Color(0xFF123D68);
const _profileSecondaryBlue = Color(0xFF1E5AA8);
const _profileGreen = Color(0xFF20B978);
const _profileMuted = Color(0xFF547080);

Future<void> showUserProfilePreview({
  required BuildContext context,
  required int userId,
  required User currentUser,
  required UserProfileContext profileContext,
}) async {
  final anchor = context.findRenderObject();
  final overlay = Overlay.of(context).context.findRenderObject();
  if (anchor is! RenderBox || overlay is! RenderBox || !anchor.hasSize) return;
  final navigator = Navigator.of(context);
  final topLeft = anchor.localToGlobal(Offset.zero, ancestor: overlay);
  final position = RelativeRect.fromRect(
    topLeft & anchor.size,
    Offset.zero & overlay.size,
  );
  final screenWidth = MediaQuery.sizeOf(context).width;
  final menuWidth = math.min(280.0, screenWidth - 24);

  User? loadedUser;
  try {
    loadedUser = await UserRepository().getActiveUserById(userId);
  } catch (_) {
    return;
  }
  if (!context.mounted || !navigator.mounted) return;
  if (loadedUser == null ||
      loadedUser.id == null ||
      (loadedUser.role != 'driver' && loadedUser.role != 'passenger')) {
    return;
  }
  final user = loadedUser;

  double? rating;
  if (user.role == 'driver') {
    try {
      final stats = await DriverProfileRepository().getStats(user.id!);
      rating = stats.ratingCount > 0 ? stats.rating : null;
    } catch (_) {
      // The preview remains useful without optional rating data.
    }
  }
  if (!context.mounted) return;
  final openProfile = await showMenu<bool>(
    context: context,
    position: position,
    constraints: BoxConstraints(
      minWidth: math.min(250.0, menuWidth),
      maxWidth: menuWidth,
    ),
    items: [
      PopupMenuItem<bool>(
        value: true,
        padding: EdgeInsets.zero,
        child: UserProfilePreview(user: user, rating: rating),
      ),
    ],
  );

  if (openProfile == true && navigator.mounted) {
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UserPublicProfileScreen(
          userId: user.id!,
          currentUser: currentUser,
          contextInfo: profileContext,
        ),
      ),
    );
  }
}

class UserProfilePreview extends StatelessWidget {
  final User user;
  final double? rating;

  const UserProfilePreview({super.key, required this.user, this.rating});

  @override
  Widget build(BuildContext context) {
    final university = user.university?.trim();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserProfileAvatar(
                  name: user.fullName,
                  image: user.profileImage,
                  size: 46,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _profileBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _roleLabel(user.role),
                        style: const TextStyle(
                          color: _profileSecondaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (university?.isNotEmpty == true || rating != null) ...[
              const SizedBox(height: 10),
              if (university?.isNotEmpty == true)
                Text(
                  university!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _profileMuted, fontSize: 11),
                ),
              if (rating != null) ...[
                if (university?.isNotEmpty == true) const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE2A631),
                      size: 15,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: _profileBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE7EFEC)),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Voir le profil',
                  style: TextStyle(
                    color: _profileGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _profileGreen,
                  size: 17,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfileTarget extends StatefulWidget {
  final int userId;
  final User currentUser;
  final UserProfileContext profileContext;
  final Widget child;
  final bool enabled;
  final BorderRadius? borderRadius;

  const UserProfileTarget({
    super.key,
    required this.userId,
    required this.currentUser,
    this.profileContext = const UserProfileContext(),
    required this.child,
    this.enabled = true,
    this.borderRadius,
  });

  @override
  State<UserProfileTarget> createState() => _UserProfileTargetState();
}

class _UserProfileTargetState extends State<UserProfileTarget> {
  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: _anchorKey,
    child: InkWell(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      onTap: widget.enabled
          ? () {
              final anchorContext = _anchorKey.currentContext;
              if (anchorContext == null) return;
              showUserProfilePreview(
                context: anchorContext,
                userId: widget.userId,
                currentUser: widget.currentUser,
                profileContext: widget.profileContext,
              );
            }
          : null,
      child: widget.child,
    ),
  );
}

String _roleLabel(String role) => switch (role) {
  'driver' => 'Conducteur',
  'passenger' => 'Passager',
  _ => 'Membre',
};
