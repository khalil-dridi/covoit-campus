import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/user.dart';
import '../../../repositories/message_repository.dart';
import '../../../widgets/profile/user_profile_preview.dart';
import 'chat_screen.dart';

// =============================================================================
// ConversationsScreen
//
// Shows the full conversation inbox for a given user.
// Reusable by both Passenger and Driver — role-specific text is derived
// from currentUser.role at runtime.
//
// No SQL is inlined here; all data access goes through MessageRepository.
// =============================================================================

class ConversationsScreen extends StatefulWidget {
  final User currentUser;

  const ConversationsScreen({super.key, required this.currentUser});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

// =============================================================================
// State
// =============================================================================

class _ConversationsScreenState extends State<ConversationsScreen> {
  // ---------------------------------------------------------------------------
  // Design tokens — exact same palette as the rest of the project.
  // ---------------------------------------------------------------------------

  static const Color _primaryBlue = Color(0xFF123D68);
  static const Color _secondaryBlue = Color(0xFF1E5AA8);
  static const Color _green = Color(0xFF20B978);
  static const Color _background = Color(0xFFF4FFFB);
  static const Color _textGrey = Color(0xFF547080);
  static const Color _lightBlue = Color(0xFFEAF3FC);
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final MessageRepository _repository = MessageRepository();
  List<ConversationSummary> _conversations = const [];
  bool _loading = true;
  String? _error;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    MessageRepository.changes.addListener(_loadConversations);
    _loadConversations();
  }

  @override
  void dispose() {
    MessageRepository.changes.removeListener(_loadConversations);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadConversations() async {
    final userId = widget.currentUser.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible d\'identifier votre compte.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final conversations = await _repository.getConversationsForUser(userId);
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger vos conversations.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation — open a conversation, then refresh the list on return.
  // ---------------------------------------------------------------------------

  Future<void> _openConversation(ConversationSummary summary) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          tripId: summary.tripId,
          rideRequestId: summary.rideRequestId,
          currentUser: widget.currentUser,
          otherUserId: summary.otherUserId,
          otherUserName: summary.otherUserName,
          tripDeparture: summary.tripDeparture,
          tripDestination: summary.tripDestination,
          requestDeparture: summary.isRideRequest
              ? summary.tripDeparture
              : null,
          requestDestination: summary.isRideRequest
              ? summary.tripDestination
              : null,
          requestDate: summary.requestDate,
          requestTime: summary.requestTime,
          requestSeats: summary.requestedSeats,
        ),
      ),
    );

    // Refresh after the user returns from ChatScreen so that unread counts
    // are up-to-date (ChatScreen already marks messages as read on entry).
    if (!mounted) return;
    _loadConversations();
  }

  // ---------------------------------------------------------------------------
  // Role-aware helpers
  // ---------------------------------------------------------------------------

  bool get _isDriver => widget.currentUser.role == 'driver';

  String get _emptyTitle =>
      _isDriver ? 'Aucune conversation' : 'Aucune conversation';

  String get _emptySubtitle => _isDriver
      ? 'Vous n\'avez encore aucune conversation avec vos passagers.'
      : 'Vous n\'avez encore aucune conversation.';

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header — consistent with every other screen in the project.
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages',
            style: TextStyle(
              color: _primaryBlue,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isDriver
                ? 'Vos conversations avec vos passagers.'
                : 'Vos conversations avec vos conducteurs.',
            style: TextStyle(
              color: _textGrey.withValues(alpha: 0.82),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 17),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body — dispatcher between loading / error / list.
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    if (_loading) return _buildLoadingState();
    if (_error != null) return _buildErrorState(_error!);

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadConversations,
      child: _conversations.isEmpty
          ? _buildEmptyState()
          : _buildConversationList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator(color: _green));

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: _secondaryBlue, size: 42),
          const SizedBox(height: 14),
          const Text(
            'Impossible de charger vos conversations',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textGrey, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadConversations,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _secondaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Empty — scrollable so RefreshIndicator works on it too.
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: constraints.maxHeight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: _green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _emptyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _emptySubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textGrey.withValues(alpha: 0.82),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Conversation list
  // ---------------------------------------------------------------------------

  Widget _buildConversationList() => ListView.separated(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(19, 0, 19, 26),
    itemCount: _conversations.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (context, index) =>
        _buildConversationCard(_conversations[index]),
  );

  // ---------------------------------------------------------------------------
  // Conversation card
  // ---------------------------------------------------------------------------

  Widget _buildConversationCard(ConversationSummary summary) {
    final hasUnread = summary.unreadCount > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openConversation(summary),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasUnread
                  ? _secondaryBlue.withValues(alpha: 0.22)
                  : const Color(0xFFE2EBE7),
              width: hasUnread ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.045),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------------
              // Avatar
              // ----------------------------------------------------------------
              UserProfileTarget(
                userId: summary.otherUserId,
                enabled: widget.currentUser.role == 'passenger',
                borderRadius: BorderRadius.circular(28),
                child: _buildAvatar(summary.otherUserName),
              ),

              const SizedBox(width: 12),

              // ----------------------------------------------------------------
              // Main content
              // ----------------------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + timestamp row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: UserProfileTarget(
                            userId: summary.otherUserId,
                            enabled: widget.currentUser.role == 'passenger',
                            borderRadius: BorderRadius.circular(6),
                            child: Text(
                              summary.otherUserName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 14,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(summary.lastMessageAt),
                          style: TextStyle(
                            color: hasUnread
                                ? _secondaryBlue
                                : _textGrey.withValues(alpha: 0.70),
                            fontSize: 10.5,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Trip route
                    Row(
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          color: _secondaryBlue,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${summary.isRideRequest ? 'Demande' : 'Trajet'} · '
                            '${summary.tripDeparture} → ${summary.tripDestination}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _secondaryBlue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Last message + unread badge row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            summary.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasUnread
                                  ? _primaryBlue
                                  : _textGrey.withValues(alpha: 0.80),
                              fontSize: 12,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          _buildUnreadBadge(summary.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar — initials-based fallback consistent with the rest of the app.
  // ---------------------------------------------------------------------------

  Widget _buildAvatar(String name) {
    final initials = _initials(name);
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: _lightBlue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: initials.isEmpty
            ? const Icon(Icons.person_rounded, color: _secondaryBlue, size: 24)
            : Text(
                initials,
                style: const TextStyle(
                  color: _secondaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Unread badge
  // ---------------------------------------------------------------------------

  Widget _buildUnreadBadge(int count) => Container(
    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
    padding: const EdgeInsets.symmetric(horizontal: 5),
    decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Timestamp formatter
  //
  //   Same day   → "HH:mm"
  //   This year  → "dd MMM" (e.g. "06 Oct")
  //   Older      → "dd/MM/yy"
  // ---------------------------------------------------------------------------

  String _formatTimestamp(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);

    if (msgDay == today) {
      return DateFormat('HH:mm').format(date);
    }
    if (date.year == now.year) {
      return DateFormat('dd MMM', 'fr_FR').format(date);
    }
    return DateFormat('dd/MM/yy').format(date);
  }

  // ---------------------------------------------------------------------------
  // Initials helper — first letter of first and last word.
  // ---------------------------------------------------------------------------

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    }
    final first = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final last = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    return '$first$last';
  }
}
