import 'package:flutter/material.dart';

import '../shared/placeholder_page.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PlaceholderPage(
      title: 'Accueil',
      subtitle: 'Gérez votre activité de conducteur.',
      icon: Icons.home_rounded,
    ),
    PlaceholderPage(
      title: 'Publier un trajet',
      subtitle: 'Proposez un nouveau trajet aux étudiants.',
      icon: Icons.add_circle_outline_rounded,
    ),
    PlaceholderPage(
      title: 'Mes trajets',
      subtitle: 'Gérez vos trajets publiés.',
      icon: Icons.directions_car_outlined,
    ),
    PlaceholderPage(
      title: 'Messages',
      subtitle: 'Discutez avec vos passagers.',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    PlaceholderPage(
      title: 'Profil',
      subtitle: 'Gérez votre profil et votre véhicule.',
      icon: Icons.person_outline_rounded,
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