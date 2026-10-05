import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../shared/placeholder_page.dart';
import 'profile/driver_profile_screen.dart';

class DriverShell extends StatefulWidget {
  final User user;

  const DriverShell({
    super.key,
    required this.user,
  });

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const PlaceholderPage(
        title: 'Accueil',
        subtitle: 'Gérez votre activité de conducteur.',
        icon: Icons.home_rounded,
      ),
      const PlaceholderPage(
        title: 'Publier un trajet',
        subtitle: 'Proposez un nouveau trajet aux étudiants.',
        icon: Icons.add_circle_outline_rounded,
      ),
      const PlaceholderPage(
        title: 'Mes trajets',
        subtitle: 'Gérez vos trajets publiés.',
        icon: Icons.directions_car_outlined,
      ),
      const PlaceholderPage(
        title: 'Messages',
        subtitle: 'Discutez avec vos passagers.',
        icon: Icons.chat_bubble_outline_rounded,
      ),
      DriverProfileScreen(user: widget.user),
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Publier',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Mes trajets',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}       