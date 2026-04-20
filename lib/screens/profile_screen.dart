import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _desktopUrl = 'https://indiego.com/dashboard/settings';
  static const _baseUrl = 'https://localhost:9001';

  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  void _refresh() {
    setState(() {
      _profileFuture = _fetchProfile();
    });
  }

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _desktopUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Settings link copied.'),
            duration: Duration(seconds: 2)),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/User/me'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Profile request failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) throw Exception('Unexpected profile response');
    return data;
  }

  Future<void> _updateProfile(Map<String, String> fields) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/User/me'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(fields),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      String msg = 'Update failed';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) msg = body['message'];
      } catch (_) {
        if (response.body.isNotEmpty) msg = response.body;
      }
      throw Exception('$msg (${response.statusCode})');
    }
  }

  void _showEditBottomSheet(BuildContext context, Map<String, dynamic> profile) {
    final firstNameCtrl =
        TextEditingController(text: profile['firstName']?.toString() ?? '');
    final lastNameCtrl =
        TextEditingController(text: profile['lastName']?.toString() ?? '');
    final userNameCtrl =
        TextEditingController(text: profile['userName']?.toString() ?? '');
    final bioCtrl =
        TextEditingController(text: profile['bio']?.toString() ?? '');
    final regionCtrl =
        TextEditingController(text: profile['region']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit Profile',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Color(0xFFB0B0C3)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                        'First Name', firstNameCtrl, Icons.person_outline),
                    _buildFormField(
                        'Last Name', lastNameCtrl, Icons.person_outline),
                    _buildFormField(
                        'Username', userNameCtrl, Icons.alternate_email),
                    _buildFormField('Bio', bioCtrl, Icons.info_outline,
                        maxLines: 3),
                    _buildFormField(
                        'Region', regionCtrl, Icons.public_outlined),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA088E4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                try {
                                  await _updateProfile({
                                    'firstName': firstNameCtrl.text.trim(),
                                    'lastName': lastNameCtrl.text.trim(),
                                    'userName': userNameCtrl.text.trim(),
                                    'bio': bioCtrl.text.trim(),
                                    'region': regionCtrl.text.trim(),
                                  });
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    _refresh();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Profile updated successfully!'),
                                          backgroundColor: Color(0xFF4CAF50)),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    setModalState(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Save Changes',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormField(
      String label, TextEditingController ctrl, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFB0B0C3)),
          prefixIcon: Icon(icon, color: const Color(0xFFA088E4), size: 18),
          filled: true,
          fillColor: const Color(0xFF0A0A16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A2A4E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A2A4E)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFA088E4)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A16),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFA088E4)));
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          final profile = snapshot.data ?? const <String, dynamic>{};
          final firstName = (profile['firstName'] ?? '').toString().trim();
          final lastName = (profile['lastName'] ?? '').toString().trim();
          final userName = (profile['userName'] ?? '').toString().trim();
          final email = (profile['email'] ?? '').toString().trim();
          final bio = (profile['bio'] ?? '').toString().trim();
          final region = (profile['region'] ?? '').toString().trim();
          final displayName = ('$firstName $lastName').trim().isNotEmpty
              ? ('$firstName $lastName').trim()
              : userName;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card with edit button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A4E)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFA088E4),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isEmpty ? 'Your profile' : displayName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          if (userName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('@$userName',
                                style: const TextStyle(
                                    color: Color(0xFFB0B0C3), fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Color(0xFFA088E4)),
                      tooltip: 'Edit Profile',
                      onPressed: () =>
                          _showEditBottomSheet(context, profile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _row(Icons.alternate_email, 'Username',
                  userName.isEmpty ? '-' : userName),
              _row(Icons.mail_outline, 'Email', email.isEmpty ? '-' : email),
              _row(Icons.public_outlined, 'Region',
                  region.isEmpty ? '-' : region),
              _row(Icons.info_outline, 'Bio', bio.isEmpty ? '-' : bio),
              const SizedBox(height: 16),
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

  Widget _errorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 40),
          const SizedBox(height: 10),
          const Text('Could not load profile.',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(error,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Color(0xFFB0B0C3), fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String title, String subtitle) {
    return Container(
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
        ],
      ),
    );
  }
}
