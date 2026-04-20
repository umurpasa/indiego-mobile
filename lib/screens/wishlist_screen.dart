import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  static const _baseUrl = 'https://localhost:9001';

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchWishlist();
  }

  Future<List<Map<String, dynamic>>> _fetchWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/wishlist'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Wishlist request failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _removeFromWishlist(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/v1/wishlist/$productId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Could not remove item (${response.statusCode})');
    }
  }

  void _onRemove(BuildContext context, int productId, String productName) async {
    try {
      await _removeFromWishlist(productId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$productName" removed from wishlist'),
          backgroundColor: const Color(0xFF4CAF50),
        ));
        setState(() {
          _future = _fetchWishlist();
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A16),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Wishlist', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFA088E4)),
            onPressed: () => setState(() {
              _future = _fetchWishlist();
            }),
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
            return _buildError(snapshot.error.toString());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _buildEmpty();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                // Header info
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF4A90E2).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF4A90E2), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add to cart and checkout on desktop to purchase.',
                          style: TextStyle(
                              color: Color(0xFFC7D7F6), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final item = items[i - 1];
              return _WishlistCard(
                item: item,
                onRemove: () => _onRemove(
                  context,
                  (item['productId'] as num?)?.toInt() ?? 0,
                  (item['productName'] ?? 'Product').toString(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 40),
            const SizedBox(height: 12),
            const Text('Could not load wishlist.',
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
              onPressed: () => setState(() {
                _future = _fetchWishlist();
              }),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, color: Color(0xFFA088E4), size: 48),
          SizedBox(height: 16),
          Text('Wishlist is empty',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Save games and assets you want to buy later',
              style: TextStyle(color: Color(0xFFB0B0C3), fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Wishlist Card ─────────────────────────────────────────────────────────────
class _WishlistCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const _WishlistCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final name = (item['productName'] ?? 'Unknown').toString();
    final seller = (item['sellerStoreName'] ?? '').toString();
    final price = item['price'];
    final isFree = item['isFree'] == true;
    final priceStr =
        isFree ? 'Free' : (price is num ? '\$${price.toStringAsFixed(2)}' : '-');
    final type = (item['productType'] ?? '').toString();
    final isGame = type.toLowerCase() == 'game';
    final coverUrl = (item['coverImageUrl'] ?? '').toString();
    final status = (item['productStatus'] ?? '').toString().toLowerCase();
    final isUnavailable =
        status == 'suspended' || status == 'deleted' || status == 'inactive';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnavailable
              ? Colors.orange.withOpacity(0.4)
              : const Color(0xFF2A2A4E),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
                child: _Cover(url: coverUrl, size: 80),
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
                          // Remove button
                          GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.favorite,
                                  color: Color(0xFFE57373), size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(name,
                          style: TextStyle(
                            color: isUnavailable
                                ? const Color(0xFF6B6B8A)
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (seller.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(seller,
                            style: const TextStyle(
                                color: Color(0xFFB0B0C3), fontSize: 11)),
                      ],
                      const SizedBox(height: 6),
                      Text(priceStr,
                          style: TextStyle(
                            color: isFree
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFA088E4),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isUnavailable)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 14),
                  SizedBox(width: 6),
                  Text('This product is no longer available',
                      style:
                          TextStyle(color: Colors.orange, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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

class _Cover extends StatelessWidget {
  final String url;
  final double size;
  const _Cover({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (url.isNotEmpty) {
      return Image.network(url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF2A2A4E),
      child: const Icon(Icons.image_outlined,
          color: Color(0xFF6B6B8A), size: 28),
    );
  }
}
