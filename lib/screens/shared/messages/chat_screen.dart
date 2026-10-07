import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/message.dart';
import '../../../models/user.dart';
import '../../../repositories/message_repository.dart';

// =============================================================================
// ChatScreen
//
// A reusable screen that renders a trip-based conversation between two users.
// Used by both Passenger and Driver roles — the caller decides which IDs
// to pass in.
//
// The screen talks exclusively to MessageRepository; no SQL is inlined here.
// =============================================================================

class ChatScreen extends StatefulWidget {
  /// The trip this conversation belongs to.
  final int? tripId;
  final int? rideRequestId;

  /// The currently authenticated user (sender).
  final User currentUser;

  /// The other participant's user id.
  final int otherUserId;

  /// Display name for the other participant (shown in the header).
  final String otherUserName;

  /// Optional: displayed in the header as trip context.
  final String? tripDeparture;
  final String? tripDestination;
  final String? requestDeparture;
  final String? requestDestination;
  final String? requestDate;
  final String? requestTime;
  final int? requestSeats;

  const ChatScreen({
    super.key,
    required this.tripId,
    this.rideRequestId,
    required this.currentUser,
    required this.otherUserId,
    required this.otherUserName,
    this.tripDeparture,
    this.tripDestination,
    this.requestDeparture,
    this.requestDestination,
    this.requestDate,
    this.requestTime,
    this.requestSeats,
  }) : assert((tripId != null) != (rideRequestId != null));

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// =============================================================================
// _ScreenState
// =============================================================================

enum _LoadState { loading, accessDenied, error, ready }

class _ChatScreenState extends State<ChatScreen> {
  // ---------------------------------------------------------------------------
  // Design tokens — match the existing project palette exactly.
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
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = const [];
  _LoadState _loadState = _LoadState.loading;
  String? _loadError;

  /// True while a send operation is in progress — prevents double-submit.
  bool _isSending = false;

