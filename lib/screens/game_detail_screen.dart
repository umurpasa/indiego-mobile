// Game detay ekranı.
// Veri kaynağı:
//   GET    /api/v1/Product/{id}                     -> ProductDetailDto
//   GET    /api/v1/cart                             -> zaten sepette mi kontrol
//   GET    /api/v1/wishlist                         -> zaten wishlist'te mi kontrol
//   POST   /api/v1/cart             body: {productId}
//   POST   /api/v1/wishlist         body: {productId}
//   DELETE /api/v1/wishlist/{productId}
//   GET    /api/v1/products/{id}/reviews            -> PagedResponse<ReviewDto>
//
// UI/UX eski hali ile birebir aynı tutuldu; tek değişiklik: originalPrice
// backend DTO'sunda yok, "-X% OFF" rozeti bu yüzden kalktı. Developer
// satırı backend'deki sellerStoreName ile beslenir, release date yok.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class GameDetailScreen extends StatefulWidget {
  final int gameId;

  const GameDetailScreen({super.key, required this.gameId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  static const _bgColor = Color(0xFF0A0A16);
  static const _primaryPurple = Color(0xFFA088E4);
  static const _inputBg = Color(0xFF1A1A2E);
  static const _borderColor = Color(0xFF2A2A4E);

  bool _loading = true;
  String? _error;
  ProductDetail? _product;

  // Cart/Wishlist durumları — ilk yüklemede /cart ve /wishlist çekilip ayarlanır,
  // sonra butonlar optimistic olarak güncellenir.
  bool _isWishlisted = false;
  bool _isInCart = false;
  bool _busyCart = false;
  bool _busyWishlist = false;

  bool _showDesktopNotice = false;
  String _activeTab = 'about'; // 'about' | 'reviews'

  // Reviews tab state — ilk kez "reviews" sekmesine tıklanınca yüklenir
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
      // Product detail — anonim erişilebilir, auth şart değil.
      final productRaw = await ApiService.get(
        '/api/v1/Product/${widget.gameId}',
        requireAuth: false,
      );
      final productJson = _unwrap(productRaw);
      if (productJson is! Map<String, dynamic>) {
        throw ApiException('Unexpected product response');
      }
      final product = ProductDetail.fromJson(productJson);

      // Cart / Wishlist durumu — token yoksa sessizce atla, butonlar "false" kalır.
      final token = await ApiService.getToken();
      bool inCart = false;
      bool inWishlist = false;
      if (token != null && token.isNotEmpty) {
        final results = await Future.wait<dynamic>([
          ApiService.get('/api/v1/cart').catchError((_) => null),
          ApiService.get('/api/v1/wishlist').catchError((_) => null),
        ]);
        inCart = _listHasProduct(results[0], product.id, 'items');
        inWishlist = _listHasProduct(results[1], product.id, 'items');
      }

      if (!mounted) return;
      setState(() {
        _product = product;
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
        _error = 'Error loading game: $e';
        _loading = false;
      });
    }
  }

  // PagedResponse<T> / ApiResponse<T> formatlarını normalize eder.
  static dynamic _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('data') &&
        raw['data'] is Map<String, dynamic>) {
      return raw['data'];
    }
    return raw;
  }

  // Cart/Wishlist response'larında productId kontrolü — hem { items: [...] }
  // hem düz liste hem { data: { items: [...] } } formatlarına dayanıklı.
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
      if (it is Map && (it['productId'] == productId || it['ProductId'] == productId)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _toggleWishlist() async {
    if (_busyWishlist || _product == null) return;
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
        await ApiService.delete('/api/v1/wishlist/${_product!.id}');
      } else {
        await ApiService.post('/api/v1/wishlist',
            body: {'productId': _product!.id});
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
    if (_busyCart || _isInCart || _product == null) return;
    setState(() => _busyCart = true);
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        _showSnack('Please log in to add items to your cart.');
        return;
      }
      await ApiService.post('/api/v1/cart',
          body: {'productId': _product!.id});
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
    if (_reviewsLoaded || _reviewsLoading || _product == null) return;
    setState(() {
      _reviewsLoading = true;
      _reviewsError = null;
    });
    try {
      final raw = await ApiService.get(
        '/api/v1/products/${_product!.id}/reviews',
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

  Future<void> _shareProduct() async {
    final product = _product;
    if (product == null) return;
    final text = product.directLink != null && product.directLink!.isNotEmpty
        ? product.directLink!
        : '${product.name} - INDIEGO';
    await Clipboard.setData(ClipboardData(text: text));
    _showSnack('Share link copied.');
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
    if (_error != null || _product == null) {
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
                  _error ?? 'Game not found.',
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

    final product = _product!;
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          CustomScrollView(
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
                  product.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: _shareProduct,
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _inputBg),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(url: product.coverImageUrl),
                    _ScreenshotsRow(urls: product.previewImages),
                    _PriceAndActions(
                      price: product.price,
                      currency: product.currency,
                      isFree: product.isFree,
                      rating: product.averageRating,
                      reviewCount: product.reviewCount,
                      isWishlisted: _isWishlisted,
                      isInCart: _isInCart,
                      busyCart: _busyCart,
                      busyWishlist: _busyWishlist,
                      onWishlist: _toggleWishlist,
                      onAddToCart: _addToCart,
                      onShowDesktopNotice: () =>
                          setState(() => _showDesktopNotice = true),
                    ),
                    _TabBarRow(
                      active: _activeTab,
                      reviewCount: product.reviewCount,
                      onChange: (t) {
                        setState(() => _activeTab = t);
                        if (t == 'reviews') _loadReviews();
                      },
                    ),
                    if (_activeTab == 'about') _AboutTab(product: product),
                    if (_activeTab == 'reviews')
                      _ReviewsTab(
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
          if (_showDesktopNotice)
            _DesktopNoticeSheet(
              onDismiss: () => setState(() => _showDesktopNotice = false),
            ),
        ],
      ),
    );
  }
}

// ── Hero image ──────────────────────────────────────────────────
class _HeroImage extends StatelessWidget {
  final String? url;
  const _HeroImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: (url == null || url!.isEmpty)
          ? Container(color: const Color(0xFF2D1B69))
          : _buildImage(url!),
    );
  }

  Widget _buildImage(String value) {
    if (value.startsWith('assets/')) {
      return Image.asset(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF2D1B69)),
      );
    }
    return Image.network(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2D1B69)),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
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

