import 'package:flutter/material.dart';

/// Material navigation bar with labels tuned for narrow phone widths.
class ResponsiveNavigationBar extends StatelessWidget {
  const ResponsiveNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationTheme = NavigationBarTheme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final height = 80.0 + ((textScale - 1).clamp(0.0, 1.0) * 12.0);
    final baseLabelStyle =
        navigationTheme.labelTextStyle?.resolve(const <WidgetState>{}) ??
        theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth =
            constraints.maxWidth - MediaQuery.viewPaddingOf(context).horizontal;
        final destinationWidth = safeWidth / destinations.length;
        final labels = destinations.map((destination) {
          final painter = TextPainter(
            text: TextSpan(
              text: destination.label,
              style: baseLabelStyle?.copyWith(letterSpacing: 0),
            ),
            textDirection: Directionality.of(context),
            textScaler: TextScaler.linear(1),
          )..layout();
          return painter.width;
        });
        final widestLabel = labels.fold<double>(0, (a, b) => a > b ? a : b);
        final baseFontSize = baseLabelStyle?.fontSize ?? 12;
        final minScale = (10 / baseFontSize).clamp(0.0, 1.0);
        final labelScale = (destinationWidth / widestLabel).clamp(
          minScale,
          1.0,
        );

        TextStyle? labelStyle(Set<WidgetState> states) {
          final themedStyle = navigationTheme.labelTextStyle?.resolve(states);
          final defaultStyle = theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface,
          );
          return (themedStyle ?? defaultStyle)?.copyWith(
            fontSize: baseFontSize * labelScale,
            letterSpacing: 0,
          );
        }

        return NavigationBar(
          height: height,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith(labelStyle),
          destinations: destinations,
        );
      },
    );
  }
}
