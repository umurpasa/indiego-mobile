import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _desktopUrl = 'https://indiego.com/dashboard/settings';
  static const _baseUrl = 'https://localhost:9001';

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _desktopUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Desktop settings link copied.'),
            duration: Duration(seconds: 2)),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchLibrarySummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }

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
    if (data is! List) {
      return {'count': 0, 'total': 0.0};
    }

    double total = 0;
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final rawPrice = item['pricePaid'];
        if (rawPrice is num) total += rawPrice.toDouble();
      }
    }

    return {'count': data.length, 'total': total};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A16),
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchLibrarySummary(),
        builder: (context, snapshot) {
          final purchaseCount =
              snapshot.hasData ? (snapshot.data!['count'] as int? ?? 0) : null;
          final totalSpent = snapshot.hasData
              ? (snapshot.data!['total'] as double? ?? 0)
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _tile(
                Icons.security_outlined,
                'Account',
                'Email and password settings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccountSettingsScreen()),
                ),
              ),
              _tile(Icons.notifications_outlined, 'Notifications',
                  'Email and push preferences'),
              _tile(
                Icons.history_outlined,
                'Purchase History',
                purchaseCount == null
                    ? 'Loading from backend...'
                    : '$purchaseCount purchases, total spent \$${totalSpent!.toStringAsFixed(2)}',
              ),
              _tile(Icons.payment_outlined, 'Payment',
                  'Managed on desktop web dashboard'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.35)),
                ),
                child: const Text(
                  'Mobile settings are intentionally simplified. '
                  'For full account/profile/payment settings, continue on desktop.',
                  style: TextStyle(color: Color(0xFFC7D7F6), fontSize: 12),
                ),
              ),
              if (snapshot.hasError) ...[
                const SizedBox(height: 10),
                Text(
                  'Backend data could not be loaded: ${snapshot.error}',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA088E4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => _copyUrl(context),
                child: const Text('Copy Desktop Settings Link'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFA088E4), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFFB0B0C3), fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: Color(0xFFB0B0C3), size: 18),
          ],
        ),
      ),
    );
  }
}
