import 'package:flutter/material.dart';

import '../shared/placeholder_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PlaceholderPage(
      title: 'Dashboard',
      subtitle: 'Vue globale de la plateforme.',
      icon: Icons.dashboard_outlined,
    ),
    PlaceholderPage(
      title: 'Utilisateurs',
      subtitle: 'Gérez les utilisateurs de Covoit Campus.',
      icon: Icons.people_outline_rounded,
    ),
    PlaceholderPage(
      title: 'Trajets',
      subtitle: 'Gérez les trajets de la plateforme.',
      icon: Icons.route_outlined,
    ),
    PlaceholderPage(
      title: 'Signalements',
      subtitle: 'Traitez les signalements des utilisateurs.',
      icon: Icons.report_problem_outlined,
    ),
    PlaceholderPage(
      title: 'Profil',
      subtitle: 'Gérez votre compte administrateur.',
      icon: Icons.admin_panel_settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Utilisateurs',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded),
            label: 'Trajets',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem_rounded),
            label: 'Signalements',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}