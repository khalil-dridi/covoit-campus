import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../widgets/messages/message_badge.dart';
import '../shared/messages/conversations_screen.dart';
import 'home/passenger_home_screen.dart';
import 'profile/passenger_profile_screen.dart';
import 'search/passenger_search_screen.dart';
import 'trips/passenger_bookings_screen.dart';

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
      PassengerHomeScreen(
        user: widget.user,
        onSearchTap: () => setState(() => _currentIndex = 1),
        onNavigateToReservations: () => setState(() => _currentIndex = 2),
      ),

      PassengerSearchScreen(user: widget.user),

      PassengerBookingsScreen(user: widget.user),

      ConversationsScreen(currentUser: widget.user),

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

        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),

          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Rechercher',
          ),

          const NavigationDestination(
            icon: Icon(
              Icons.confirmation_number_outlined,
            ),
            selectedIcon: Icon(
              Icons.confirmation_number_rounded,
            ),
            label: 'Réservations',
          ),

          NavigationDestination(
            icon: MessageBadgeIcon(
              userId: widget.user.id ?? 0,
              selected: false,
            ),
            selectedIcon: MessageBadgeIcon(
              userId: widget.user.id ?? 0,
              selected: true,
            ),
            label: 'Messages',
          ),

          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