// ── Screenshots row ─────────────────────────────────────────────
class _ScreenshotsRow extends StatelessWidget {
  final List<String> urls;
  const _ScreenshotsRow({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _ScreenshotImage(url: urls[i]),
          ),
        ),
      ),
    );
  }
}

class _ScreenshotImage extends StatelessWidget {
  final String url;

  const _ScreenshotImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: 120,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 120,
          height: 80,
          color: const Color(0xFF2D1B69),
        ),
      );
    }
    return Image.network(
      url,
      width: 120,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 120,
        height: 80,
        color: const Color(0xFF2D1B69),
      ),
    );
  }
}

// ── Price + Actions block ───────────────────────────────────────
class _PriceAndActions extends StatelessWidget {
  final double price;
  final String currency;
  final bool isFree;
  final double rating;
  final int reviewCount;
  final bool isWishlisted;
  final bool isInCart;
  final bool busyCart;
  final bool busyWishlist;
  final VoidCallback onWishlist;
  final VoidCallback onAddToCart;
  final VoidCallback onShowDesktopNotice;

  const _PriceAndActions({
    required this.price,
    required this.currency,
    required this.isFree,
    required this.rating,
    required this.reviewCount,
    required this.isWishlisted,
    required this.isInCart,
    required this.busyCart,
    required this.busyWishlist,
    required this.onWishlist,
    required this.onAddToCart,
    required this.onShowDesktopNotice,
  });

