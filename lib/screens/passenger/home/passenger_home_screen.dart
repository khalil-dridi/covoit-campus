import 'package:flutter/material.dart';

class PassengerHomeScreen extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onReservationsTap;

  const PassengerHomeScreen({
    super.key,
    this.onSearchTap,
    this.onReservationsTap,
  });

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);
  static const Color lightGreen = Color(0xFFE8F8F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                28,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildHeader(context),

                    const SizedBox(height: 26),

                    _buildSearchCard(context),

                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      title: 'Votre prochain trajet',
                      actionText: 'Voir tout',
                      onTap: onReservationsTap,
                    ),

                    const SizedBox(height: 14),

                    _buildUpcomingTrip(context),

                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      title: 'Trajets recommandés',
                      actionText: 'Explorer',
                      onTap: onSearchTap,
                    ),

                    const SizedBox(height: 14),

                    _buildRecommendations(),

                    const SizedBox(height: 28),

                    _buildEcoCard(),

                    const SizedBox(height: 24),

                    _buildSafetyCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour Khalil 👋',
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prêt pour votre prochain trajet ?',
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.78),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE0ECE7),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              IconButton(
                onPressed: () {
                  _showInfoDialog(
                    context,
                    title: 'Notifications',
                    message:
                        'Vos notifications apparaîtront ici.',
                    icon: Icons.notifications_none_rounded,
                  );
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: primaryBlue,
                  size: 23,
                ),
              ),

              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SEARCH CARD
  // ==========================================================

  Widget _buildSearchCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue,
            secondaryBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trouver un trajet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Trouvez un conducteur près de vous',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildLocationField(
            icon: Icons.radio_button_checked_rounded,
            label: 'Départ',
            value: 'Votre position',
            color: green,
          ),

          const SizedBox(height: 10),

          _buildLocationField(
            icon: Icons.location_on_rounded,
            label: 'Destination',
            value: 'Où allez-vous ?',
            color: Colors.white,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildSmallInfo(
                  icon: Icons.calendar_today_outlined,
                  text: 'Aujourd’hui',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildSmallInfo(
                  icon: Icons.access_time_rounded,
                  text: '08:30',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onSearchTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Rechercher un trajet',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LOCATION FIELD
  // ==========================================================

  Widget _buildLocationField({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SMALL INFO
  // ==========================================================

  Widget _buildSmallInfo({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          Icon(
            icon,
            size: 15,
            color: Colors.white70,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION HEADER
  // ==========================================================

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: secondaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // UPCOMING TRIP
  // ==========================================================

  Widget _buildUpcomingTrip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE0ECE7),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: primaryBlue,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demain • 08:30',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tunis → Ariana',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Confirmé',
                  style: TextStyle(
                    color: green,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildTripPoint(
                color: secondaryBlue,
                title: 'Tunis Centre',
                subtitle: '08:30',
              ),

              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  color: const Color(0xFFDCE7E3),
                ),
              ),

              _buildTripPoint(
                color: green,
                title: 'Ariana',
                subtitle: '09:00',
                isEnd: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onReservationsTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(
                  color: Color(0xFFD8E6E1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Voir le trajet',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TRIP POINT
  // ==========================================================

  Widget _buildTripPoint({
    required Color color,
    required String title,
    required String subtitle,
    bool isEnd = false,
  }) {
    return Column(
      crossAxisAlignment: isEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          title,
          style: const TextStyle(
            color: primaryBlue,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          subtitle,
          style: TextStyle(
            color: textGrey.withValues(alpha: 0.7),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // RECOMMENDATIONS
  // ==========================================================

  Widget _buildRecommendations() {
    return SizedBox(
      height: 172,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildRecommendationCard(
            destination: 'La Marsa',
            departure: 'Tunis',
            time: '07:45',
            price: '4.500 DT',
            seats: '2 places',
            icon: Icons.waves_rounded,
          ),

          const SizedBox(width: 12),

          _buildRecommendationCard(
            destination: 'Manouba',
            departure: 'Ariana',
            time: '08:15',
            price: '3.000 DT',
            seats: '3 places',
            icon: Icons.school_rounded,
          ),

          const SizedBox(width: 12),

          _buildRecommendationCard(
            destination: 'Berges du Lac',
            departure: 'Centre-ville',
            time: '09:00',
            price: '5.000 DT',
            seats: '1 place',
            icon: Icons.business_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({
    required String destination,
    required String departure,
    required String time,
    required String price,
    required String seats,
    required IconData icon,
  }) {
    return Container(
      width: 235,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE0ECE7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: green,
                  size: 20,
                ),
              ),

              const Spacer(),

              Text(
                price,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            '$departure → $destination',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: textGrey,
              ),
              const SizedBox(width: 5),
              Text(
                time,
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.78),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.event_seat_outlined,
                size: 14,
                color: textGrey,
              ),
              const SizedBox(width: 5),
              Text(
                seats,
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.78),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ECO CARD
  // ==========================================================

  Widget _buildEcoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: green.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: green,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre impact positif 🌱',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Vous avez déjà contribué à réduire '
                  'votre empreinte carbone.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
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

  // ==========================================================
  // SAFETY CARD
  // ==========================================================

  Widget _buildSafetyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE0ECE7),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: secondaryBlue,
            size: 21,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Tous les membres sont vérifiés pour '
              'une expérience plus sûre.',
              style: TextStyle(
                color: textGrey.withValues(alpha: 0.78),
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFO DIALOG
  // ==========================================================

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: secondaryBlue,
                    size: 30,
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
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}