  /// Tracks the raw input so we can enable/disable the send button reactively.
  String _inputText = '';

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      final text = _inputController.text;
      if (text != _inputText) {
        setState(() => _inputText = text);
      }
    });
    _loadConversation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadConversation() async {
    final userId = widget.currentUser.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loadState = _LoadState.accessDenied;
        _loadError = 'Impossible d\'identifier votre compte.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loadState = _LoadState.loading;
      _loadError = null;
    });

    try {
      // Mark incoming messages as read before loading so the returned
      // list already reflects is_read = 1 for those messages.
      final requestId = widget.rideRequestId;
      if (requestId != null) {
        await _repository.markRideRequestConversationAsRead(
          rideRequestId: requestId,
          currentUserId: userId,
          otherUserId: widget.otherUserId,
        );
      } else {
        await _repository.markConversationAsRead(
          tripId: widget.tripId!,
          currentUserId: userId,
          otherUserId: widget.otherUserId,
        );
      }
      if (!mounted) return;

      final messages = requestId != null
          ? await _repository.getRideRequestConversation(
              rideRequestId: requestId,
              currentUserId: userId,
              otherUserId: widget.otherUserId,
            )
          : await _repository.getConversation(
              tripId: widget.tripId!,
              currentUserId: userId,
              otherUserId: widget.otherUserId,
            );
      if (!mounted) return;

      setState(() {
        _messages = messages;
        _loadState = _LoadState.ready;
      });

      // Scroll to the bottom after the first frame is rendered.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animate: false);
      });
    } on StateError catch (e) {
      if (!mounted) return;
      // StateError from the repository signals a business-rule violation —
      // treat it as access denied so the user sees a clear explanation.
      setState(() {
        _loadState = _LoadState.accessDenied;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadState = _LoadState.error;
        _loadError = 'Impossible de charger la conversation.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Send
  // ---------------------------------------------------------------------------

  Future<void> _sendMessage() async {
    final userId = widget.currentUser.id;
    if (userId == null) return;

    final text = _inputController.text.trim();
    if (text.isEmpty || text.length > 1000) return;
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final requestId = widget.rideRequestId;
      if (requestId != null) {
        await _repository.sendRideRequestMessage(
          rideRequestId: requestId,
          senderId: userId,
          otherUserId: widget.otherUserId,
          message: text,
        );
      } else {
        await _repository.sendMessage(
          tripId: widget.tripId!,
          senderId: userId,
          receiverId: widget.otherUserId,
          message: text,
        );
      }
      if (!mounted) return;

      // Clear input immediately so it feels snappy.
      _inputController.clear();

      // Reload the conversation from SQLite — source of truth.
      final messages = requestId != null
          ? await _repository.getRideRequestConversation(
              rideRequestId: requestId,
              currentUserId: userId,
              otherUserId: widget.otherUserId,
            )
          : await _repository.getConversation(
              tripId: widget.tripId!,
              currentUserId: userId,
              otherUserId: widget.otherUserId,
            );
      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isSending = false;
      });

      // Scroll to the new message after the frame is laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animate: true);
      });
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _showSnack(e.message.toString());
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _showSnack('L\'envoi a échoué. Veuillez réessayer.');
    }
  }

  // ---------------------------------------------------------------------------
  // Scroll helpers
  // ---------------------------------------------------------------------------

  void _scrollToBottom({required bool animate}) {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        maxExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(maxExtent);
    }
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  bool get _canSend =>
      _inputText.trim().isNotEmpty &&
      _inputText.trim().length <= 1000 &&
      !_isSending &&
      _loadState == _LoadState.ready;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      // resizeToAvoidBottomInset = true (default) keeps the composer visible
      // when the software keyboard opens.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            if (_loadState == _LoadState.ready) _buildComposer(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    final hasTripContext =
        (widget.tripDeparture?.trim().isNotEmpty == true) &&
        (widget.tripDestination?.trim().isNotEmpty == true);
    final hasRequestRoute =
        widget.requestDeparture?.trim().isNotEmpty == true &&
        widget.requestDestination?.trim().isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2EBE7))),
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: IconButton(
              tooltip: 'Retour',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, color: _primaryBlue),
            ),
          ),

          const SizedBox(width: 4),

          // Avatar placeholder
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _lightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: _secondaryBlue,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          // Name + trip context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.otherUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.rideRequestId != null) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'À propos de cette demande',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasRequestRoute)
                    Text(
                      '${widget.requestDeparture} → ${widget.requestDestination}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ] else if (hasTripContext) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${widget.tripDeparture} → ${widget.tripDestination}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body dispatcher
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    return switch (_loadState) {
      _LoadState.loading => _buildLoadingState(),
      _LoadState.accessDenied => _buildAccessDeniedState(),
      _LoadState.error => _buildErrorState(),
      _LoadState.ready => _buildMessageList(),
    };
  }

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator(color: _green));

  // ---------------------------------------------------------------------------
  // Access-denied state
  // ---------------------------------------------------------------------------

  Widget _buildAccessDeniedState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFB63A3A),
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Conversation non disponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryBlue,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError ??
                'Vous n\'êtes pas autorisé à accéder à cette conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textGrey.withValues(alpha: 0.82),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Retour'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _secondaryBlue,
              side: const BorderSide(color: Color(0xFFDCE7E3)),
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
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: _secondaryBlue, size: 42),
          const SizedBox(height: 14),
          const Text(
            'Impossible de charger la conversation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _loadError ?? 'Vérifiez votre connexion puis réessayez.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textGrey, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadConversation,
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
  // Empty state (ready but no messages yet)
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: _green,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Commencez la conversation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envoyez votre premier message.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textGrey, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Message list
  // ---------------------------------------------------------------------------

  Widget _buildMessageList() {
    if (_messages.isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isOwn = message.senderId == widget.currentUser.id;

        // Show a date separator when the day changes between messages.
        final showSeparator =
            index == 0 ||
            !_sameDay(_messages[index - 1].createdAt, message.createdAt);

        return Column(
          children: [
            if (showSeparator) _buildDateSeparator(message.createdAt),
            _buildBubble(message, isOwn: isOwn),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Date separator
  // ---------------------------------------------------------------------------

  Widget _buildDateSeparator(String isoDate) {
    final label = _formatSeparatorDate(isoDate);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFDCE7E3))),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: _textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: Color(0xFFDCE7E3))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Message bubble
  // ---------------------------------------------------------------------------

  Widget _buildBubble(Message message, {required bool isOwn}) {
    const double maxBubbleWidth = 0.75; // 75 % of screen width

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isOwn
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            // Small avatar on the left for incoming messages
            const CircleAvatar(
              radius: 14,
              backgroundColor: _lightBlue,
              child: Icon(
                Icons.person_rounded,
                color: _secondaryBlue,
                size: 16,
              ),
            ),
            const SizedBox(width: 7),
          ],

          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * maxBubbleWidth,
            ),
            child: Column(
              crossAxisAlignment: isOwn
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isOwn ? _secondaryBlue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isOwn ? 18 : 4),
                      bottomRight: Radius.circular(isOwn ? 4 : 18),
                    ),
                    border: isOwn
                        ? null
                        : Border.all(color: const Color(0xFFE2EBE7)),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isOwn ? Colors.white : _primaryBlue,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),

                // Timestamp
                const SizedBox(height: 3),
                Text(
                  _formatMessageTime(message.createdAt),
                  style: TextStyle(
                    color: _textGrey.withValues(alpha: 0.70),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (isOwn) ...[
            const SizedBox(width: 7),
            // Small avatar on the right for outgoing messages
            const CircleAvatar(
              radius: 14,
              backgroundColor: _lightBlue,
              child: Icon(
                Icons.person_rounded,
                color: _secondaryBlue,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Message composer
  // ---------------------------------------------------------------------------

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2EBE7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAF8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDCE7E3)),
              ),
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) {
                  if (_canSend) _sendMessage();
                },
                style: const TextStyle(color: _primaryBlue, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Votre message…',
                  hintStyle: TextStyle(
                    color: _textGrey.withValues(alpha: 0.55),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _canSend ? _green : const Color(0xFFCCDDD8),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _canSend ? _sendMessage : null,
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Date / time helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when two ISO timestamps fall on the same calendar day.
  bool _sameDay(String iso1, String iso2) {
    final d1 = DateTime.tryParse(iso1);
    final d2 = DateTime.tryParse(iso2);
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// "Aujourd'hui", "Hier", or "dd MMM yyyy".
  String _formatSeparatorDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  /// "HH:mm" — short time label shown beneath each bubble.
  String _formatMessageTime(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }
}
