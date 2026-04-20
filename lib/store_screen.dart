import 'package:flutter/material.dart';
import 'screens/game_detail_screen.dart';
import 'screens/asset_detail_screen.dart';
import 'models/product.dart';
import 'services/api_service.dart';

class StoreScreen extends StatefulWidget {
  final VoidCallback onOpenGames;
  final VoidCallback onOpenGameAssets;

  const StoreScreen({
    super.key,
    required this.onOpenGames,
    required this.onOpenGameAssets,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ─────────────────────────────────────
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),

          // ── Categories ─────────────────────────────────────
          const _StoreSection(title: 'Browse by Category'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: _CategoryCard(
                  icon: Icons.videogame_asset_outlined,
                  label: 'Games',
                  count: '2,500+',
                  onTap: widget.onOpenGames,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _CategoryCard(
                  icon: Icons.widgets_outlined,
                  label: 'Game Assets',
                  count: '5,000+',
                  onTap: widget.onOpenGameAssets,
                )),
              ],
            ),
          ),

          // ── Popular Tags ────────────────────────────────────
          const SizedBox(height: 20),
          const _StoreSection(title: 'Popular Tags'),
          const _TagsRow(),

          // ── Featured ────────────────────────────────────────
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Featured',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onOpenGames,
                  child: Row(
                    children: const [
                      Text('See all',
                          style: TextStyle(
                              color: Color(0xFF9370DB), fontSize: 13)),
                      Icon(Icons.chevron_right,
                          color: Color(0xFF9370DB), size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _FeaturedList(
            searchQuery: _searchQuery,
            onGameTap: (gameId) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailScreen(gameId: gameId),
              ),
            ),
            onAssetTap: (assetId) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssetDetailScreen(assetId: assetId),
              ),
            ),
          ),

          // ── Sale Banner ──────────────────────────────────────
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _SaleBanner(
              onTap: () => _showInfo('Weekend sale page is coming soon.'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Search Bar ───────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: const Color(0xFF0A0A16).withOpacity(0.95),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search games & assets...',
                hintStyle:
                    const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF6B7280), size: 18),
                suffixIcon:
                    const Icon(Icons.tune, color: Color(0xFF6B7280), size: 18),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2A2A4E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFA088E4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ────────────────────────────────────────────
class _StoreSection extends StatelessWidget {
  final String title;
  const _StoreSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}

// ── Category Card ────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A4E)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFA088E4), size: 32),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('$count items',
                  style:
                      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tags Row ─────────────────────────────────────────────────
class _TagsRow extends StatelessWidget {
  static const _tags = [
    'Pixel Art',
    'RPG',
    'Action',
    'Indie',
    'Adventure',
    'Strategy',
    'Casual',
    'Horror',
  ];

  const _TagsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _tags.map((tag) {
          return GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$tag" tag filtering is available in the dedicated list pages.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A4E).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Featured List ─────────────────────────────────────────────
class _FeaturedList extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<int> onGameTap;
  final ValueChanged<int> onAssetTap;

  const _FeaturedList({
    required this.searchQuery,
    required this.onGameTap,
    required this.onAssetTap,
  });

  @override
  State<_FeaturedList> createState() => _FeaturedListState();
}

class _FeaturedListState extends State<_FeaturedList> {
  bool _loading = true;
  String? _error;
  List<Product> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await ApiService.get(
        '/api/v1/Product',
        query: {'PageNumber': '1', 'PageSize': '8'},
        requireAuth: false,
      );
      final items = _extractProductList(raw);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<Product> _filteredItems() {
    final q = widget.searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _items.take(4).toList();
    return _items
        .where((item) =>
            item.name.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q))
        .take(4)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFA088E4)),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Featured products could not be loaded.',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
      );
    }

    final items = _filteredItems();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          widget.searchQuery.trim().isEmpty
              ? 'No featured products yet.'
              : 'No featured products match your search.',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final isGame = item.type == ProductType.game;
        final coverUrl = item.coverImageUrl;
        return GestureDetector(
          onTap: isGame
              ? () => widget.onGameTap(item.id)
              : () => widget.onAssetTap(item.id),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _NetworkThumb(
                    url: coverUrl,
                    width: 72,
                    height: 54,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isGame
                              ? const Color(0xFF4A90E2).withOpacity(0.2)
                              : const Color(0xFFA088E4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isGame ? 'Game' : 'Asset',
                          style: TextStyle(
                            color: isGame
                                ? const Color(0xFF4A90E2)
                                : const Color(0xFFA088E4),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 3),
                      if (isGame)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFFBBC05), size: 11),
                            const SizedBox(width: 3),
                            const Text('View details',
                                style: TextStyle(
                                    color: Color(0xFF9CA3AF), fontSize: 11)),
                          ],
                        ),
                      if (!isGame)
                        Text('Asset product',
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  _formatPrice(item.price, item.currency),
                  style: const TextStyle(
                      color: Color(0xFFA088E4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Sale Banner ──────────────────────────────────────────────
class _SaleBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _SaleBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A4E)),
          gradient: const LinearGradient(
            colors: [Color(0x33FF5E8A), Color(0x33A088E4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'WEEKEND SALE',
                    style: TextStyle(
                      color: Color(0xFFFF5E8A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Up to 70% Off',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Limited time offers',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFA088E4), size: 28),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

// ── Data Model ───────────────────────────────────────────────
List<Product> _extractProductList(dynamic raw) {
  dynamic cursor = raw;
  if (cursor is Map && cursor['data'] != null) cursor = cursor['data'];
  if (cursor is Map && cursor['data'] is List) {
    cursor = cursor['data'];
  }
  if (cursor is List) {
    return cursor
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }
  return const [];
}

String _formatPrice(double price, String currency) {
  if (price <= 0) return 'Free';
  final symbol = currency.toUpperCase() == 'USD' ? '\$' : '$currency ';
  return '$symbol${price.toStringAsFixed(2)}';
}

class _NetworkThumb extends StatelessWidget {
  final String? url;
  final double width;
  final double height;

  const _NetworkThumb({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF2D1B69),
      );
    }
    if (url!.startsWith('assets/')) {
      return Image.asset(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFF2D1B69),
        ),
      );
    }
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFF2D1B69),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF1A1A2E),
        );
      },
    );
  }
}
