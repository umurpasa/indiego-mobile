import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _baseUrl = 'https://localhost:9001';

  late Future<List<Map<String, dynamic>>> _future;
  String _filter = 'All'; // All / Game / GameAsset

  @override
  void initState() {
    super.initState();
    _future = _fetchLibrary();
  }

  Future<List<Map<String, dynamic>>> _fetchLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/library'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Library request failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> items) {
    if (_filter == 'All') return items;
    return items.where((item) {
      final type = (item['productType'] ?? '').toString().toLowerCase();
      if (_filter == 'Game') return type == 'game';
      if (_filter == 'Asset') return type == 'gameasset' || type == 'asset';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A16),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Library', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFA088E4)),
            onPressed: () => setState(() => _future = _fetchLibrary()),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFA088E4)));
          }
          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error.toString(),
              onRetry: () => setState(() => _future = _fetchLibrary()),
            );
          }

          final all = snapshot.data ?? [];
          final items = _applyFilter(all);

          return Column(
            children: [
              // Filter chips
              _FilterRow(
                selected: _filter,
                gameCount: all
                    .where((i) =>
                        (i['productType'] ?? '').toString().toLowerCase() ==
                        'game')
                    .length,
                assetCount: all
                    .where((i) {
                  final t = (i['productType'] ?? '').toString().toLowerCase();
                  return t == 'gameasset' || t == 'asset';
                }).length,
                onSelected: (f) => setState(() => _filter = f),
              ),
              // Summary bar
              if (all.isNotEmpty)
                _SummaryBar(
                  count: all.length,
                  total: all.fold<double>(0, (sum, i) {
                    final p = i['pricePaid'];
                    return sum + (p is num ? p.toDouble() : 0.0);
                  }),
                ),
              // List
              Expanded(
                child: items.isEmpty
                    ? _EmptyState(
                        filter: _filter,
                        onClearFilter: () => setState(() => _filter = 'All'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) =>
                            _LibraryItem(item: items[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final String selected;
  final int gameCount;
  final int assetCount;
  final ValueChanged<String> onSelected;

  const _FilterRow({
    required this.selected,
    required this.gameCount,
    required this.assetCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('All', gameCount + assetCount),
      ('Game', gameCount),
      ('Asset', assetCount),
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: options.map((opt) {
          final isSelected = selected == opt.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${opt.$1} (${opt.$2})'),
              selected: isSelected,
              onSelected: (_) => onSelected(opt.$1),
              selectedColor: const Color(0xFFA088E4).withOpacity(0.25),
              checkmarkColor: const Color(0xFFA088E4),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFA088E4) : Colors.grey,
                fontSize: 12,
              ),
              backgroundColor: const Color(0xFF1A1A2E),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFFA088E4)
                    : const Color(0xFF2A2A4E),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Summary Bar ───────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final int count;
  final double total;

  const _SummaryBar({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A4E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.library_books_outlined,
              color: Color(0xFFA088E4), size: 16),
          const SizedBox(width: 8),
          Text(
            '$count items',
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Icon(Icons.attach_money,
              color: Color(0xFF4CAF50), size: 16),
          Text(
            'Total paid: \$${total.toStringAsFixed(2)}',
            style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Library Item Card ─────────────────────────────────────────────────────────
class _LibraryItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const _LibraryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = (item['productName'] ?? 'Unknown Product').toString();
    final seller = (item['sellerStoreName'] ?? '').toString();
    final pricePaid = item['pricePaid'];
    final priceStr = pricePaid is num
        ? (pricePaid == 0 ? 'Free' : '\$${pricePaid.toStringAsFixed(2)}')
        : 'Free';
    final type = (item['productType'] ?? '').toString();
    final isGame = type.toLowerCase() == 'game';
    final coverUrl = (item['coverImageUrl'] ?? '').toString();
    final purchasedAt = (item['purchasedAt'] ?? '').toString();
    String dateStr = '';
    if (purchasedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(purchasedAt);
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4E)),
      ),
      child: Row(
        children: [
          // Cover image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: _CoverImage(url: coverUrl, size: 80),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeBadge(isGame: isGame),
                      const Spacer(),
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: const TextStyle(
                                color: Color(0xFF6B6B8A), fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (seller.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(seller,
                        style: const TextStyle(
                            color: Color(0xFFB0B0C3), fontSize: 11)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(priceStr,
                          style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      // Download = desktop only
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A4E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.desktop_windows_outlined,
                                size: 12, color: Color(0xFFB0B0C3)),
                            SizedBox(width: 4),
                            Text('Desktop',
                                style: TextStyle(
                                    color: Color(0xFFB0B0C3), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final bool isGame;
  const _TypeBadge({required this.isGame});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isGame
            ? const Color(0xFFA088E4).withOpacity(0.2)
            : const Color(0xFF4A90E2).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isGame ? 'Game' : 'Asset',
        style: TextStyle(
          color: isGame ? const Color(0xFFA088E4) : const Color(0xFF4A90E2),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String url;
  final double size;
  const _CoverImage({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(size),
      );
    }
    if (url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(size),
      );
    }
    return _placeholder(size);
  }

  Widget _placeholder(double s) {
    return Container(
      width: s,
      height: s,
      color: const Color(0xFF2A2A4E),
      child: const Icon(Icons.image_outlined,
          color: Color(0xFF6B6B8A), size: 28),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  final VoidCallback onClearFilter;

  const _EmptyState({required this.filter, required this.onClearFilter});

  @override
  Widget build(BuildContext context) {
    final isFiltered = filter != 'All';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.library_books_outlined,
              color: Color(0xFFA088E4), size: 48),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No ${filter}s in your library' : 'Library is empty',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try showing all items'
                : 'Purchase games or assets from the Store',
            style:
                const TextStyle(color: Color(0xFFB0B0C3), fontSize: 13),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClearFilter,
              child: const Text('Show All',
                  style: TextStyle(color: Color(0xFFA088E4))),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 40),
            const SizedBox(height: 12),
            const Text('Could not load library.',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(error,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Color(0xFFB0B0C3), fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA088E4),
                  foregroundColor: Colors.white),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
