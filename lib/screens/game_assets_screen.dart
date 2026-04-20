// Game Assets listeleme ekranı.
// Veri kaynağı: GET /api/v1/Product?Type=1  (1 = GameAsset)
// Yapı game_screen.dart ile bilinçli olarak paralel; tek farklar:
//   - Type=1, kart görseli square (1:1) ve contain ile yerleşiyor,
//   - Sort menüsünde "Most Downloads" var (client-side sıralanamıyor, server order).

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'asset_detail_screen.dart';

class GameAssetsScreen extends StatefulWidget {
  const GameAssetsScreen({super.key});

  @override
  State<GameAssetsScreen> createState() => _GameAssetsScreenState();
}

class _GameAssetsScreenState extends State<GameAssetsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTag = 'All';
  String _selectedSort = 'Popular';
  bool _showSortMenu = false;

  late Future<List<Product>> _future;

  static const _sortOptions = [
    'Popular',
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
    'Most Downloads',
  ];

  static const _filterTags = [
    'All',
    'UI',
    'Characters',
    'Tileset',
    'Sprites',
    'Animation',
    'Backgrounds',
    'Icons',
  ];

  @override
  void initState() {
    super.initState();
    _future = _fetchAssets();
  }

  Future<List<Product>> _fetchAssets() async {
    final json = await ApiService.get(
      '/api/v1/Product',
      query: {'Type': '1', 'PageSize': '100'},
      requireAuth: false,
    );
    final paged = PagedResult<Product>.fromJson(
      json as Map<String, dynamic>,
      Product.fromJson,
    );
    return paged.data;
  }

  List<Product> _applyFilters(List<Product> all) {
    Iterable<Product> result = all;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(q));
    }

    if (_selectedTag != 'All') {
      final t = _selectedTag.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(t) ||
          p.description.toLowerCase().contains(t));
    }

    final list = result.toList();
    switch (_selectedSort) {
      case 'Price: Low to High':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0A0A16);
    const primaryPurple = Color(0xFFA088E4);
    const inputBg = Color(0xFF1A1A2E);
    const borderColor = Color(0xFF2A2A4E);

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () => setState(() => _showSortMenu = false),
        child: FutureBuilder<List<Product>>(
          future: _future,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final hasError = snapshot.hasError;
            final all = snapshot.data ?? const <Product>[];
            final filtered = _applyFilters(all);

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: inputBg)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Game Assets',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('High-quality assets for your games',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  color: bgColor.withOpacity(0.95),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search assets...',
                          hintStyle: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 14),
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF6B7280), size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Color(0xFF6B7280), size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: primaryPurple),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filterTags.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final tag = _filterTags[i];
                            final selected = tag == _selectedTag;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTag = tag),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected ? primaryPurple : inputBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(tag,
                                    style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFFD1D5DB),
                                        fontSize: 13)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${filtered.length} assets',
                              style: const TextStyle(
                                  color: Color(0xFF9CA3AF), fontSize: 13)),
                          PopupMenuButton<String>(
                            onSelected: (v) => setState(() => _selectedSort = v),
                            color: inputBg,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: borderColor)),
                            elevation: 8,
                            itemBuilder: (_) => _sortOptions.map((opt) {
                              final sel = opt == _selectedSort;
                              return PopupMenuItem<String>(
                                value: opt,
                                child: Text(opt,
                                    style: TextStyle(
                                        color: sel ? primaryPurple : const Color(0xFFD1D5DB),
                                        fontSize: 13,
                                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                              );
                            }).toList(),
                            child: Row(
                              children: [
                                Text(_selectedSort,
                                    style: const TextStyle(
                                        color: Color(0xFF9370DB), fontSize: 13)),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: Color(0xFF9370DB), size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBody(
                    isLoading: isLoading,
                    hasError: hasError,
                    error: snapshot.error,
                    items: filtered,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isLoading,
    required bool hasError,
    required Object? error,
    required List<Product> items,
  }) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFA088E4)));
    }
    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off,
                  color: Color(0xFFA088E4), size: 48),
              const SizedBox(height: 12),
              Text(
                'Could not load assets\n${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _future = _fetchAssets());
                },
                child: const Text('Retry',
                    style: TextStyle(color: Color(0xFFA088E4))),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return const Center(
        child: Text('No assets match your filter',
            style: TextStyle(color: Color(0xFF9CA3AF))),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFA088E4),
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: () async {
        final f = _fetchAssets();
        setState(() => _future = f);
        await f;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.70,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _AssetCard(product: items[i]),
      ),
    );
  }
}

// ── Asset Card ───────────────────────────────────────────────
// game_screen kartına kıyasla:
//  - Görsel kare (1:1), contain ile yerleştirilir (asset paketleri için doğal)
//  - Rating/download row'u backend list response'unda yok → gizlendi.
//    Detay sayfasında ProductDetail.averageRating, downloadCount alanları var.
class _AssetCard extends StatelessWidget {
  final Product product;
  const _AssetCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(assetId: p.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: const Color(0xFF0D0D1A)),
                    _coverImage(p.coverImageUrl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(_formatPrice(p),
                      style: const TextStyle(
                          color: Color(0xFFA088E4),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(color: const Color(0xFF2D1B69));
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF2D1B69)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Container(color: const Color(0xFF2D1B69)),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFA088E4),
            ),
          ),
        );
      },
    );
  }

  String _formatPrice(Product p) {
    final symbol = p.currency == 'USD' ? '\$' : '${p.currency} ';
    return '$symbol${p.price.toStringAsFixed(2)}';
  }
}
