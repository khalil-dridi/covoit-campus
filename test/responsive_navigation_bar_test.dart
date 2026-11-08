import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:covoit_campus/widgets/shared/responsive_navigation_bar.dart';

const _destinations = [
  NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
  NavigationDestination(icon: Icon(Icons.search), label: 'Rechercher'),
  NavigationDestination(
    icon: Icon(Icons.confirmation_number_outlined),
    label: 'Réservations',
  ),
  NavigationDestination(icon: Icon(Icons.message_outlined), label: 'Messages'),
  NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
];

void main() {
  const sizes = [
    Size(360, 640),
    Size(360, 800),
    Size(393, 873),
    Size(412, 915),
  ];

  for (final size in sizes) {
    testWidgets('renders without overflow at ${size.width} x ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: _NavigationHarness()));
      await tester.pumpAndSettle();

      expect(find.text('Réservations'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Réservations'));
      await tester.pumpAndSettle();
      expect(find.text('Destination 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('handles enlarged system text without layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const _NavigationHarness(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Réservations'), findsOneWidget);
    expect(tester.getSize(find.byType(NavigationBar)).height, greaterThan(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps logical layout at higher pixel density', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: _NavigationHarness()));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(ResponsiveNavigationBar)).width, 360);
    expect(find.text('Réservations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _NavigationHarness extends StatefulWidget {
  const _NavigationHarness();

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

class _NavigationHarnessState extends State<_NavigationHarness> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Destination $_selectedIndex')),
      bottomNavigationBar: ResponsiveNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: _destinations,
      ),
    );
  }
}
