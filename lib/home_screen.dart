import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'store_screen.dart';
import 'screens/game_screen.dart';
import 'screens/game_assets_screen.dart';
import 'screens/game_detail_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/become_seller_info_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/library_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/asset_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'models/product.dart';
import 'services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0=Home, 1=Store, 2=Library, 3=Wishlist
  bool _isSeller = false;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    // Load display info for drawer regardless of role flag source.
    final firstName = prefs.getString('user_first_name') ?? '';
    final lastName = prefs.getString('user_last_name') ?? '';
    final username = prefs.getString('user_username') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final displayName = ('$firstName $lastName').trim();
    if (mounted) {
      setState(() {
        _userName = displayName.isNotEmpty ? displayName : username;
        _userEmail = email;
      });
    }

    final savedRoleFlag = prefs.getBool('is_seller');
    if (savedRoleFlag != null) {
      if (mounted) {
        setState(() => _isSeller = savedRoleFlag);
      }
      return;
    }

    // Backward-compatible fallback: try reading roles from JWT payload.
    final token = prefs.getString('jwt_token');
    final decodedSeller = _isSellerFromToken(token);
    if (mounted) {
      setState(() => _isSeller = decodedSeller);
    }
  }

  bool _isSellerFromToken(String? token) {
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length < 2) return false;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;

      final roleValue = map['roles'] ?? map['role'];
      if (roleValue is String) {
        return roleValue.toLowerCase() == 'seller';
      }
      if (roleValue is List) {
        return roleValue.any((r) => r.toString().toLowerCase() == 'seller');
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  // Sayfa listesi — ileride her biri kendi dosyasına taşınır
  List<Widget> get _pages => [
        _HomePage(
          showBecomeSellerAction: !_isSeller,
          showDashboardAction: _isSeller,
          onOpenDashboard: () => _selectPage(6),
          onOpenBecomeSeller: () => _selectPage(7),
        ),
        StoreScreen(
          onOpenGames: () => _selectPage(4),
          onOpenGameAssets: () => _selectPage(5),
        ),
        const LibraryScreen(), // 2
        const WishlistScreen(), // 3
        const GamesScreen(), // 4
        const GameAssetsScreen(), // 5
        DashboardScreen(
          onBack: () => _selectPage(0),
        ), // 6
        const BecomeSellerInfoScreen(), // 7
        const ProfileScreen(), // 8
        const SettingsScreen(), // 9
        const CartScreen(), // 10
        const WalletScreen(), // 11
      ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('is_seller');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  void _navigate(int index) {
    _selectPage(index);
    Navigator.pop(context); // drawer'ı kapat
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0A0A16);
    const primaryPurple = Color(0xFFA088E4);
    const drawerBg = Color(0xFF0D0D1A);
    const borderColor = Color(0xFF2A2A4E);

    final drawerItems = [
      _DrawerItem(icon: Icons.home_outlined, label: 'Home', index: 0),
      _DrawerItem(
          icon: Icons.storefront_outlined,
          label: 'Store',
          index: 1,
          children: [
            _DrawerSubItem(
                icon: Icons.videogame_asset_outlined, label: 'Games', index: 4),
            _DrawerSubItem(
                icon: Icons.widgets_outlined, label: 'Game Assets', index: 5),
          ]),
      _DrawerItem(
          icon: Icons.library_books_outlined, label: 'Library', index: 2),
      _DrawerItem(icon: Icons.favorite_border, label: 'Wishlist', index: 3),
      _DrawerItem(icon: Icons.shopping_cart_outlined, label: 'Cart', index: 10),
      _DrawerItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Wallet',
          index: 11),
      if (!_isSeller)
        _DrawerItem(
            icon: Icons.store_outlined,
            label: 'Become Seller',
            index: 7,
            badge: 'Web'),
      if (_isSeller)
        _DrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            index: 6,
            badge: 'View only'),
      _DrawerItem(icon: Icons.person_outline, label: 'Profile', index: 8),
      _DrawerItem(icon: Icons.settings_outlined, label: 'Settings', index: 9),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      // ── TOP APP BAR ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _selectPage(0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/icon-128.png',
                width: 26,
                height: 26,
                errorBuilder: (_, __, ___) => const Icon(Icons.blur_circular,
                    color: primaryPurple, size: 26),
              ),
              const SizedBox(width: 8),
              const Text(
                'INDIEGO',
                style: TextStyle(
                  color: primaryPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: primaryPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),

      // ── DRAWER ───────────────────────────────────────────────
      drawer: Drawer(
        backgroundColor: drawerBg,
        child: SafeArea(
          child: Column(
            children: [
              // Kullanıcı avatarı
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryPurple.withOpacity(0.3),
                        border: Border.all(color: primaryPurple, width: 1.5),
                      ),
                      child: const Icon(Icons.person,
                          color: primaryPurple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName.isNotEmpty ? _userName : 'INDIEGO User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userEmail.isNotEmpty
                                ? _userEmail
                                : 'Signed in account',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      alignment: Alignment.centerRight,
                      icon: const Icon(Icons.close,
                          color: Colors.grey, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E1E3A), height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final item in drawerItems)
                      if (item.children == null)
                        _DrawerTile(
                          icon: item.icon,
                          label: item.label,
                          badge: item.badge,
                          selected: _selectedIndex == item.index,
                          onTap: item.index >= 0
                              ? () => _navigate(item.index)
                              : () => Navigator.pop(context),
                        )
                      else
                        _DrawerExpandable(
                          icon: item.icon,
                          label: item.label,
                          children: item.children!,
                          selected: _selectedIndex == item.index,
                          onTap: () => _navigate(item.index),
                          onSubTap: _navigate,
                          currentIndex: _selectedIndex,
                        ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E1E3A), height: 1),
              // Çıkış yap
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.grey, size: 20),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),

      // ── BODY ─────────────────────────────────────────────────
      body: _pages[_selectedIndex],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HOME PAGE CONTENT
// ─────────────────────────────────────────────────────────────
class _HomePage extends StatelessWidget {
  final bool showBecomeSellerAction;
  final bool showDashboardAction;
  final VoidCallback onOpenDashboard;
  final VoidCallback onOpenBecomeSeller;

  const _HomePage(
      {required this.showBecomeSellerAction,
      required this.showDashboardAction,
      required this.onOpenDashboard,
      required this.onOpenBecomeSeller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner (GIF)
          _HeroBanner(),

          // Event / Sale Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _EventBanner(),
          ),

          // Featured Games
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFFA088E4),
            title: 'Featured Games',
            onSeeAll: () => context.findAncestorStateOfType<_HomeScreenState>()?._selectPage(4),
          ),
          const SizedBox(height: 12),
          _FeaturedGamesRow(),

          // New Releases
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFF4A90E2),
            title: 'New Game Releases',
            onSeeAll: () => context.findAncestorStateOfType<_HomeScreenState>()?._selectPage(4),
          ),
          const SizedBox(height: 12),
          _NewReleasesList(),

          // Popular Assets
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.trending_up,
            iconColor: const Color(0xFFFF5E8A),
            title: 'Popular Assets',
            onSeeAll: () => context.findAncestorStateOfType<_HomeScreenState>()?._selectPage(5),
          ),
          const SizedBox(height: 12),
          _PopularAssetsRow(),

          // Quick Actions
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
          ),
          const SizedBox(height: 12),
          _QuickActions(
            showBecomeSellerAction: showBecomeSellerAction,
            showDashboardAction: showDashboardAction,
            onOpenDashboard: onOpenDashboard,
            onOpenBecomeSeller: onOpenBecomeSeller,
            onNavigate: (i) => context.findAncestorStateOfType<_HomeScreenState>()?._selectPage(i),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Hero Banner ──────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // GIF veya fallback gradient
          Image.asset(
            'assets/images/b.gif',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF2D1B69)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Gradient overlay (alttan karartma)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFF0A0A16)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.4, 1.0],
              ),
            ),
          ),
          // Yazılar
          const Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Indiego',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Discover indie games & assets',
                  style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event Banner ─────────────────────────────────────────────
