import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 44,
                    color: green,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}