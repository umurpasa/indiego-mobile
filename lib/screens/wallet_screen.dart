import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const _baseUrl = 'https://localhost:9001';
  static const _desktopUrl = 'https://indiego.com/dashboard/settings#payment';

  // Wallet has no dedicated API endpoint — we show a summary from library data
  late Future<_WalletSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchSummary();
  }

  Future<_WalletSummary> _fetchSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) {
      return const _WalletSummary(purchaseCount: 0, totalSpent: 0);
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/library'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return const _WalletSummary(purchaseCount: 0, totalSpent: 0);
      }

      final data = jsonDecode(response.body);
      if (data is! List) {
        return const _WalletSummary(purchaseCount: 0, totalSpent: 0);
      }

      double total = 0;
      int count = 0;
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final p = item['pricePaid'];
          if (p is num) total += p.toDouble();
          count++;
        }
      }
      return _WalletSummary(purchaseCount: count, totalSpent: total);
    } catch (_) {
      return const _WalletSummary(purchaseCount: 0, totalSpent: 0);
    }
  }

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _desktopUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Desktop wallet link copied.'),
            duration: Duration(seconds: 2)),
      );
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
        title: const Text('Wallet', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<_WalletSummary>(
        future: _future,
        builder: (context, snapshot) {
          final summary = snapshot.data ??
              const _WalletSummary(purchaseCount: 0, totalSpent: 0);
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Balance Card (no real balance endpoint — desktop managed)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A3E), Color(0xFF2A1A4E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFA088E4).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFA088E4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Color(0xFFA088E4),
                              size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Indiego Balance',
                                style: TextStyle(
                                    color: Color(0xFFB0B0C3),
                                    fontSize: 12)),
                            SizedBox(height: 2),
                            Text('Managed on Desktop',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF2A2A5E)),
                    const SizedBox(height: 16),
                    const Text(
                      'Add funds, manage payment methods and view transaction history on the web dashboard.',
                      style: TextStyle(
                          color: Color(0xFFB0B0C3), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Spending Summary from Library
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A4E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bar_chart_outlined,
                            color: Color(0xFFA088E4), size: 18),
                        SizedBox(width: 8),
                        Text('Spending Summary',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(color: Color(0xFF2A2A4E), height: 20),
                    if (isLoading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            color: Color(0xFFA088E4), strokeWidth: 2),
                      ))
                    else ...[
                      _StatRow(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Total Purchases',
                        value: '${summary.purchaseCount} items',
                      ),
                      const SizedBox(height: 10),
                      _StatRow(
                        icon: Icons.attach_money,
                        label: 'Total Spent',
                        value:
                            '\$${summary.totalSpent.toStringAsFixed(2)}',
                        valueColor: const Color(0xFF4CAF50),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // What's available on desktop
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A4E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.desktop_windows_outlined,
                            color: Color(0xFFA088E4), size: 18),
                        SizedBox(width: 8),
                        Text('Available on Desktop',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(color: Color(0xFF2A2A4E), height: 20),
                    ...[
                      'Add funds to wallet',
                      'Manage payment methods',
                      'View transaction history',
                      'Set billing address',
                      'Payout settings (sellers)',
                    ].map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Color(0xFF4CAF50), size: 16),
                            const SizedBox(width: 8),
                            Text(item,
                                style: const TextStyle(
                                    color: Color(0xFFB0B0C3),
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA088E4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _copyUrl(context),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Copy Desktop Wallet Link'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WalletSummary {
  final int purchaseCount;
  final double totalSpent;

  const _WalletSummary(
      {required this.purchaseCount, required this.totalSpent});
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFA088E4), size: 16),
        const SizedBox(width: 8),
        Text(label,
            style:
                const TextStyle(color: Color(0xFFB0B0C3), fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}
