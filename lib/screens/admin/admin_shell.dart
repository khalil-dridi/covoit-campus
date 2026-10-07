import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../shared/placeholder_page.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'trips/admin_trips_screen.dart';
import 'users/admin_users_screen.dart';
import 'profile/admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  final User user;

  const AdminShell({
    super.key,
    required this.user,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  late User _admin;

  @override
  void initState() {
    super.initState();
    _admin = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AdminDashboardScreen(admin: _admin),
      AdminUsersScreen(admin: _admin),
      AdminTripsScreen(admin: _admin),
      const PlaceholderPage(
        title: 'Signalements',
        subtitle: 'Traitez les signalements des utilisateurs.',
        icon: Icons.report_problem_outlined,
      ),
      AdminProfileScreen(
        admin: _admin,
        onUserUpdated: (user) => setState(() => _admin = user),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
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
