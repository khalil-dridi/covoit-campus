import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../repositories/notification_repository.dart';
import '../../screens/shared/notifications_screen.dart';
import '../notifications/notification_dropdown.dart';

class NotificationBell extends StatefulWidget {
  final User user;
  final Color iconColor;
  final double size;

  const NotificationBell({
    super.key,
    required this.user,
    required this.iconColor,
    this.size = 22,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  final NotificationRepository _repository = NotificationRepository();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownEntry;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    NotificationRepository.changes.addListener(_loadCount);
    WidgetsBinding.instance.addObserver(this);
    _loadCount();
  }

  @override
  void dispose() {
    NotificationRepository.changes.removeListener(_loadCount);
    WidgetsBinding.instance.removeObserver(this);
    _closeDropdown();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadCount();
  }

  Future<void> _loadCount() async {
    final userId = widget.user.id;
    if (userId == null) return;
    try {
      final count = await _repository.getUnreadCount(userId);
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {
      if (!mounted) return;
    }
  }

  void _toggleDropdown() {
    if (_dropdownEntry == null) {
      _openDropdown();
      return;
    }
    _closeDropdown();
  }

  void _openDropdown() {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || !mounted) return;
    _closeDropdown();
    _dropdownEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeDropdown,
          child: NotificationDropdown(
            key: const Key('notification-dropdown'),
            user: widget.user,
            layerLink: _layerLink,
            onClose: _closeDropdown,
            onViewAll: _openNotifications,
          ),
        ),
      ),
    );
    overlay.insert(_dropdownEntry!);
    if (mounted) setState(() {});
  }

  void _closeDropdown() {
    _dropdownEntry?.remove();
    _dropdownEntry = null;
    if (mounted) setState(() {});
  }

  Future<void> _openNotifications() async {
    _closeDropdown();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(user: widget.user),
      ),
    );
    if (!mounted) return;
    await _loadCount();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _dropdownEntry == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _dropdownEntry != null) {
            _closeDropdown();
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: IconButton(
                tooltip: 'Notifications',
                onPressed: _toggleDropdown,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: widget.iconColor,
                  size: widget.size,
                ),
              ),
            ),
            if (_unreadCount > 0)
              Positioned(
                top: 2,
                right: 1,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
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
        ),
      );
}
