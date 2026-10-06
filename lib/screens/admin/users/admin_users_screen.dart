import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/user.dart';
import '../../../repositories/user_repository.dart';

/// Complete Admin User Management module for Covoit Campus.
///
/// Features:
/// - Real SQLite data loading via [UserRepository]
/// - Live aggregate stats (total, passengers, drivers, active, unverified)
/// - Real-time full-text search by full name & email
/// - Filter chips for roles (All, Passengers, Drivers, Admins) and statuses (All, Active, Inactive, Verified, Unverified)
/// - Polished user cards with initials/avatar, role badges, verification & activity state
/// - Modal bottom sheet with complete user profile details & platform activity
/// - Safe account activation/deactivation with confirmation dialog
/// - Strict admin self-protection (cannot deactivate own account)
/// - Fully responsive, mobile-first design matching the Admin Dashboard palette
class AdminUsersScreen extends StatefulWidget {
  final User admin;

  const AdminUsersScreen({
    super.key,
    required this.admin,
  });

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  // ---------------------------------------------------------------------------
  // Design Tokens (strictly aligned with AdminDashboardScreen)
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
  static const double _cardRadius = 18;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final UserRepository _userRepository = UserRepository();
  final TextEditingController _searchController = TextEditingController();

  List<User> _allUsers = const [];
  AdminUserStats? _stats;

  bool _loading = true;
  String? _error;

