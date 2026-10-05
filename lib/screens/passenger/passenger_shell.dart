import 'package:flutter/material.dart';

import '../shared/placeholder_page.dart';
import 'profile/passenger_profile_screen.dart';

class PassengerShell extends StatefulWidget {
  const PassengerShell({super.key});

  @override
  State<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends State<PassengerShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PlaceholderPage(
      title: 'Accueil',
      subtitle: 'Retrouvez vos trajets et recommandations.',
      icon: Icons.home_rounded,
    ),

    PlaceholderPage(
      title: 'Rechercher',
      subtitle: 'Trouvez un trajet qui vous correspond.',
      icon: Icons.search_rounded,
    ),

    PlaceholderPage(
      title: 'Réservations',
      subtitle: 'Gérez vos réservations et vos trajets à venir.',
      icon: Icons.confirmation_number_outlined,
    ),

    PlaceholderPage(
      title: 'Messages',
      subtitle: 'Discutez avec les autres étudiants.',
      icon: Icons.chat_bubble_outline_rounded,
    ),

    PassengerProfileScreen(),
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
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Rechercher',
          ),

          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(
              Icons.confirmation_number_rounded,
            ),
            label: 'Réservations',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.chat_bubble_rounded,
            ),
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