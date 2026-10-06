
import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../repositories/admin_repository.dart';

/// Admin dashboard for Covoit Campus.
///
/// UI-only refactor:
/// - Keeps the existing AdminRepository and AdminStats flow.
/// - Does not introduce any new dependency.
/// - Uses real values already exposed by AdminStats.
/// - Optimized for mobile screens.
class AdminDashboardScreen extends StatefulWidget {
  final User admin;

  const AdminDashboardScreen({
    super.key,
    required this.admin,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ---------------------------------------------------------------------------
  // Design system
  // ---------------------------------------------------------------------------

  static const Color _navy = Color(0xFF123D68);
  static const Color _blue = Color(0xFF1E5AA8);
  static const Color _blueSoft = Color(0xFFEAF3FC);

  static const Color _green = Color(0xFF18A974);
  static const Color _greenSoft = Color(0xFFEAF8F1);

  static const Color _orange = Color(0xFFD89228);
  static const Color _orangeSoft = Color(0xFFFFF5E8);

  static const Color _red = Color(0xFFC94A4A);
  static const Color _redSoft = Color(0xFFFFEEEE);

  static const Color _purple = Color(0xFF7A63A8);
  static const Color _purpleSoft = Color(0xFFF1EDFA);

  static const Color _background = Color(0xFFF6F9FC);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE6EDF3);
  static const Color _text = Color(0xFF183B5E);
  static const Color _muted = Color(0xFF71879A);

  static const double _pageHorizontalPadding = 18;
  static const double _sectionGap = 22;
  static const double _cardRadius = 20;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final AdminRepository _repository = AdminRepository();

  AdminStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final stats = await _repository.loadStats();

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les statistiques.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          backgroundColor: Colors.white,
          onRefresh: _loadStats,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadingView(),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(),
                )
              else if (_stats != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    _pageHorizontalPadding,
                    0,
                    _pageHorizontalPadding,
                    32,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _buildOverviewSection(_stats!),
                        const SizedBox(height: _sectionGap),
                        _buildAttentionCard(_stats!),
                        const SizedBox(height: _sectionGap),
                        _buildPlatformVolumeCard(_stats!),
                        const SizedBox(height: _sectionGap),
                        _buildUsersCard(_stats!),
                        const SizedBox(height: 14),
                        _buildTripsCard(_stats!),
                        const SizedBox(height: 14),
                        _buildBookingsCard(_stats!),
                        const SizedBox(height: 14),
                        _buildReportsCard(_stats!),
                        const SizedBox(height: 24),
                        _buildDataFooter(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    final fullName = widget.admin.fullName.trim();
    final firstName = fullName.isEmpty
        ? 'Administrateur'
        : fullName.split(RegExp(r'\s+')).first;

    final initials = _initials(fullName.isEmpty ? 'Administrateur' : fullName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _pageHorizontalPadding,
        18,
        _pageHorizontalPadding,
        18,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _blueSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: _blue,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $firstName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: _green,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Vue administrateur · données en temps réel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _loading ? null : _loadStats,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: _loading ? _muted : _blue,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Overview
  // ---------------------------------------------------------------------------

  Widget _buildOverviewSection(AdminStats s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Vue d’ensemble',
          subtitle: 'Les indicateurs essentiels de Covoit Campus',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 650 ? 4 : 2;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: crossAxisCount == 4 ? 1.55 : 1.48,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _KpiCard(
                  icon: Icons.people_alt_rounded,
                  iconColor: _blue,
                  iconBackground: _blueSoft,
                  label: 'Utilisateurs',
                  value: s.totalUsers,
                ),
                _KpiCard(
                  icon: Icons.route_rounded,
                  iconColor: _green,
                  iconBackground: _greenSoft,
                  label: 'Trajets',
                  value: s.totalTrips,
                ),
                _KpiCard(
                  icon: Icons.confirmation_number_rounded,
                  iconColor: _purple,
                  iconBackground: _purpleSoft,
                  label: 'Réservations',
                  value: s.totalBookings,
                ),
                _KpiCard(
                  icon: Icons.flag_rounded,
                  iconColor: s.pendingReports > 0 ? _red : _green,
                  iconBackground:
                      s.pendingReports > 0 ? _redSoft : _greenSoft,
                  label: 'À surveiller',
                  value: s.pendingReports,
                  valueColor: s.pendingReports > 0 ? _red : _text,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Attention / priority area
  // ---------------------------------------------------------------------------

  Widget _buildAttentionCard(AdminStats s) {
    final hasPendingBookings = s.pendingBookings > 0;
    final hasPendingReports = s.pendingReports > 0;
    final hasAttention = hasPendingBookings || hasPendingReports;

    if (!hasAttention) {
      return _SurfaceCard(
        child: Row(
          children: [
            const _StatusIcon(
              icon: Icons.check_rounded,
              color: _green,
              background: _greenSoft,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tout est en ordre',
                    style: TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Aucune action urgente à traiter pour le moment.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _SurfaceCard(
      borderColor: _orange.withValues(alpha: 0.28),
      backgroundColor: const Color(0xFFFFFCF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _StatusIcon(
                icon: Icons.priority_high_rounded,
                color: _orange,
                background: _orangeSoft,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'À traiter',
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (hasPendingBookings)
            _AttentionRow(
              icon: Icons.hourglass_top_rounded,
              color: _orange,
              title: '${s.pendingBookings} réservation'
                  '${s.pendingBookings > 1 ? 's' : ''} en attente',
              subtitle: 'Une demande nécessite une vérification.',
            ),
          if (hasPendingBookings && hasPendingReports)
            const SizedBox(height: 10),
          if (hasPendingReports)
            _AttentionRow(
              icon: Icons.report_problem_rounded,
              color: _red,
              title: '${s.pendingReports} signalement'
                  '${s.pendingReports > 1 ? 's' : ''} en attente',
              subtitle: 'Un signalement nécessite une intervention.',
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Platform volume
  // ---------------------------------------------------------------------------

  Widget _buildPlatformVolumeCard(AdminStats s) {
    final maxValue = _max3(
      s.totalUsers,
      s.totalTrips,
      s.totalBookings,
    );

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Volume actuel',
            subtitle: 'Répartition des principaux volumes',
          ),
          const SizedBox(height: 18),
          _VolumeRow(
            icon: Icons.people_alt_rounded,
            iconColor: _blue,
            iconBackground: _blueSoft,
            label: 'Utilisateurs',
            value: s.totalUsers,
            maxValue: maxValue,
          ),
          const SizedBox(height: 14),
          _VolumeRow(
            icon: Icons.route_rounded,
            iconColor: _green,
            iconBackground: _greenSoft,
            label: 'Trajets',
            value: s.totalTrips,
            maxValue: maxValue,
          ),
          const SizedBox(height: 14),
          _VolumeRow(
            icon: Icons.confirmation_number_rounded,
            iconColor: _purple,
            iconBackground: _purpleSoft,
            label: 'Réservations',
            value: s.totalBookings,
            maxValue: maxValue,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  Widget _buildUsersCard(AdminStats s) {
    final others = (s.totalUsers - s.passengerCount - s.driverCount)
        .clamp(0, s.totalUsers)
        .toInt();

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Utilisateurs',
            subtitle: 'Composition de la communauté',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.totalUsers}',
                style: const TextStyle(
                  color: _text,
                  fontSize: 32,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'utilisateurs',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SegmentedBar(
            segments: [
              _Segment(
                value: s.passengerCount,
                color: _blue,
              ),
              _Segment(
                value: s.driverCount,
                color: _green,
              ),
              _Segment(
                value: others,
                color: _border,
              ),
            ],
            total: s.totalUsers,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(
                color: _blue,
                label: 'Passagers',
                value: s.passengerCount,
              ),
              _LegendItem(
                color: _green,
                label: 'Conducteurs',
                value: s.driverCount,
              ),
              if (others > 0)
                _LegendItem(
                  color: _muted,
                  label: 'Autres',
                  value: others,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Trips
  // ---------------------------------------------------------------------------

  Widget _buildTripsCard(AdminStats s) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Trajets',
            subtitle: 'État actuel des trajets publiés',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.event_available_rounded,
                  label: 'Disponibles',
                  value: s.availableTrips,
                  color: _green,
                  background: _greenSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.check_circle_rounded,
                  label: 'Terminés',
                  value: s.completedTrips,
                  color: _purple,
                  background: _purpleSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.cancel_rounded,
                  label: 'Annulés',
                  value: s.cancelledTrips,
                  color: _red,
                  background: _redSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DistributionLine(
            label: 'Disponibles',
            value: s.availableTrips,
            total: s.totalTrips,
            color: _green,
          ),
          const SizedBox(height: 9),
          _DistributionLine(
            label: 'Terminés',
            value: s.completedTrips,
            total: s.totalTrips,
            color: _purple,
          ),
          const SizedBox(height: 9),
          _DistributionLine(
            label: 'Annulés',
            value: s.cancelledTrips,
            total: s.totalTrips,
            color: _red,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bookings
  // ---------------------------------------------------------------------------

  Widget _buildBookingsCard(AdminStats s) {
    final remaining = (s.totalBookings - s.acceptedBookings - s.pendingBookings)
        .clamp(0, s.totalBookings)
        .toInt();

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Réservations',
            subtitle: 'Suivi des demandes de réservation',
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BookingSummary(
                value: s.totalBookings,
                label: 'Total',
                color: _blue,
              ),
              const Spacer(),
              _InlineCount(
                label: 'Acceptées',
                value: s.acceptedBookings,
                color: _green,
              ),
              const SizedBox(width: 18),
              _InlineCount(
                label: 'En attente',
                value: s.pendingBookings,
                color: s.pendingBookings > 0 ? _orange : _muted,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SegmentedBar(
            segments: [
              _Segment(
                value: s.acceptedBookings,
                color: _green,
              ),
              _Segment(
                value: s.pendingBookings,
                color: _orange,
              ),
              _Segment(
                value: remaining,
                color: _border,
              ),
            ],
            total: s.totalBookings,
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 9),
            Text(
              '$remaining autre${remaining > 1 ? 's' : ''} statut'
              '${remaining > 1 ? 's' : ''}',
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------

  Widget _buildReportsCard(AdminStats s) {
    final resolved = (s.totalReports - s.pendingReports)
        .clamp(0, s.totalReports)
        .toInt();

    final hasPending = s.pendingReports > 0;

    return _SurfaceCard(
      borderColor: hasPending ? _red.withValues(alpha: 0.22) : _border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StatusIcon(
            icon: hasPending
                ? Icons.report_problem_rounded
                : Icons.verified_rounded,
            color: hasPending ? _red : _green,
            background: hasPending ? _redSoft : _greenSoft,
            size: 46,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending
                      ? 'Signalements à traiter'
                      : 'Aucun signalement en attente',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPending
                      ? '${s.pendingReports} en attente sur ${s.totalReports} au total.'
                      : 'La plateforme ne présente aucun problème signalé.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.totalReports}',
                style: const TextStyle(
                  color: _text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                resolved == 0 ? 'total' : '$resolved traité${resolved > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildDataFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: _muted,
        ),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Statistiques calculées depuis les données locales de Covoit Campus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: _SurfaceCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _blueSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: _blue,
                  size: 27,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger les statistiques',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _error ?? 'Réessayez dans quelques instants.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Réessayer'),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  static int _max3(int a, int b, int c) {
    var result = a;
    if (b > result) result = b;
    if (c > result) result = c;
    return result;
  }
}

// =============================================================================
// Reusable UI components
// =============================================================================

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  const _SurfaceCard({
    required this.child,
    this.backgroundColor = _AdminDashboardScreenState._surface,
    this.borderColor = _AdminDashboardScreenState._border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          _AdminDashboardScreenState._cardRadius,
        ),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: _AdminDashboardScreenState._navy.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _AdminDashboardScreenState._text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: _AdminDashboardScreenState._muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CardTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _AdminDashboardScreenState._text,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: _AdminDashboardScreenState._muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final int value;
  final Color valueColor;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    this.valueColor = _AdminDashboardScreenState._text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AdminDashboardScreenState._border),
        boxShadow: [
          BoxShadow(
            color: _AdminDashboardScreenState._navy.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AdminDashboardScreenState._muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const _StatusIcon({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.45,
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _AttentionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _AdminDashboardScreenState._text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _AdminDashboardScreenState._muted,
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final int value;
  final int maxValue;

  const _VolumeRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxValue <= 0
        ? 0.0
        : (value / maxValue).clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: _AdminDashboardScreenState._text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: _AdminDashboardScreenState._text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: _AdminDashboardScreenState._border,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment {
  final int value;
  final Color color;

  const _Segment({
    required this.value,
    required this.color,
  });
}

class _SegmentedBar extends StatelessWidget {
  final List<_Segment> segments;
  final int total;

  const _SegmentedBar({
    required this.segments,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 9,
        child: Row(
          children: [
            for (final segment in segments)
              if (segment.value > 0)
                Expanded(
                  flex: segment.value,
                  child: ColoredBox(color: segment.color),
                )
              else
                const SizedBox.shrink(),
            if (total <= 0) const Expanded(child: ColoredBox(color: _AdminDashboardScreenState._border)),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $value',
          style: const TextStyle(
            color: _AdminDashboardScreenState._muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final Color background;

  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 7),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AdminDashboardScreenState._muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionLine extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _DistributionLine({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0
        ? 0.0
        : (value / total).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _AdminDashboardScreenState._muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value / $total',
              style: const TextStyle(
                color: _AdminDashboardScreenState._text,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: _AdminDashboardScreenState._border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _BookingSummary extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _BookingSummary({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _AdminDashboardScreenState._blueSoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.confirmation_number_rounded,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: _AdminDashboardScreenState._text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: _AdminDashboardScreenState._muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InlineCount extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _InlineCount({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: _AdminDashboardScreenState._muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _AdminDashboardScreenState._blue,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Chargement des statistiques…',
              style: TextStyle(
                color: _AdminDashboardScreenState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}