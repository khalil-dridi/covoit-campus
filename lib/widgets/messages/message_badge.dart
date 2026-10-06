import 'package:flutter/material.dart';

import '../../repositories/message_repository.dart';

// =============================================================================
// MessageBadgeIcon
//
// A reactive icon widget that shows the current unread-message count as a
// small badge overlay. Listens to MessageRepository.changes so it updates
// whenever a message is sent or marked as read — without polling SQLite.
//
// Usage:
//   MessageBadgeIcon(userId: currentUser.id!, selected: isSelected)
// =============================================================================

class MessageBadgeIcon extends StatefulWidget {
  final int userId;
  final bool selected;

  const MessageBadgeIcon({
    super.key,
    required this.userId,
    required this.selected,
  });

  @override
  State<MessageBadgeIcon> createState() => _MessageBadgeIconState();
}

class _MessageBadgeIconState extends State<MessageBadgeIcon>
    with WidgetsBindingObserver {
  final MessageRepository _repository = MessageRepository();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    MessageRepository.changes.addListener(_loadCount);
    WidgetsBinding.instance.addObserver(this);
    _loadCount();
  }

  @override
  void dispose() {
    MessageRepository.changes.removeListener(_loadCount);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final count = await _repository.getUnreadMessageCount(widget.userId);
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.selected
        ? Icons.chat_bubble_rounded
        : Icons.chat_bubble_outline_rounded;

    if (_unreadCount <= 0) {
      return Icon(icon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          top: -4,
          right: -6,
          child: IgnorePointer(
            child: Container(
              constraints:
                  const BoxConstraints(minWidth: 15, minHeight: 15),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFB63A3A),
                shape: BoxShape.circle,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