class _EventBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4E)),
        // İmge varsa: DecorationImage ile — yoksa gradient
        gradient: const LinearGradient(
          colors: [Color(0xFF3B3564), Color(0xFF1A1A2E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/event-banner.png'),
          fit: BoxFit.cover,
          onError: _ignoreImageError,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0x993B3564), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'April 2026',
                  style: TextStyle(color: Color(0xFFA088E4), fontSize: 11),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Spring Sale – Up to 50% Off',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child:
                  Icon(Icons.chevron_right, color: Color(0xFFA088E4), size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: const [
                Text('See all',
                    style: TextStyle(color: Color(0xFF9370DB), fontSize: 13)),
                Icon(Icons.chevron_right, color: Color(0xFF9370DB), size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured Games (yatay scroll) ────────────────────────────
// Veri: GET /api/v1/Product?Type=0&PageSize=6  (Type=0 = Game)
class _FeaturedGamesRow extends StatefulWidget {
  const _FeaturedGamesRow();

  @override
  State<_FeaturedGamesRow> createState() => _FeaturedGamesRowState();
}

class _FeaturedGamesRowState extends State<_FeaturedGamesRow> {
  bool _loading = true;
  String? _error;
  List<Product> _games = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await ApiService.get(
        '/api/v1/Product',
        query: {'Type': '0', 'PageNumber': '1', 'PageSize': '6'},
        requireAuth: false,
      );
      final items = _extractProductList(raw);
      if (!mounted) return;
      setState(() {
        _games = items;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 165,
        child: Center(
          child: CircularProgressIndicator(
              color: Color(0xFFA088E4), strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 165,
        child: Center(
          child: Text('Unable to load games',
              style: const TextStyle(color: Color(0xFF9CA3AF))),
        ),
      );
    }
    if (_games.isEmpty) {
      return const SizedBox(
        height: 165,
        child: Center(
          child:
              Text('No games yet.', style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
      );
    }
    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _games.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final g = _games[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailScreen(gameId: g.id),
              ),
            ),
            child: SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _RemoteImage(
                      url: g.coverImageUrl,
                      width: 130,
                      height: 98,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(g.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(_formatPrice(g.price, g.currency),
                      style: const TextStyle(
                          color: Color(0xFFA088E4), fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── New Releases (dikey liste) ────────────────────────────────
// Veri: GET /api/v1/Product?Type=0&PageNumber=2&PageSize=3
// Featured ile çakışmamak için ikinci sayfayı çekiyoruz.
class _NewReleasesList extends StatefulWidget {
  const _NewReleasesList();

  @override
  State<_NewReleasesList> createState() => _NewReleasesListState();
}

class _NewReleasesListState extends State<_NewReleasesList> {
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
        query: {'Type': '0', 'PageNumber': '2', 'PageSize': '3'},
        requireAuth: false,
      );
      var items = _extractProductList(raw);
      // Eğer 2. sayfa boş geldiyse 1. sayfayı tail-slice ederek göster
      if (items.isEmpty) {
        final raw2 = await ApiService.get(
          '/api/v1/Product',
          query: {'Type': '0', 'PageNumber': '1', 'PageSize': '6'},
          requireAuth: false,
        );
        final all = _extractProductList(raw2);
        items = all.length > 3 ? all.sublist(3) : all;
      }
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
              color: Color(0xFFA088E4), strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Unable to load releases',
            style: const TextStyle(color: Color(0xFF9CA3AF))),
      );
    }
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('No new releases.',
            style: TextStyle(color: Color(0xFF9CA3AF))),
      );
    }
    return Column(
      children: _items.map((item) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameDetailScreen(gameId: item.id),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _RemoteImage(
                    url: item.coverImageUrl,
                    width: 60,
                    height: 60,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(_formatPrice(item.price, item.currency),
                    style: const TextStyle(
                        color: Color(0xFFA088E4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Popular Assets (yatay scroll) ────────────────────────────
// Veri: GET /api/v1/Product?Type=1&PageSize=6
class _PopularAssetsRow extends StatefulWidget {
  const _PopularAssetsRow();

  @override
  State<_PopularAssetsRow> createState() => _PopularAssetsRowState();
}

class _PopularAssetsRowState extends State<_PopularAssetsRow> {
  bool _loading = true;
  String? _error;
  List<Product> _assets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await ApiService.get(
        '/api/v1/Product',
        query: {'Type': '1', 'PageNumber': '1', 'PageSize': '6'},
        requireAuth: false,
      );
      final items = _extractProductList(raw);
      if (!mounted) return;
      setState(() {
        _assets = items;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 148,
        child: Center(
          child: CircularProgressIndicator(
              color: Color(0xFFA088E4), strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 148,
        child: Center(
          child: Text('Unable to load assets',
              style: const TextStyle(color: Color(0xFF9CA3AF))),
        ),
      );
    }
    if (_assets.isEmpty) {
      return const SizedBox(
        height: 148,
        child: Center(
          child: Text('No assets yet.',
              style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
      );
    }
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _assets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final a = _assets[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssetDetailScreen(assetId: a.id),
              ),
            ),
            child: SizedBox(
              width: 118,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _RemoteImage(
                      url: a.coverImageUrl,
                      width: 118,
                      height: 88,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(_formatPrice(a.price, a.currency),
                      style: const TextStyle(
                          color: Color(0xFFA088E4), fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Product listesini PagedResponse / ApiResponse sarmalayıcısından çıkarır.
List<Product> _extractProductList(dynamic raw) {
  dynamic cursor = raw;
  if (cursor is Map && cursor['data'] != null) cursor = cursor['data'];
  // PagedResponse<T>: { data: [...], pageNumber, ... }
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

// Network image helper — cover URL için cache'siz Image.network.
class _RemoteImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;

  const _RemoteImage(
      {required this.url, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
          width: width, height: height, color: const Color(0xFF2D1B69));
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
      loadingBuilder: (ctx, child, progress) {
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

// ── Quick Actions ─────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final bool showBecomeSellerAction;
  final bool showDashboardAction;
  final VoidCallback onOpenDashboard;
  final VoidCallback onOpenBecomeSeller;
  final ValueChanged<int> onNavigate;

  const _QuickActions(
      {required this.showBecomeSellerAction,
      required this.showDashboardAction,
      required this.onOpenDashboard,
      required this.onOpenBecomeSeller,
      required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QAction(
          icon: Icons.star_border,
          color: const Color(0xFFFF5E8A),
          label: 'Wishlist',
          onTap: () => onNavigate(3)),
      _QAction(
          icon: Icons.library_books_outlined,
          color: const Color(0xFF4A90E2),
          label: 'My Library',
          onTap: () => onNavigate(2)),
      if (showBecomeSellerAction)
        _QAction(
            icon: Icons.store_outlined,
            color: const Color(0xFF4A90E2),
            label: 'Become Seller',
            onTap: onOpenBecomeSeller),
      if (showDashboardAction)
        _QAction(
            icon: Icons.access_time_outlined,
            color: const Color(0xFF9370DB),
            label: 'Dashboard',
            onTap: onOpenDashboard),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2,
        children: actions.map((a) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: a.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: a.color.withOpacity(0.2),
                      ),
                      child: Icon(a.icon, color: a.color, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(a.label,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DRAWER HELPERS
// ─────────────────────────────────────────────────────────────
class _DrawerItem {
  final IconData icon;
  final String label;
  final int index;
  final String? badge;
  final List<_DrawerSubItem>? children;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.index,
    this.badge,
    this.children,
  });
}

class _DrawerSubItem {
  final IconData icon;
  final String label;
  final int index;
  const _DrawerSubItem(
      {required this.icon, required this.label, required this.index});
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: selected ? const Color(0xFFA088E4) : Colors.grey, size: 20),
      title: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFFA088E4) : Colors.white,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A4E),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badge!,
                  style:
                      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
            ),
          ],
        ],
      ),
      selected: selected,
      selectedTileColor: const Color(0xFFA088E4).withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }
}

class _DrawerExpandable extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<_DrawerSubItem> children;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<int> onSubTap;
  final int currentIndex;

  const _DrawerExpandable({
    required this.icon,
    required this.label,
    required this.children,
    required this.selected,
    required this.onTap,
    required this.onSubTap,
    required this.currentIndex,
  });

  @override
  State<_DrawerExpandable> createState() => _DrawerExpandableState();
}

class _DrawerExpandableState extends State<_DrawerExpandable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(widget.icon,
              color: widget.selected ? const Color(0xFFA088E4) : Colors.grey,
              size: 20),
          title: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? const Color(0xFFA088E4) : Colors.white,
              fontSize: 14,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey,
              size: 18,
            ),
            splashRadius: 16,
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          onTap: widget.onTap,
        ),
        if (_expanded)
          for (final sub in widget.children)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: ListTile(
                leading: Icon(sub.icon,
                    color: widget.currentIndex == sub.index
                        ? const Color(0xFFA088E4)
                        : Colors.grey,
                    size: 16),
                title: Text(sub.label,
                    style: TextStyle(
                        color: widget.currentIndex == sub.index
                            ? const Color(0xFFA088E4)
                            : const Color(0xFF9CA3AF),
                        fontSize: 13)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                onTap: () => widget.onSubTap(sub.index),
              ),
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────

// Resim yoksa mor placeholder göster
class _GameImage extends StatelessWidget {
  final String path;
  final double width;
  final double height;

  const _GameImage(
      {required this.path, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
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
}

// Placeholder sayfalar (Library, Wishlist)
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFA088E4), size: 48),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 8),
          const Text('Coming soon',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

// Data models
class _GameItem {
  final int id;
  final String title;
  final String price;
  final String rating;
  final String imagePath;

  const _GameItem(
      {required this.id,
      required this.title,
      required this.price,
      required this.rating,
      required this.imagePath});
}

class _AssetItem {
  final String title;
  final String price;
  final String downloads;
  final String imagePath;

  const _AssetItem(
      {required this.title,
      required this.price,
      required this.downloads,
      required this.imagePath});
}

class _QAction {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _QAction(
      {required this.icon,
      required this.color,
      required this.label,
      this.onTap});
}

void _ignoreImageError(Object error, StackTrace? stackTrace) {}
