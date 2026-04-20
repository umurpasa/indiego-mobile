import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock notification data — in a real app these come from the backend.
  final List<_Notif> _notifications = [
    _Notif(
      id: 1,
      type: _NotifType.purchase,
      title: 'Purchase Confirmed',
      body:
          'Your purchase of "Echo of the Void" was successful. Check your library!',
      time: '2 min ago',
      isRead: false,
    ),
    _Notif(
      id: 2,
      type: _NotifType.newRelease,
      title: 'New Release',
      body:
          '"Pixel Frontier 2" is now available on Indiego. Be one of the first to play!',
      time: '1 hour ago',
      isRead: false,
    ),
    _Notif(
      id: 3,
      type: _NotifType.sale,
      title: 'Spring Sale — Up to 50% Off',
      body:
          'Selected games and assets are on sale until the end of April. Don\'t miss out!',
      time: '3 hours ago',
      isRead: false,
    ),
    _Notif(
      id: 4,
      type: _NotifType.system,
      title: 'Welcome to Indiego Mobile',
      body:
          'Browse indie games, manage your library and wishlist from anywhere.',
      time: 'Yesterday',
      isRead: true,
    ),
    _Notif(
      id: 5,
      type: _NotifType.wishlist,
      title: 'Wishlist Item on Sale',
      body: '"Starfall Chronicles" from your wishlist is now 30% off!',
      time: 'Yesterday',
      isRead: true,
    ),
    _Notif(
      id: 6,
      type: _NotifType.purchase,
      title: 'Asset Pack Delivered',
      body:
          '"Pixel UI Kit v3" has been added to your library. Ready to download.',
      time: '2 days ago',
      isRead: true,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _toggleRead(int id) {
    setState(() {
      final n = _notifications.firstWhere((n) => n.id == id);
      n.isRead = !n.isRead;
    });
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0A0A16);
    const primaryPurple = Color(0xFFA088E4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            if (_unreadCount > 0)
              Text('$_unreadCount unread',
                  style:
                      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: primaryPurple, fontSize: 13)),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFF1E1E3A), height: 1),
        ),
      ),
      body: _notifications.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Color(0xFF1A1A2E), height: 1),
              itemBuilder: (_, i) => _NotifTile(
                notif: _notifications[i],
                onTap: () => _toggleRead(_notifications[i].id),
              ),
            ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_outlined,
              color: Color(0xFFA088E4), size: 52),
          SizedBox(height: 16),
          Text('No notifications yet',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 6),
          Text('We\'ll notify you about purchases, sales and new releases.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Tile ─────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.isRead
            ? Colors.transparent
            : const Color(0xFFA088E4).withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notif.type.color.withOpacity(0.15),
              ),
              child: Icon(notif.type.icon, color: notif.type.color, size: 20),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFA088E4),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style:
                        const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(notif.time,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────
enum _NotifType { purchase, newRelease, sale, wishlist, system }

extension _NotifTypeX on _NotifType {
  IconData get icon => switch (this) {
        _NotifType.purchase => Icons.check_circle_outline,
        _NotifType.newRelease => Icons.new_releases_outlined,
        _NotifType.sale => Icons.local_offer_outlined,
        _NotifType.wishlist => Icons.favorite_border,
        _NotifType.system => Icons.info_outline,
      };

  Color get color => switch (this) {
        _NotifType.purchase => const Color(0xFF4CAF50),
        _NotifType.newRelease => const Color(0xFF4A90E2),
        _NotifType.sale => const Color(0xFFFF5E8A),
        _NotifType.wishlist => const Color(0xFFFF5E8A),
        _NotifType.system => const Color(0xFFA088E4),
      };
}

class _Notif {
  final int id;
  final _NotifType type;
  final String title;
  final String body;
  final String time;
  bool isRead;

  _Notif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}
