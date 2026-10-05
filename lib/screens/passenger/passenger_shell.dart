import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../shared/placeholder_page.dart';
import 'home/passenger_home_screen.dart';
import 'profile/passenger_profile_screen.dart';
import 'search/passenger_search_screen.dart';

class PassengerShell extends StatefulWidget {
  final User user;

  const PassengerShell({
    super.key,
    required this.user,
  });

  @override
  State<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends State<PassengerShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      PassengerHomeScreen(user: widget.user),

      PassengerSearchScreen(user: widget.user),

      const PlaceholderPage(
        title: 'Réservations',
        subtitle:
            'Gérez vos réservations et vos trajets à venir.',
        icon: Icons.confirmation_number_outlined,
      ),

      const PlaceholderPage(
        title: 'Messages',
        subtitle:
            'Discutez avec les autres étudiants.',
        icon: Icons.chat_bubble_outline_rounded,
      ),

      PassengerProfileScreen(user: widget.user),
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
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Rechercher',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.confirmation_number_outlined,
            ),
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