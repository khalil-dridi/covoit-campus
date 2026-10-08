import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../widgets/messages/message_badge.dart';
import '../shared/messages/conversations_screen.dart';
import 'home/driver_home_screen.dart';
import 'profile/driver_profile_screen.dart';
import 'publish/driver_publish_trip_screen.dart';
import 'trips/driver_trips_screen.dart';

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
  final GlobalKey<DriverTripsScreenState> _tripsKey =
      GlobalKey<DriverTripsScreenState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
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
        onTripPublished: () {
          _homeKey.currentState?.refresh();
          _tripsKey.currentState?.refresh();
        },
        onAddVehicleTap: () => setState(() => _currentIndex = 4),
      ),
      DriverTripsScreen(
        key: _tripsKey,
        user: widget.user,
        onPublishTap: () => setState(() => _currentIndex = 1),
      ),
      ConversationsScreen(currentUser: widget.user),
      DriverProfileScreen(user: widget.user),
    ];
  }

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
          if (index == 1) {
            _publishKey.currentState?.reloadVehicles();
          }
        },

        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Publier',
          ),
          const NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Mes trajets',
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