  String get _priceLabel {
    if (isFree || price <= 0) return 'Free';
    final symbol = currency.toUpperCase() == 'USD' ? '\$' : '$currency ';
    return '$symbol${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFFA088E4);
    const inputBg = Color(0xFF1A1A2E);
    const borderColor = Color(0xFF2A2A4E);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: inputBg)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _priceLabel,
                style: const TextStyle(
                    color: primaryPurple,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.star,
                      color: Color(0xFFFBBC05), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating > 0 ? rating.toStringAsFixed(1) : '—',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Text('($reviewCount)',
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onShowDesktopNotice,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inputBg,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monitor_outlined,
                      color: Color(0xFF4A90E2), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Download on Desktop',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        SizedBox(height: 2),
                        Text(
                          'Purchase here, download from desktop or laptop',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF9CA3AF), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: busyWishlist ? null : onWishlist,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isWishlisted
                        ? const Color(0xFFFF5E8A).withOpacity(0.2)
                        : inputBg,
                    border: Border.all(
                      color: isWishlisted
                          ? const Color(0xFFFF5E8A)
                          : borderColor,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: busyWishlist
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Color(0xFFFF5E8A), strokeWidth: 2),
                        )
                      : Icon(
                          isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isWishlisted
                              ? const Color(0xFFFF5E8A)
                              : Colors.white,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: (busyCart || isInCart) ? null : onAddToCart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isInCart ? borderColor : primaryPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (busyCart)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.shopping_cart_outlined,
                            color:
                                isInCart ? primaryPurple : Colors.white,
                            size: 18,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          isInCart ? 'In Cart' : 'Add to Cart',
                          style: TextStyle(
                            color:
                                isInCart ? primaryPurple : Colors.white,
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
    );
  }
}

// ── Tabs ─────────────────────────────────────────────────────────
class _TabBarRow extends StatelessWidget {
  final String active;
  final int reviewCount;
  final ValueChanged<String> onChange;
  const _TabBarRow({
    required this.active,
    required this.reviewCount,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFFA088E4);
    const inputBg = Color(0xFF1A1A2E);
    final tabs = ['about', 'reviews'];
    return Row(
      children: tabs.map((tab) {
        final a = active == tab;
        final label = tab == 'about' ? 'About' : 'Reviews ($reviewCount)';
        return Expanded(
          child: GestureDetector(
            onTap: () => onChange(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: a ? primaryPurple : inputBg,
                    width: a ? 2 : 1,
                  ),
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: a ? primaryPurple : const Color(0xFF9CA3AF),
                  fontSize: 14,
                  fontWeight: a ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── About Tab ────────────────────────────────────────────────────
class _AboutTab extends StatelessWidget {
  final ProductDetail product;
  const _AboutTab({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            product.description.isEmpty ? '—' : product.description,
            style: const TextStyle(
                color: Color(0xFFD1D5DB), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.people_outline,
            label: 'Developer',
            value: (product.sellerStoreName == null ||
                    product.sellerStoreName!.isEmpty)
                ? 'Indiego Seller'
                : product.sellerStoreName!,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.file_download_outlined,
            label: 'Downloads',
            value: '${product.downloadCount}',
          ),
          const SizedBox(height: 12),
          if (product.categories.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Categories',
              value: product.categories.map((c) => c.name).join(', '),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.label_outline,
                  color: Color(0xFF9CA3AF), size: 16),
              const SizedBox(width: 10),
              const Text('Tags',
                  style:
                      TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: product.tags.isEmpty
                    ? const Text('—',
                        style: TextStyle(
                            color: Color(0xFFD1D5DB), fontSize: 13))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: product.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A4E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                    color: Color(0xFFD1D5DB),
                                    fontSize: 11)),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF9CA3AF), size: 16),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }
}

// ── Reviews Tab ──────────────────────────────────────────────────
class _ReviewsTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_ReviewVM> reviews;
  final VoidCallback onRetry;

  const _ReviewsTab({
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
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
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
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (r.verified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified,
                                    size: 12, color: Color(0xFFA088E4)),
                              ],
                            ],
                          ),
                          Text(r.dateLabel,
                              style: const TextStyle(
                                  color: Color(0xFF6B7280), fontSize: 11)),
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
                Text(r.comment,
                    style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Desktop notice bottom sheet ──────────────────────────────────
class _DesktopNoticeSheet extends StatelessWidget {
  final VoidCallback onDismiss;
  const _DesktopNoticeSheet({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onDismiss,
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4A90E2).withOpacity(0.2),
                      ),
                      child: const Icon(Icons.monitor_outlined,
                          color: Color(0xFF4A90E2), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Download on Desktop',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('Games can only be downloaded on desktop',
                            style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'After purchasing, you can download this game from your Library on a desktop or laptop. Visit indiego.com/library to access your purchased games.',
                  style: TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 13,
                      height: 1.5),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA088E4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Got it',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Review VM ────────────────────────────────────────────────────
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
      userName: (json['userName'] ?? json['UserName'] ?? 'anon').toString(),
      rating: (json['rating'] ?? json['Rating'] ?? 0) as int,
      comment: (json['comment'] ?? json['Comment'] ?? '').toString(),
      verified: (json['isVerifiedPurchase'] ??
              json['IsVerifiedPurchase'] ??
              false) as bool,
      createdAt: created,
    );
  }
}
