import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _baseUrl = 'https://localhost:9001';

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchCart();
  }

  Future<Map<String, dynamic>> _fetchCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/cart'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Cart request failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return {'items': [], 'totalAmount': 0};
    return data;
  }

  Future<void> _removeFromCart(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/v1/cart/$productId'),
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

  Future<void> _clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/v1/cart'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Could not clear cart (${response.statusCode})');
    }
  }

  void _onRemoveItem(BuildContext context, int productId, String name) async {
    try {
      await _removeFromCart(productId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" removed from cart'),
          backgroundColor: const Color(0xFF4CAF50),
        ));
        setState(() {
          _future = _fetchCart();
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _onClearCart(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Clear Cart',
            style: TextStyle(color: Colors.white)),
        content: const Text('Remove all items from your cart?',
            style: TextStyle(color: Color(0xFFB0B0C3))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFB0B0C3)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await _clearCart();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cart cleared'),
          backgroundColor: Color(0xFF4CAF50),
        ));
        setState(() {
          _future = _fetchCart();
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: const Text('Cart', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFA088E4)),
            onPressed: () => setState(() {
              _future = _fetchCart();
            }),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFA088E4)));
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final cartData = snapshot.data ?? {};
          final rawItems = cartData['items'];
          final List<Map<String, dynamic>> items = rawItems is List
              ? rawItems.whereType<Map<String, dynamic>>().toList()
              : [];
          final total = (cartData['totalAmount'] ?? 0);
          final totalAmount =
              total is num ? total.toDouble() : double.tryParse('$total') ?? 0;
          final currency = (cartData['currency'] ?? 'USD').toString();

          if (items.isEmpty) return _buildEmpty();

          return Column(
            children: [
              // Desktop checkout note
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.desktop_windows_outlined,
                        color: Color(0xFF4A90E2), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Checkout is available on desktop. You can manage your cart here.',
                        style:
                            TextStyle(color: Color(0xFFC7D7F6), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              // Items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return _CartCard(
                      item: item,
                      onRemove: () => _onRemoveItem(
                        context,
                        (item['productId'] as num?)?.toInt() ?? 0,
                        (item['productName'] ?? 'Product').toString(),
                      ),
                    );
                  },
                ),
              ),
              // Bottom total bar
              _CartBottomBar(
                itemCount: items.length,
                total: totalAmount,
                currency: currency,
                onClear: items.isNotEmpty
                    ? () => _onClearCart(context)
                    : null,
              ),
            ],
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
            const Text('Could not load cart.',
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
                _future = _fetchCart();
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
          Icon(Icons.shopping_cart_outlined,
              color: Color(0xFFA088E4), size: 48),
          SizedBox(height: 16),
          Text('Your cart is empty',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Add games or assets from the Store',
              style: TextStyle(color: Color(0xFFB0B0C3), fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Cart Item Card ─────────────────────────────────────────────────────────────
class _CartCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const _CartCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final name = (item['productName'] ?? 'Unknown').toString();
    final seller = (item['sellerStoreName'] ?? '').toString();
    final price = item['price'];
    final isFree = item['isFree'] == true;
    final priceStr =
        isFree ? 'Free' : (price is num ? '\$${price.toStringAsFixed(2)}' : '-');
    final coverUrl = (item['coverImageUrl'] ?? '').toString();
    final status =
        (item['productStatus'] ?? '').toString().toLowerCase();
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
                child: _Cover(url: coverUrl, size: 76),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(priceStr,
                              style: TextStyle(
                                color: isFree
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFA088E4),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              )),
                          const Spacer(),
                          // Remove button
                          GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Color(0xFFE57373), size: 14),
                                  SizedBox(width: 4),
                                  Text('Remove',
                                      style: TextStyle(
                                          color: Color(0xFFE57373),
                                          fontSize: 12)),
                                ],
                              ),
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

// ── Bottom Bar ────────────────────────────────────────────────────────────────
class _CartBottomBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final String currency;
  final VoidCallback? onClear;

  const _CartBottomBar({
    required this.itemCount,
    required this.total,
    required this.currency,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border:
            Border(top: BorderSide(color: const Color(0xFF2A2A4E))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$itemCount item${itemCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Color(0xFFB0B0C3), fontSize: 13)),
              Text(
                'Total: \$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Clear cart
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE57373),
                    side: const BorderSide(color: Color(0xFFE57373)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Clear Cart'),
                ),
              ),
              const SizedBox(width: 10),
              // Checkout = Desktop only
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A4E),
                    foregroundColor: const Color(0xFFB0B0C3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Checkout is available on desktop.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.desktop_windows_outlined,
                      size: 16),
                  label: const Text('Checkout on Desktop'),
                ),
              ),
            ],
          ),
        ],
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
          color: Color(0xFF6B6B8A), size: 26),
    );
  }
}