  String _searchQuery = '';
  String _roleFilter = 'all'; // all, passenger, driver, admin
  String _statusFilter = 'all'; // all, active, inactive, verified, unverified

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Data Loading
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _userRepository.getAllUsers(),
        _userRepository.getAdminUserStats(),
      ]);

      if (!mounted) return;

      setState(() {
        _allUsers = results[0] as List<User>;
        _stats = results[1] as AdminUserStats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger la liste des utilisateurs.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Filter & Search Logic
  // ---------------------------------------------------------------------------

  List<User> get _filteredUsers {
    return _allUsers.where((user) {
      // 1. Search Query (full name or email)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = user.fullName.toLowerCase().contains(q);
        final matchEmail = user.email.toLowerCase().contains(q);
        if (!matchName && !matchEmail) {
          return false;
        }
      }

      // 2. Role Filter
      if (_roleFilter != 'all') {
        if (user.role != _roleFilter) {
          return false;
        }
      }

      // 3. Status Filter
      if (_statusFilter != 'all') {
        switch (_statusFilter) {
          case 'active':
            if (!user.isActive) return false;
            break;
          case 'inactive':
            if (user.isActive) return false;
            break;
          case 'verified':
            if (!user.isVerified) return false;
            break;
          case 'unverified':
            if (user.isVerified) return false;
            break;
        }
      }

      return true;
    }).toList(growable: false);
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _roleFilter = 'all';
      _statusFilter = 'all';
    });
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _roleFilter != 'all' ||
      _statusFilter != 'all';

  // ---------------------------------------------------------------------------
  // Account Activation / Deactivation
  // ---------------------------------------------------------------------------

  Future<void> _toggleUserStatus(User targetUser) async {
    // Safety check: protect logged-in admin
    if (targetUser.id == widget.admin.id) {
      _showSnackBar(
        'Action impossible : vous ne pouvez pas désactiver votre propre compte administrateur.',
        isError: true,
      );
      return;
    }

    final willActivate = !targetUser.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => _StatusConfirmationDialog(
        user: targetUser,
        willActivate: willActivate,
      ),
    );

    if (confirmed != true) return;

    try {
      await _userRepository.setUserActiveStatus(
        targetUser.id!,
        willActivate,
        adminId: widget.admin.id,
      );

      final updatedUser = targetUser.copyWith(
        isActive: willActivate,
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Refresh aggregate stats in background
      final updatedStats = await _userRepository.getAdminUserStats();

      if (!mounted) return;

      setState(() {
        _allUsers = _allUsers
            .map((u) => u.id == targetUser.id ? updatedUser : u)
            .toList(growable: false);
        _stats = updatedStats;
      });

      _showSnackBar(
        willActivate
            ? 'Le compte de ${targetUser.fullName} a été réactivé avec succès.'
            : 'Le compte de ${targetUser.fullName} a été désactivé.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Une erreur est survenue lors de la mise à jour du statut.',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _red : _navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          backgroundColor: Colors.white,
          onRefresh: _loadData,
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
                  child: Center(
                    child: CircularProgressIndicator(color: _blue),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(),
                )
              else ...[
                // Compact real statistics
                if (_stats != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _pageHorizontalPadding,
                      ),
                      child: _buildStatsSection(_stats!),
                    ),
                  ),

                // Search & Filter controls
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _pageHorizontalPadding,
                      18,
                      _pageHorizontalPadding,
                      14,
                    ),
                    child: _buildControlsSection(filtered.length),
                  ),
                ),

                // User list or empty states
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _pageHorizontalPadding,
                        vertical: 36,
                      ),
                      child: _buildEmptyState(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      _pageHorizontalPadding,
                      0,
                      _pageHorizontalPadding,
                      32,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final user = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _UserCard(
                              user: user,
                              isCurrentAdmin: user.id == widget.admin.id,
                              onTap: () => _openUserDetails(user),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _pageHorizontalPadding,
        18,
        _pageHorizontalPadding,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _blueSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.people_alt_rounded,
              color: _blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Utilisateurs',
                  style: TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: _green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Gestion des comptes et des rôles',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _loading ? null : _loadData,
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
  // Real Statistics Row (Compact KPI Grid)
  // ---------------------------------------------------------------------------

  Widget _buildStatsSection(AdminUserStats s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total',
                value: s.totalUsers,
                icon: Icons.groups_rounded,
                color: _blue,
                background: _blueSoft,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Passagers',
                value: s.passengerCount,
                icon: Icons.backpack_rounded,
                color: _navy,
                background: _blueSoft,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Conducteurs',
                value: s.driverCount,
                icon: Icons.directions_car_rounded,
                color: _green,
                background: _greenSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Actifs',
                value: s.activeCount,
                icon: Icons.check_circle_outline_rounded,
                color: _green,
                background: _greenSoft,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'En attente',
                value: s.unverifiedCount,
                icon: Icons.pending_actions_rounded,
                color: s.unverifiedCount > 0 ? _orange : _muted,
                background: s.unverifiedCount > 0 ? _orangeSoft : const Color(0xFFF0F4F8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search Bar & Filter Chips
  // ---------------------------------------------------------------------------

  Widget _buildControlsSection(int matchCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(
              color: _text,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou email...',
              hintStyle: const TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _blue,
                size: 21,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _muted,
                        size: 19,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Role Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _FilterChip(
                label: 'Tous les rôles',
                selected: _roleFilter == 'all',
                onTap: () => setState(() => _roleFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Passagers',
                icon: Icons.backpack_rounded,
                selected: _roleFilter == 'passenger',
                onTap: () => setState(() => _roleFilter = 'passenger'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Conducteurs',
                icon: Icons.directions_car_rounded,
                selected: _roleFilter == 'driver',
                onTap: () => setState(() => _roleFilter = 'driver'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Admins',
                icon: Icons.admin_panel_settings_rounded,
                selected: _roleFilter == 'admin',
                onTap: () => setState(() => _roleFilter = 'admin'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Status Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _FilterChip(
                label: 'Tous les statuts',
                selected: _statusFilter == 'all',
                onTap: () => setState(() => _statusFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Actifs',
                icon: Icons.check_circle_rounded,
                selected: _statusFilter == 'active',
                onTap: () => setState(() => _statusFilter = 'active'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Inactifs',
                icon: Icons.block_rounded,
                selected: _statusFilter == 'inactive',
                onTap: () => setState(() => _statusFilter = 'inactive'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Vérifiés',
                icon: Icons.verified_rounded,
                selected: _statusFilter == 'verified',
                onTap: () => setState(() => _statusFilter = 'verified'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Non vérifiés',
                icon: Icons.mark_email_unread_rounded,
                selected: _statusFilter == 'unverified',
                onTap: () => setState(() => _statusFilter = 'unverified'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Count row with reset button if filters are active
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$matchCount utilisateur${matchCount > 1 ? 's' : ''}',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_hasActiveFilters)
              GestureDetector(
                onTap: _resetFilters,
                child: const Row(
                  children: [
                    Icon(
                      Icons.restore_rounded,
                      size: 14,
                      color: _blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Effacer les filtres',
                      style: TextStyle(
                        color: _blue,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _border),
      ),
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
              Icons.search_off_rounded,
              color: _blue,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aucun compte ne correspond à vos critères de recherche ou de filtre.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Réinitialiser les filtres'),
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error State
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: _red,
                size: 38,
              ),
              const SizedBox(height: 14),
              const Text(
                'Erreur de chargement',
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error ?? 'Une erreur est survenue.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadData,
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // User Details Bottom Sheet
  // ---------------------------------------------------------------------------

  void _openUserDetails(User user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _UserDetailsSheet(
          user: user,
          currentAdmin: widget.admin,
          userRepository: _userRepository,
          onToggleStatus: () {
            Navigator.pop(sheetCtx);
            _toggleUserStatus(user);
          },
        );
      },
    );
  }
}

// =============================================================================
// User Card
// =============================================================================

class _UserCard extends StatelessWidget {
  final User user;
  final bool isCurrentAdmin;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.isCurrentAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _extractInitials(user.fullName);
    final roleColor = _getRoleColor(user.role);
    final roleSoft = _getRoleSoft(user.role);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_AdminUsersScreenState._cardRadius),
        border: Border.all(
          color: isCurrentAdmin
              ? _AdminUsersScreenState._purple.withValues(alpha: 0.35)
              : _AdminUsersScreenState._border,
        ),
        boxShadow: [
          BoxShadow(
            color: _AdminUsersScreenState._navy.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_AdminUsersScreenState._cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_AdminUsersScreenState._cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with role accent
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: roleSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Name & You/Status pill
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _AdminUsersScreenState._text,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isCurrentAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _AdminUsersScreenState._purpleSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Vous',
                                style: TextStyle(
                                  color: _AdminUsersScreenState._purple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else if (!user.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _AdminUsersScreenState._redSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Inactif',
                                style: TextStyle(
                                  color: _AdminUsersScreenState._red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Email
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _AdminUsersScreenState._muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 9),

                      // Badges row: Role & Verification & Date
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _RoleBadge(role: user.role),
                          _VerificationBadge(isVerified: user.isVerified),
                          Text(
                            _formatDateShort(user.createdAt),
                            style: const TextStyle(
                              color: _AdminUsersScreenState._muted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Trailing chevron
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _AdminUsersScreenState._muted,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// User Details Modal Bottom Sheet
// =============================================================================

class _UserDetailsSheet extends StatefulWidget {
  final User user;
  final User currentAdmin;
  final UserRepository userRepository;
  final VoidCallback onToggleStatus;

  const _UserDetailsSheet({
    required this.user,
    required this.currentAdmin,
    required this.userRepository,
    required this.onToggleStatus,
  });

  @override
  State<_UserDetailsSheet> createState() => _UserDetailsSheetState();
}

class _UserDetailsSheetState extends State<_UserDetailsSheet> {
  Map<String, int>? _activityCounts;
  bool _loadingActivity = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    if (widget.user.id == null) return;
    try {
      final counts = await widget.userRepository.getUserActivityCounts(
        widget.user.id!,
      );
      if (!mounted) return;
      setState(() {
        _activityCounts = counts;
        _loadingActivity = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingActivity = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isSelf = user.id == widget.currentAdmin.id;
    final roleColor = _getRoleColor(user.role);
    final roleSoft = _getRoleSoft(user.role);
    final initials = _extractInitials(user.fullName);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0DCE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // User Header Banner
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: roleSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            color: _AdminUsersScreenState._text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: _AdminUsersScreenState._muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _RoleBadge(role: user.role),
                            _StatusBadge(isActive: user.isActive),
                            _VerificationBadge(isVerified: user.isVerified),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: _AdminUsersScreenState._border, height: 1),
              const SizedBox(height: 18),

              // Section: General Information
              const _SectionLabel(title: 'Informations générales'),
              const SizedBox(height: 10),
              _DetailTile(
                icon: Icons.badge_outlined,
                label: 'Identifiant système',
                value: user.id != null ? '#${user.id}' : 'N/A',
              ),
              _DetailTile(
                icon: Icons.phone_outlined,
                label: 'Numéro de téléphone',
                value: user.phone?.trim().isNotEmpty == true
                    ? user.phone!.trim()
                    : 'Non renseigné',
              ),
              _DetailTile(
                icon: Icons.school_outlined,
                label: 'Université / Établissement',
                value: user.university?.trim().isNotEmpty == true
                    ? user.university!.trim()
                    : 'Non renseignée',
              ),
              _DetailTile(
                icon: Icons.calendar_today_outlined,
                label: 'Date d’inscription',
                value: _formatDateFull(user.createdAt),
              ),
              _DetailTile(
                icon: Icons.update_rounded,
                label: 'Dernière mise à jour',
                value: _formatDateFull(user.updatedAt),
              ),

              const SizedBox(height: 18),

              // Section: Activity on platform
              const _SectionLabel(title: 'Activité sur Covoit Campus'),
              const SizedBox(height: 10),
              if (_loadingActivity)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _AdminUsersScreenState._blue,
                      ),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _ActivityBox(
                        label: 'Trajets',
                        count: _activityCounts?['trips'] ?? 0,
                        icon: Icons.route_rounded,
                        color: _AdminUsersScreenState._green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActivityBox(
                        label: 'Réservations',
                        count: _activityCounts?['bookings'] ?? 0,
                        icon: Icons.confirmation_number_rounded,
                        color: _AdminUsersScreenState._blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActivityBox(
                        label: 'Véhicules',
                        count: _activityCounts?['vehicles'] ?? 0,
                        icon: Icons.directions_car_rounded,
                        color: _AdminUsersScreenState._purple,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),
              const Divider(color: _AdminUsersScreenState._border, height: 1),
              const SizedBox(height: 18),

              // Section: Actions & Safety
              const _SectionLabel(title: 'Actions administratives'),
              const SizedBox(height: 10),

              if (isSelf) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _AdminUsersScreenState._purpleSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _AdminUsersScreenState._purple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: _AdminUsersScreenState._purple,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Vous êtes connecté sur ce compte administrateur. Pour garantir l’accès au système, ce compte ne peut être ni désactivé ni rétrogradé.',
                          style: TextStyle(
                            color: _AdminUsersScreenState._purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: user.isActive
                      ? OutlinedButton.icon(
                          onPressed: widget.onToggleStatus,
                          icon: const Icon(Icons.person_off_rounded, size: 18),
                          label: const Text('Désactiver ce compte'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _AdminUsersScreenState._red,
                            side: const BorderSide(
                              color: _AdminUsersScreenState._red,
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: widget.onToggleStatus,
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Réactiver ce compte'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _AdminUsersScreenState._green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    user.isActive
                        ? 'La désactivation bloque immédiatement l’accès à l’application.'
                        : 'La réactivation rétablit l’accès de l’utilisateur.',
                    style: const TextStyle(
                      color: _AdminUsersScreenState._muted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: _AdminUsersScreenState._muted,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
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

// =============================================================================
// Status Confirmation Dialog
// =============================================================================

class _StatusConfirmationDialog extends StatelessWidget {
  final User user;
  final bool willActivate;

  const _StatusConfirmationDialog({
    required this.user,
    required this.willActivate,
  });

  @override
  Widget build(BuildContext context) {
    final title = willActivate
        ? 'Réactiver le compte ?'
        : 'Désactiver le compte ?';

    final message = willActivate
        ? 'L’utilisateur ${user.fullName} (${user.email}) pourra de nouveau se connecter et utiliser l’application Covoit Campus.\n\nConfirmer la réactivation ?'
        : 'L’utilisateur ${user.fullName} (${user.email}) ne pourra plus se connecter à Covoit Campus tant que son compte restera inactif.\n\nConfirmer la désactivation ?';

    final iconColor = willActivate
        ? _AdminUsersScreenState._green
        : _AdminUsersScreenState._red;

    final iconBg = willActivate
        ? _AdminUsersScreenState._greenSoft
        : _AdminUsersScreenState._redSoft;

    final icon = willActivate
        ? Icons.check_circle_rounded
        : Icons.person_off_rounded;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _AdminUsersScreenState._text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _AdminUsersScreenState._muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _AdminUsersScreenState._text,
                  side: const BorderSide(color: _AdminUsersScreenState._border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  willActivate ? 'Réactiver' : 'Désactiver',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Helper Widgets & Badges
// =============================================================================

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AdminUsersScreenState._border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: _AdminUsersScreenState._text,
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AdminUsersScreenState._muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _AdminUsersScreenState._navy : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? _AdminUsersScreenState._navy
                  : _AdminUsersScreenState._border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected
                      ? Colors.white
                      : _AdminUsersScreenState._muted,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : _AdminUsersScreenState._text,
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);
    final bg = _getRoleSoft(role);
    final label = _getRoleLabel(role);
    final icon = _getRoleIcon(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final bool isVerified;

  const _VerificationBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final color = isVerified
        ? _AdminUsersScreenState._green
        : _AdminUsersScreenState._orange;
    final bg = isVerified
        ? _AdminUsersScreenState._greenSoft
        : _AdminUsersScreenState._orangeSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.pending_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3.5),
          Text(
            isVerified ? 'Vérifié' : 'Non vérifié',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? _AdminUsersScreenState._green
        : _AdminUsersScreenState._red;
    final bg = isActive
        ? _AdminUsersScreenState._greenSoft
        : _AdminUsersScreenState._redSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        isActive ? 'Actif' : 'Désactivé',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _AdminUsersScreenState._text,
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: _AdminUsersScreenState._muted,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _AdminUsersScreenState._muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    color: _AdminUsersScreenState._text,
                    fontSize: 13,
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
}

class _ActivityBox extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _ActivityBox({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AdminUsersScreenState._border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: _AdminUsersScreenState._text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AdminUsersScreenState._muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pure Helpers
// -----------------------------------------------------------------------------

Color _getRoleColor(String role) {
  switch (role) {
    case 'driver':
      return _AdminUsersScreenState._green;
    case 'admin':
      return _AdminUsersScreenState._purple;
    default:
      return _AdminUsersScreenState._blue;
  }
}

Color _getRoleSoft(String role) {
  switch (role) {
    case 'driver':
      return _AdminUsersScreenState._greenSoft;
    case 'admin':
      return _AdminUsersScreenState._purpleSoft;
    default:
      return _AdminUsersScreenState._blueSoft;
  }
}

String _getRoleLabel(String role) {
  switch (role) {
    case 'driver':
      return 'Conducteur';
    case 'admin':
      return 'Admin';
    default:
      return 'Passager';
  }
}

IconData _getRoleIcon(String role) {
  switch (role) {
    case 'driver':
      return Icons.directions_car_rounded;
    case 'admin':
      return Icons.admin_panel_settings_rounded;
    default:
      return Icons.backpack_rounded;
  }
}

String _extractInitials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _formatDateShort(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  return 'Inscrit le ${DateFormat('dd/MM/yyyy').format(dt)}';
}

String _formatDateFull(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  return DateFormat('dd/MM/yyyy à HH:mm').format(dt);
}
