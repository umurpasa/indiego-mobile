// Game Asset detay ekranı.
// Veri kaynağı (game_detail_screen.dart ile aynı endpoint, tek fark UI):
//   GET    /api/v1/Product/{id}                     -> ProductDetailDto
//   GET    /api/v1/cart, /api/v1/wishlist           -> mevcut durum kontrol
//   POST   /api/v1/cart    body: {productId}
//   POST   /api/v1/wishlist body: {productId}
//   DELETE /api/v1/wishlist/{productId}
//   GET    /api/v1/products/{id}/reviews            -> PagedResponse<ReviewDto>
//
// UI farkı: hero image kare (1:1 contain), "Download on Desktop" rozeti yok —
// onun yerine indirme sayısı rozeti. Tab ismi "Overview" (About değil).
// Backend'de fileFormat / updatedAt alanı yok, bu yüzden Overview panelinde
// onları göstermiyorum; yerine downloadCount ve categories bilgisi var.

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class AssetDetailScreen extends StatefulWidget {
  final int assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  static const _bgColor = Color(0xFF0A0A16);
  static const _primaryPurple = Color(0xFFA088E4);
  static const _inputBg = Color(0xFF1A1A2E);
  static const _borderColor = Color(0xFF2A2A4E);

  bool _loading = true;
  String? _error;
  ProductDetail? _asset;

  bool _isWishlisted = false;
  bool _isInCart = false;
  bool _busyCart = false;
  bool _busyWishlist = false;

  String _activeTab = 'overview'; // overview | reviews

  bool _reviewsLoaded = false;
  bool _reviewsLoading = false;
  String? _reviewsError;
  List<_ReviewVM> _reviews = const [];

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
        '/api/v1/Product/${widget.assetId}',
        requireAuth: false,
      );
      final json = _unwrap(raw);
      if (json is! Map<String, dynamic>) {
        throw ApiException('Unexpected asset response');
      }
      final asset = ProductDetail.fromJson(json);

      final token = await ApiService.getToken();
      bool inCart = false;
      bool inWishlist = false;
      if (token != null && token.isNotEmpty) {
        final results = await Future.wait<dynamic>([
          ApiService.get('/api/v1/cart').catchError((_) => null),
          ApiService.get('/api/v1/wishlist').catchError((_) => null),
        ]);
        inCart = _listHasProduct(results[0], asset.id, 'items');
        inWishlist = _listHasProduct(results[1], asset.id, 'items');
      }

      if (!mounted) return;
      setState(() {
        _asset = asset;
        _isInCart = inCart;
        _isWishlisted = inWishlist;
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
        _error = 'Error loading asset: $e';
        _loading = false;
      });
    }
  }

  static dynamic _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic> &&
        raw.containsKey('data') &&
        raw['data'] is Map<String, dynamic>) {
      return raw['data'];
    }
    return raw;
  }

  static bool _listHasProduct(dynamic raw, int productId, String itemsKey) {
    if (raw == null) return false;
    dynamic cursor = raw;
    if (cursor is Map && cursor['data'] != null) cursor = cursor['data'];
    List? items;
    if (cursor is Map && cursor[itemsKey] is List) {
      items = cursor[itemsKey] as List;
    } else if (cursor is List) {
      items = cursor;
    }
    if (items == null) return false;
    for (final it in items) {
      if (it is Map &&
          (it['productId'] == productId || it['ProductId'] == productId)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _toggleWishlist() async {
    if (_busyWishlist || _asset == null) return;
    final wasWishlisted = _isWishlisted;
    setState(() {
      _busyWishlist = true;
      _isWishlisted = !wasWishlisted;
    });
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        _showSnack('Please log in to use wishlist.');
        setState(() => _isWishlisted = wasWishlisted);
        return;
      }
      if (wasWishlisted) {
        await ApiService.delete('/api/v1/wishlist/${_asset!.id}');
      } else {
        await ApiService.post('/api/v1/wishlist',
            body: {'productId': _asset!.id});
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isWishlisted = wasWishlisted);
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isWishlisted = wasWishlisted);
      _showSnack('Wishlist update failed.');
    } finally {
      if (mounted) setState(() => _busyWishlist = false);
    }
  }

  Future<void> _addToCart() async {
    if (_busyCart || _isInCart || _asset == null) return;
    setState(() => _busyCart = true);
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        _showSnack('Please log in to add items to your cart.');
        return;
      }
      await ApiService.post('/api/v1/cart',
          body: {'productId': _asset!.id});
      if (!mounted) return;
      setState(() => _isInCart = true);
      _showSnack('Added to cart.');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Could not add to cart.');
    } finally {
      if (mounted) setState(() => _busyCart = false);
    }
  }

  Future<void> _loadReviews() async {
    if (_reviewsLoaded || _reviewsLoading || _asset == null) return;
    setState(() {
      _reviewsLoading = true;
      _reviewsError = null;
    });
    try {
      final raw = await ApiService.get(
        '/api/v1/products/${_asset!.id}/reviews',
        query: {'pageSize': '20'},
        requireAuth: false,
      );
      final list = _extractReviewList(raw);
      final parsed = list.map(_ReviewVM.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _reviews = parsed;
        _reviewsLoaded = true;
        _reviewsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _reviewsError = e.message;
        _reviewsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reviewsError = 'Error loading reviews: $e';
        _reviewsLoading = false;
      });
    }
  }

  static List<Map<String, dynamic>> _extractReviewList(dynamic raw) {
    dynamic cursor = raw;
    if (cursor is Map && cursor['data'] != null) cursor = cursor['data'];
    if (cursor is List) {
      return cursor.whereType<Map<String, dynamic>>().toList();
    }
    if (cursor is Map && cursor['data'] is List) {
      return (cursor['data'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return const [];
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  String _formatDownloads(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: CircularProgressIndicator(color: _primaryPurple),
        ),
      );
    }
    if (_error != null || _asset == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Asset not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPurple),
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final asset = _asset!;
    final priceLabel = asset.isFree || asset.price <= 0
        ? 'Free'
        : (asset.currency.toUpperCase() == 'USD'
            ? '\$${asset.price.toStringAsFixed(2)}'
            : '${asset.currency} ${asset.price.toStringAsFixed(2)}');

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _bgColor.withOpacity(0.95),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              asset.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _inputBg),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image — asset için kare, contain
                AspectRatio(
                  aspectRatio: 1,
                  child: (asset.coverImageUrl == null ||
                          asset.coverImageUrl!.isEmpty)
                      ? Container(color: const Color(0xFF2D1B69))
                      : _AssetImage(
                          url: asset.coverImageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                        ),
                ),
                if (asset.previewImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                    child: SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: asset.previewImages.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: const Color(0xFF0D0D1A),
                            child: _AssetImage(
                              url: asset.previewImages[i],
                              width: 100,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _inputBg)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            priceLabel,
                            style: const TextStyle(
                              color: _primaryPurple,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Color(0xFFFBBC05), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                asset.averageRating > 0
                                    ? asset.averageRating.toStringAsFixed(1)
                                    : '—',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              Text('(${asset.reviewCount})',
                                  style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _inputBg,
                          border: Border.all(color: _borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.download_outlined,
                                color: Color(0xFF4A90E2), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_formatDownloads(asset.downloadCount)} downloads',
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _busyWishlist ? null : _toggleWishlist,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isWishlisted
                                    ? const Color(0xFFFF5E8A)
                                        .withOpacity(0.2)
                                    : _inputBg,
                                border: Border.all(
                                  color: _isWishlisted
                                      ? const Color(0xFFFF5E8A)
                                      : _borderColor,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _busyWishlist
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Color(0xFFFF5E8A),
                                          strokeWidth: 2),
                                    )
                                  : Icon(
                                      _isWishlisted
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _isWishlisted
                                          ? const Color(0xFFFF5E8A)
                                          : Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: (_busyCart || _isInCart)
                                  ? null
                                  : _addToCart,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                decoration: BoxDecoration(
                                  color: _isInCart
                                      ? _borderColor
                                      : _primaryPurple,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    if (_busyCart)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    else
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        color: _isInCart
                                            ? _primaryPurple
                                            : Colors.white,
                                        size: 18,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isInCart ? 'In Cart' : 'Add to Cart',
                                      style: TextStyle(
                                        color: _isInCart
                                            ? _primaryPurple
                                            : Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: ['overview', 'reviews'].map((tab) {
                    final active = _activeTab == tab;
                    final label = tab == 'overview'
                        ? 'Overview'
                        : 'Reviews (${asset.reviewCount})';
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _activeTab = tab);
                          if (tab == 'reviews') _loadReviews();
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    active ? _primaryPurple : _inputBg,
                                width: active ? 2 : 1,
                              ),
                            ),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active
                                  ? _primaryPurple
                                  : const Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_activeTab == 'overview') _OverviewTab(asset: asset),
                if (_activeTab == 'reviews')
                  _AssetReviewsTab(
                    loading: _reviewsLoading,
                    error: _reviewsError,
                    reviews: _reviews,
                    onRetry: () {
                      _reviewsLoaded = false;
                      _loadReviews();
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;

  const _AssetImage({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFF2D1B69),
        ),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFF2D1B69),
      ),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF1A1A2E),
          child: const Center(
            child: CircularProgressIndicator(
                color: Color(0xFFA088E4), strokeWidth: 2),
          ),
        );
      },
    );
  }
}

