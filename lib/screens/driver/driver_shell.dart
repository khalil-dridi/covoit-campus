import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../shared/placeholder_page.dart';
import 'home/driver_home_screen.dart';
import 'profile/driver_profile_screen.dart';
import 'publish/driver_publish_trip_screen.dart';

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
  final GlobalKey<DriverHomeScreenState> _homeKey =
      GlobalKey<DriverHomeScreenState>();
  final GlobalKey<DriverPublishTripScreenState> _publishKey =
      GlobalKey<DriverPublishTripScreenState>();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DriverHomeScreen(
        key: _homeKey,
        user: widget.user,
        onPublishTap: () => setState(() => _currentIndex = 1),
        onTripsTap: () => setState(() => _currentIndex = 2),
        onProfileTap: () => setState(() => _currentIndex = 4),
      ),
      DriverPublishTripScreen(
        key: _publishKey,
        user: widget.user,
        onTripPublished: () => _homeKey.currentState?.refresh(),
        onViewTripsTap: () => setState(() => _currentIndex = 2),
        onAddVehicleTap: () => setState(() => _currentIndex = 4),
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
          if (index == 1) {
            _publishKey.currentState?.reloadVehicles();
          }
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