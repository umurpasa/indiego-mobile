import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import 'asset_detail_screen.dart';
import 'game_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DashboardScreen({super.key, this.onBack});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  List<Product> _products = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.get(
        '/api/v1/Product/mine',
        query: {'PageNumber': '1', 'PageSize': '100'},
      );
      final items = _extractProducts(raw);
      if (!mounted) return;
      setState(() {
        _products = items;
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
        _error = 'Could not load dashboard: $e';
        _loading = false;
      });
    }
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _copyDesktopLink() async {
    await Clipboard.setData(
      const ClipboardData(text: 'https://indiego.com/dashboard'),
    );
    if (!mounted) return;
    _showInfo('Desktop dashboard link copied.');
  }

  @override
  Widget build(BuildContext context) {
    final games = _products
        .where((p) => p.type == ProductType.game)
        .toList(growable: false);
    final assets = _products
        .where((p) => p.type == ProductType.gameAsset)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFA088E4),
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Header(onBack: widget.onBack),
              const _ViewOnlyNotice(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'My Products',
                        value: '${_products.length}',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFFA088E4),
                        onTap: () => _showInfo(
                            'Your seller products are listed below.'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Games',
                        value: '${games.length}',
                        icon: Icons.videogame_asset_outlined,
                        color: const Color(0xFF4A90E2),
                        onTap: () => _showInfo(
                            'Game products are included in the list below.'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Assets',
                        value: '${assets.length}',
                        icon: Icons.widgets_outlined,
                        color: const Color(0xFF4CAF50),
                        onTap: () => _showInfo(
                            'Asset products are included in the list below.'),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Mobile Seller Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'On mobile, seller tools are limited to preview and monitoring. Product upload, editing and store management continue on the web dashboard.',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFA088E4)),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A4E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard unavailable',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFB0B0C3),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA088E4),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_loading && _error == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _products.isEmpty
                      ? const _EmptyDashboard()
                      : Column(
                          children: _products
                              .map((p) => _ProductTile(product: p))
                              .toList(),
                        ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _DesktopPrompt(onCopy: _copyDesktopLink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onBack;

  const _Header({this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A16),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A2E))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ??
                () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Seller Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewOnlyNotice extends StatelessWidget {
  const _ViewOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4A90E2).withOpacity(0.1),
          border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.monitor, color: Color(0xFF4A90E2), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desktop-Managed Seller Tools',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'This mobile view is for quick monitoring only. Uploading products, editing metadata and managing your store happen on desktop.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4E)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: Color(0xFFA088E4), size: 34),
          SizedBox(height: 10),
          Text(
            'No seller products yet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'When you publish products from the web dashboard, they will appear here for quick preview on mobile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final isGame = product.type == ProductType.game;

    return GestureDetector(
      onTap: () {
        if (isGame) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameDetailScreen(gameId: product.id),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(assetId: product.id),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A4E)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: _ProductImage(
                path: product.coverImageUrl,
                width: 86,
                height: 86,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGame
                            ? const Color(0xFF4A90E2).withOpacity(0.15)
                            : const Color(0xFFA088E4).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGame ? 'Game' : 'Asset',
                        style: TextStyle(
                          color: isGame
                              ? const Color(0xFF4A90E2)
                              : const Color(0xFFA088E4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatPrice(product.price, product.currency),
                      style: const TextStyle(
                        color: Color(0xFFA088E4),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopPrompt extends StatelessWidget {
  final VoidCallback onCopy;

  const _DesktopPrompt({required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border.all(color: const Color(0xFF2A2A4E)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.monitor, color: Color(0xFFA088E4), size: 32),
          const SizedBox(height: 10),
          const Text(
            'Need to edit or upload products?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use the web dashboard for seller management actions. Mobile stays focused on quick monitoring and customer-side browsing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          const Text(
            'indiego.com/dashboard',
            style: TextStyle(
              color: Color(0xFFA088E4),
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onCopy,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA088E4),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy_outlined, size: 16),
            label: const Text('Copy Desktop Link'),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? path;
  final double width;
  final double height;

  const _ProductImage({
    required this.path,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return _placeholder();
    }
    if (_isAssetPath(path!)) {
      return Image.asset(
        path!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.network(
      path!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2A2A4E),
      child: const Icon(Icons.image_outlined, color: Color(0xFF6B6B8A)),
    );
  }
}

List<Product> _extractProducts(dynamic raw) {
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

bool _isAssetPath(String value) => value.startsWith('assets/');