// ── Overview Tab ─────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final ProductDetail asset;
  const _OverviewTab({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            asset.description.isEmpty ? '—' : asset.description,
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Creator',
            value: (asset.sellerStoreName == null ||
                    asset.sellerStoreName!.isEmpty)
                ? 'Indiego Seller'
                : asset.sellerStoreName!,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.file_download_outlined,
            label: 'Downloads',
            value: '${asset.downloadCount}',
          ),
          const SizedBox(height: 12),
          if (asset.categories.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Categories',
              value: asset.categories.map((c) => c.name).join(', '),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.label_outline,
                  color: Color(0xFF9CA3AF), size: 16),
              const SizedBox(width: 10),
              const Text(
                'Tags',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: asset.tags.isEmpty
                    ? const Text('—',
                        style: TextStyle(
                            color: Color(0xFFD1D5DB), fontSize: 13))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: asset.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A4E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reviews Tab ──────────────────────────────────────────────────
class _AssetReviewsTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_ReviewVM> reviews;
  final VoidCallback onRetry;

  const _AssetReviewsTab({
    required this.loading,
    required this.error,
    required this.reviews,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFA088E4)),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(error!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('No reviews yet.',
              style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: reviews.map((r) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF2D1B69),
                      child: Text(
                        r.initial,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  r.userName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (r.verified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified,
                                    size: 12, color: Color(0xFFA088E4)),
                              ],
                            ],
                          ),
                          Text(
                            r.dateLabel,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < r.rating ? Icons.star : Icons.star_border,
                          color: i < r.rating
                              ? const Color(0xFFFBBC05)
                              : const Color(0xFF4B5563),
                          size: 12,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.comment,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF9CA3AF), size: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ReviewVM {
  final int id;
  final String userName;
  final int rating;
  final String comment;
  final bool verified;
  final DateTime? createdAt;

  _ReviewVM({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.verified,
    required this.createdAt,
  });

  String get initial =>
      userName.isNotEmpty ? userName[0].toUpperCase() : '?';

  String get dateLabel {
    if (createdAt == null) return '';
    final d = DateTime.now().difference(createdAt!);
    if (d.inDays >= 30) return '${(d.inDays / 30).floor()} mo ago';
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
    return 'just now';
  }

  factory _ReviewVM.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final raw = json['createdAt'] ?? json['CreatedAt'];
    if (raw is String) {
      try {
        created = DateTime.parse(raw);
      } catch (_) {}
    }
    return _ReviewVM(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      userName:
          (json['userName'] ?? json['UserName'] ?? 'anon').toString(),
      rating: (json['rating'] ?? json['Rating'] ?? 0) as int,
      comment: (json['comment'] ?? json['Comment'] ?? '').toString(),
      verified: (json['isVerifiedPurchase'] ??
              json['IsVerifiedPurchase'] ??
              false) as bool,
      createdAt: created,
    );
  }
}
