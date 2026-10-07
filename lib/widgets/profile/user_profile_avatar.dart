import 'package:flutter/material.dart';

const _profileAvatarBlue = Color(0xFF1E5AA8);

class UserProfileAvatar extends StatelessWidget {
  final String name;
  final String? image;
  final double size;

  const UserProfileAvatar({
    super.key,
    required this.name,
    required this.image,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final source = image?.trim();
    final uri = source == null ? null : Uri.tryParse(source);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final isAsset = source?.startsWith('assets/') == true;
    final ImageProvider<Object>? provider = isNetwork
        ? NetworkImage(source!)
        : isAsset
        ? AssetImage(source!)
        : null;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFEAF3FC),
      foregroundImage: provider,
      onForegroundImageError: provider is NetworkImage ? (_, _) {} : null,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: _profileAvatarBlue,
          fontSize: size * .3,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}
