import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BecomeSellerInfoScreen extends StatelessWidget {
  const BecomeSellerInfoScreen({super.key});

  static const _dashboardUrl = 'https://indiego.com/dashboard/become-seller';

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _dashboardUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied. Open it on desktop browser.'),
          duration: Duration(seconds: 2),
        ),
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
        title: const Text(
          'Become Seller',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A4E)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller application is managed on web',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'On mobile, creator features are view-only. '
                    'To apply as a seller and upload products, use the desktop dashboard.',
                    style: TextStyle(color: Color(0xFFB0B0C3), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Desktop URL',
              style: TextStyle(
                color: Color(0xFFA088E4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A4E)),
              ),
              child: const Text(
                _dashboardUrl,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA088E4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => _copyUrl(context),
                child: const Text('Copy Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
