import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../widgets/passenger/passenger_header.dart';

class PassengerHomeScreen extends StatelessWidget {
  final User user;

  const PassengerHomeScreen({
    super.key,
    required this.user,
  });

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);
  static const Color lightGreen = Color(0xFFE8F8F1);
  static const Color lightPink = Color(0xFFFFEFF0);
  static const Color lightYellow = Color(0xFFFFF5DE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSearch(context),
              const SizedBox(height: 25),
              const _SectionTitle(title: 'Accès rapides'),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 23),
              _SectionTitle(
                title: 'Votre prochain trajet',
                action: 'Voir tout',
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Mes réservations',
                  message: 'Vos réservations seront disponibles ici.',
                ),
              ),
              const SizedBox(height: 11),
              _buildEmptyState(
                icon: Icons.calendar_today_rounded,
                title: 'Aucun trajet à venir',
                message: 'Vos prochaines réservations apparaîtront ici.',
              ),
              const SizedBox(height: 22),
              _SectionTitle(
                title: 'Trajets recommandés pour vous',
                action: 'Voir tout',
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Trajets recommandés',
                  message: 'Aucun trajet recommandé pour le moment.',
                ),
              ),
              const SizedBox(height: 11),
              _buildEmptyState(
                icon: Icons.explore_outlined,
                title: 'Aucun trajet recommandé',
                message:
                    'Les trajets disponibles apparaîtront ici lorsqu’ils '
                    'correspondront à votre recherche.',
              ),
              const SizedBox(height: 22),
              _buildEcoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSearch(BuildContext context) {
    return Stack(
      children: [
        const SizedBox(height: 276),
        PassengerHeader(
          user: user,
          onNotificationTap: () => _showInfoDialog(
            context,
            title: 'Notifications',
            message: 'Vos notifications seront disponibles ici.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 222, 8, 0),
          child: _buildSearchCard(context),
        ),
      ],
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6ECE9)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.search_rounded, color: green, size: 23),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rechercher un trajet',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Trouver un trajet parmi les étudiants',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _swapButton(context),
            ],
          ),
          const SizedBox(height: 15),
          _buildSearchField(
            context,
            icon: Icons.trip_origin_rounded,
            iconColor: green,
            label: 'Ville de départ',
            value: 'Choisir une ville',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Container(
              height: 10,
              width: 1,
              color: const Color(0xFFD9E4E0),
            ),
          ),
          _buildSearchField(
            context,
            icon: Icons.location_on_rounded,
            iconColor: secondaryBlue,
            label: 'Ville d’arrivée',
            value: 'Choisir une destination',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCompactField(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: 'Date du trajet',
                  value: 'Choisir une date',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _buildCompactField(
                  context,
                  icon: Icons.access_time_rounded,
                  label: 'Heure',
                  value: 'Ajouter une heure',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: ElevatedButton.icon(
              onPressed: () => _showSearchInfo(context),
              icon: const Icon(Icons.search_rounded, size: 19),
              label: const Text(
                'Rechercher un trajet',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swapButton(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: 'Inverser les villes',
        padding: EdgeInsets.zero,
        onPressed: () => _showSearchInfo(context),
        icon: const Icon(
          Icons.swap_vert_rounded,
          color: secondaryBlue,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSearchField(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return _SearchInputSurface(
      onTap: () => _showSearchInfo(context),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: textGrey, size: 19),
        ],
      ),
    );
  }

  Widget _buildCompactField(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return _SearchInputSurface(
      onTap: () => _showSearchInfo(context),
      compact: true,
      child: Row(
        children: [
          Icon(icon, color: secondaryBlue, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.search_rounded,
            title: 'Rechercher\nun trajet',
            foreground: secondaryBlue,
            surface: lightBlue,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.event_available_rounded,
            title: 'Mes\nréservations',
            foreground: green,
            surface: lightGreen,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.favorite_rounded,
            title: 'Mes trajets\nfavoris',
            foreground: const Color(0xFFD85B72),
            surface: lightPink,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.history_rounded,
            title: 'Historique',
            foreground: const Color(0xFFB98522),
            surface: lightYellow,
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color foreground,
    required Color surface,
  }) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showInfoDialog(
          context,
          title: title.replaceAll('\n', ' '),
          message: 'Cette section sera disponible prochainement.',
        ),
        child: SizedBox(
          height: 106,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 23),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 9.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE7)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: secondaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.82),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: green, size: 23),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ensemble pour un campus plus vert',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Le covoiturage réduit les émissions de CO₂ et renforce '
                  'la communauté étudiante.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchInfo(BuildContext context) {
    _showInfoDialog(
      context,
      title: 'Recherche de trajet',
      message:
          'Cette fonctionnalité sera connectée à la recherche de trajets '
          'dans une prochaine étape.',
    );
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: secondaryBlue,
                  size: 29,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.82),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Compris',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _SectionTitle({
    required this.title,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PassengerHomeScreen.primaryBlue,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: PassengerHomeScreen.secondaryBlue,
              padding: const EdgeInsets.only(left: 8),
              minimumSize: const Size(58, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '$action  ›',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _SearchInputSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool compact;

  const _SearchInputSurface({
    required this.child,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCFDFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 52 : 58),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12,
            vertical: compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE7E3)),
          ),
          child: child,
        ),
      ),
    );
  }
}
